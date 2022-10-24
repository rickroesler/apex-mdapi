public class MetadataXmlBatchHelper {
    private static final Double API_VERSION = 55.0;
    private static final Integer SOAP_TIMEOUT = 120000;
    private static final String FILE_TYPE = 'xml';

    private String sessionId;
    private String metadataType;

    public MetadataXmlBatchHelper(String sessionId, String metadataType) {
        if (!Metadata_Type__mdt.getAll().keySet().contains(metadataType)) {
            throw new GetMetadataXmlBatch.MetadataXmlBatchException('UNSUPPORTED METADATA TYPE: ' + metadataType);
        }

        this.metadataType = metadataType;
        this.sessionId = sessionId;

        Map<Id, MetadataItemWrapper> currentItems = getCurrentItems();
        Map<Id, MetadataItemWrapper> savedItems = getSavedItems();
        processDeletedItems(currentItems, savedItems);
        processNewItems(currentItems, savedItems);
        processExistingItems(currentItems, savedItems);
    }

    public static String getFileName(String encodedFullName) {
        return EncodingUtil.urlDecode(encodedFullName, 'UTF-8') + '.xml';
    }

    /**
     * returns List<String> list of encoded Profile names whose Last_Saved_Datetime < Last_Modified_Datetime
     */
    public List<String> getItemsToUpdate() {
        List<String> itemsToUpdate = new List<String>();
        for (Metadata_Item__c item: [SELECT Encoded_FullName__c,
                                            Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                       FROM Metadata_Item__c
                                      WHERE Metadata_Type__c = :this.metadataType]) {
            if (item.Last_Saved_Datetime__c == null || item.Last_Saved_Datetime__c < item.Last_Modified_Datetime__c) {
                itemsToUpdate.add(item.Encoded_FullName__c);
            }
        }
        return itemsToUpdate;
    }

    public static void persistLastSavedDatetimes(String metadataType, Map<String, Datetime> lastSavedDatetimes) {
        List<Metadata_Item__c> items = [SELECT Id, Encoded_FullName__c, Last_Saved_Datetime__c
                                          FROM Metadata_Item__c
                                         WHERE Encoded_FullName__c IN :lastSavedDatetimes.keySet()
                                           AND Metadata_Type__c = :metadataType];
        for (Metadata_Item__c item: items) {
            item.Last_Saved_Datetime__c = lastSavedDatetimes.get(item.Encoded_FullName__c);
        }
        update items;
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
        S3Repository.deleteXmlFilesFromS3(FILE_TYPE, this.metadataType, fileNamesToDelete);
    }

    

    private void processNewItems(Map<Id, MetadataItemWrapper> currentItems, Map<Id, MetadataItemWrapper> savedItems) {
        // TODO: handle case where a new item is created with the same fullName as a previously-deleted item
        // make a list of fullnames of the new items
        // select saved items that are deleted with those fullnames
        // if there's a match handle those ids/fullnames separately
        Set<Id> newIds = currentItems.keySet().clone();
        newIds.removeAll(savedItems.keySet());  // the set of current items that are not yet saved

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

        List<Metadata_Item__c> existingItems = [SELECT Id, Salesforce_Id__c, Last_Modified_Datetime__c, Is_Deleted__c 
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
                        item.lastModifiedDatetime = (Datetime) JSON.deserialize(element.getText(), Datetime.class);
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
                                               Last_Saved_Datetime__c, Last_Modified_Datetime__c
                                          FROM Metadata_Item__c
                                         WHERE Metadata_Type__c = :this.metadataType];
        
        for (Metadata_Item__c item: items) {
            MetadataItemWrapper mi = new MetadataItemWrapper();
                mi.salesforceId = item.Salesforce_Id__c;
                mi.encodedFullName = item.Encoded_FullName__c;
                mi.lastSavedDatetime = item.Last_Saved_Datetime__c;
                mi.lastModifiedDatetime = item.Last_Modified_Datetime__c;
                mi.isDeleted = item.Is_Deleted__c;
            savedItems.put(mi.salesforceId, mi);
        }
        return savedItems;
    }

    class MetadataItemWrapper {
        String encodedFullName;
        Id salesforceId;
        Boolean isDeleted;
        Datetime lastSavedDatetime;
        Datetime lastModifiedDatetime;
    }
}
