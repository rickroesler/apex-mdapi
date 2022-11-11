public class MetadataXmlBatchHelper {
    private static final Double API_VERSION = 55.0;
    private static final Integer SOAP_TIMEOUT = 120000;
    private static final String FILE_TYPE = 'xml';

    // private static Map<String, Metadata_Type__mdt> metadataTypes = Metadata_Type__mdt.getAll();
    private String sessionId;
    private String metadataType;
    private Boolean ignoreLastModifiedDate;
    private Map<String, Integer> hashMap;
    private List<String> itemsToUpdate;

    public MetadataXmlBatchHelper(String sessionId, String metadataType) {
        
        // if (!metadataTypes.keySet().contains(metadataType)) {
        if (!Metadata_Type__mdt.getAll().keySet().contains(metadataType)) {
            throw new GetMetadataXmlBatch.MetadataXmlBatchException('UNSUPPORTED METADATA TYPE: ' + metadataType);
        }

        this.sessionId = sessionId;
        this.metadataType = metadataType;
        // this.ignoreLastModifiedDate = metadataTypes.get(metadataType).Ignore_LastModifiedDate__c;
        this.ignoreLastModifiedDate = Metadata_Type__mdt.getInstance(metadataType).Ignore_LastModifiedDate__c;
        this.hashMap  = new Map<String, Integer>();
        this.itemsToUpdate = new List<String>();

        Map<Id, MetadataItemWrapper> currentItems = getCurrentItems();
        Map<Id, MetadataItemWrapper> savedItems = getSavedItems();
        processDeletedItems(currentItems, savedItems);
        processNewItems(currentItems, savedItems);
        processExistingItems(currentItems, savedItems);
        processItemsToUpdate();
    }

    public static String getFileName(String encodedFullName) {
        return encodedFullName + '.xml';
    }

    public Boolean getIgnoreLastModifiedDate() {
        return this.ignoreLastModifiedDate;
    }

    public Map<String, Integer> getHashMap() {
        return this.hashMap;
    }

    public List<String> getItemsToUpdate() {
        return this.itemsToUpdate;
    }

    private void processItemsToUpdate() {
        for (Metadata_Item__c item: [SELECT Encoded_FullName__c,
                                            Last_Saved_Datetime__c, Last_Modified_Datetime__c, Hash__c
                                       FROM Metadata_Item__c
                                      WHERE Metadata_Type__c = :this.metadataType
                                        AND Is_Deleted__c = false]) {
            if (this.ignoreLastModifiedDate || item.Last_Saved_Datetime__c == null || item.Last_Saved_Datetime__c < item.Last_Modified_Datetime__c) {
                this.itemsToUpdate.add(item.Encoded_FullName__c);
                this.hashMap.put(item.Encoded_FullName__c, Integer.valueOf(item.Hash__c));
            }
        }
    }

    public static void updateSavedMetadataItems(String metadataType, Map<String, MetadataItemWrapper> items) {
        List<Metadata_Item__c> metadataItems = [SELECT Id, Encoded_FullName__c, Last_Saved_Datetime__c, Hash__c
                                                  FROM Metadata_Item__c
                                                 WHERE Encoded_FullName__c IN :items.keySet()
                                                   AND Metadata_Type__c = :metadataType];
        for (Metadata_Item__c metadataItem: metadataItems) {
            MetadataItemWrapper item = items.get(metadataItem.Encoded_FullName__c);
            metadataItem.Last_Saved_Datetime__c = item.lastSavedDatetime;
            metadataItem.Hash__c = item.hash;
        }
        update metadataItems;
    }

    public static void markTooBig(String metadataType, List<String> encodedFullNames) {
        List<Metadata_Item__c> items = [SELECT Id, Is_Too_Large_To_Process__c
                                          FROM Metadata_Item__c
                                         WHERE Encoded_FullName__c IN :encodedFullNames
                                           AND Metadata_Type__c = :metadataType];

        if (items.size() != encodedFullNames.size()) {
            system.debug('requested: ' + encodedFullNames + '; received: ' + items);
            return;
        }

        for (Metadata_Item__c item: items) {
            item.Is_Too_Large_To_Process__c = true;
        }

        update items;
    }

    private void processDeletedItems(Map<Id, MetadataItemWrapper> currentItems, Map<Id, MetadataItemWrapper> savedItems) {
        Set<Id> deletedIds = savedItems.keySet().clone();
        deletedIds.removeAll(currentItems.keySet());  // set of items that are saved but not current

        if (deletedIds.isEmpty()) return;

        List<String> fileNamesToDelete = new List<String>();

        List<Metadata_Item__c> items = [SELECT Id, Encoded_FullName__c, Is_Deleted__c 
                                          FROM Metadata_Item__c
                                         WHERE Salesforce_Id__c IN :deletedIds];
        for (Metadata_Item__c item: items) {
            item.Is_Deleted__c = true;
            fileNamesToDelete.add(getFileName(item.Encoded_FullName__c));
        }
        update items;
        S3Service.deleteFilesFromS3(FILE_TYPE, this.metadataType, fileNamesToDelete);
    }

    private void processNewItems(Map<Id, MetadataItemWrapper> currentItems, Map<Id, MetadataItemWrapper> savedItems) {
        Set<Id> newIds = currentItems.keySet().clone();
        newIds.removeAll(savedItems.keySet());  // the set of current items that are not yet saved

        List<String> newEncodedFullNames = new List<String>();
        for (Id newId: newIds) {
            newEncodedFullNames.add(currentItems.get(newId).encodedFullName);
        }

        // remove "is deleted" records if we've created a new Profile with the same name as one previously-deleted
        List<Metadata_Item__c> duplicates = [SELECT Id
                                               FROM Metadata_Item__c
                                              WHERE Encoded_FullName__c IN :newEncodedFullNames
                                                AND Is_Deleted__c = true
                                                AND Metadata_Type__c = :this.metadataType];
        delete duplicates;

        List<Metadata_Item__c> newItems = new List<Metadata_Item__c>();
        for (Id newId: newIds) {
            MetadataItemWrapper currentItem = currentItems.get(newId);
            Metadata_Item__c item = new Metadata_Item__c();
                item.Metadata_Type__c = this.metadataType;
                item.Salesforce_Id__c = newId;
                item.Last_Modified_Datetime__c = currentItem.lastModifiedDatetime;
                item.Encoded_FullName__c = currentItem.encodedFullName;
                item.Is_Deleted__c = false;
                item.Last_Saved_Datetime__c = null;
            newItems.add(item);
        }
        insert newItems;
    }

    private void processExistingItems(Map<Id, MetadataItemWrapper> currentItems, Map<Id, MetadataItemWrapper> savedItems) {
        Set<Id> existingIds = currentItems.keySet().clone();
        existingIds.retainAll(savedItems.keySet()); // the set of current items that have already been saved

        List<Metadata_Item__c> existingItems = [SELECT Id, Salesforce_Id__c, Is_Deleted__c, Last_Modified_Datetime__c  
                                                  FROM Metadata_Item__c
                                                 WHERE Salesforce_Id__c IN :existingIds];
        for (Metadata_Item__c item: existingItems) {
            MetadataItemWrapper currentItem = currentItems.get(item.Salesforce_Id__c);
            item.Encoded_FullName__c = currentItem.encodedFullName;
            item.Last_Modified_Datetime__c = currentItems.get(item.Salesforce_Id__c).lastModifiedDatetime;
            item.Is_Deleted__c = false;
        }
        update existingItems;
    }

    /**
     * returns Map<Id, MetadataItem> 
     *                  where Id == Salesforce Profile Id
     *                        MetadataItem == record corresponding to an existing Profile
     */
    public Map<Id, MetadataItemWrapper> getCurrentItems() {
        Map<Id, MetadataItemWrapper> currentItems = new Map<Id, MetadataItemWrapper>();

        if (Test.isRunningTest()) return currentItems;

        ListMetadataApi listMetadataApi = new ListMetadataApi(this.sessionId, this.metadataType);

        Dom.Document doc = new Dom.Document();
        doc.load(listMetadataApi.executeRequest());
        Dom.XmlNode envelope = doc.getRootElement();
        Dom.XmlNode body = envelope.getChildElements()[0];
        Dom.XmlNode listMetadataResponse = body.getChildElements()[0];
        List<Dom.XmlNode> results = listMetadataResponse.getChildElements();
        for (Dom.XmlNode result: results) {
            Boolean hasId = false;
            Boolean hasName = false;
            Boolean hasDate = false;
            MetadataItemWrapper item = new MetadataItemWrapper();
            for (Dom.XmlNode element: result.getChildElements()) {
                switch on element.getName() {
                    when 'id' {
                        item.salesforceId = (Id) element.getText();
                        hasId = true;
                    }
                    when 'fullName' {
                        item.encodedFullName = element.getText();
                        hasName = true;
                    }
                    when 'lastModifiedDate' {
                        item.lastModifiedDatetime = Datetime.valueOfGmt(element.getText().replace('T', ' ').replace('.000Z', ''));
                        hasDate = true;
                    }
                }   
            }
            if (hasId && hasName && hasDate) {
                currentItems.put(item.salesforceId, item);
            }
        }

        return currentItems;
    }

    /**
     * returns Map<Id, MetadataItem> 
     *                      where Id == Salesforce Profile Id
     *                            MetadataItem == a saved Metadata_Item__c record
     */
    private Map<Id, MetadataItemWrapper> getSavedItems() {
        Map<Id, MetadataItemWrapper> savedItems = new Map<Id, MetadataItemWrapper>();

        List<Metadata_Item__c> items = [SELECT Id, Encoded_FullName__c, Salesforce_Id__c, Is_Deleted__c,  
                                               Last_Saved_Datetime__c, Last_Modified_Datetime__c, Hash__c
                                          FROM Metadata_Item__c
                                         WHERE Metadata_Type__c = :this.metadataType];
        
        for (Metadata_Item__c item: items) {
            MetadataItemWrapper mi = new MetadataItemWrapper();
                mi.salesforceId = item.Salesforce_Id__c;
                mi.encodedFullName = item.Encoded_FullName__c;
                mi.lastSavedDatetime = item.Last_Saved_Datetime__c;
                mi.lastModifiedDatetime = item.Last_Modified_Datetime__c;
                mi.isDeleted = item.Is_Deleted__c;
                mi.hash = Integer.valueOf(item.Hash__c);
            savedItems.put(mi.salesforceId, mi);
        }
        return savedItems;
    }

    public class MetadataItemWrapper {
        public String encodedFullName;
        public Id salesforceId;
        public Boolean isDeleted;
        public Datetime lastSavedDatetime;
        public Datetime lastModifiedDatetime;
        public Integer hash;
    }
}
