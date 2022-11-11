@isTest
public class MetadataXmlBatchHelperTest {
    @TestSetup
    static void makeData(){
        Metadata_Item__c item = new Metadata_Item__c();
            item.Metadata_Type__c = 'Profile';
            item.Encoded_FullName__c = 'test';
            item.Salesforce_Id__c = '000000000000000AAA';
            item.Is_Deleted__c = false;
            item.Is_Too_Large_To_Process__c = false;        
        insert item;
    }

    @isTest
    private static void testConstructor() {
        String sessionId = 'test';
        String metadataType = 'Profile';
        MetadataXmlBatchHelper helper = new MetadataXmlBatchHelper(sessionId, metadataType);
    }

    @isTest
    private static void testUpdateSavedMetadataItems() {
        MetadataXmlBatchHelper.MetadataItemWrapper item = new MetadataXmlBatchHelper.MetadataItemWrapper();
        item.encodedFullName = 'test';
        item.lastSavedDatetime = Datetime.now();
        item.hash = 12345;
        MetadataXmlBatchHelper.updateSavedMetadataItems('Profile', new Map<String, MetadataXmlBatchHelper.MetadataItemWrapper>{ 'test' => item });
    }
}
