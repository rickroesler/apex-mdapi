@isTest
public class S3ServiceTest {
    @isTest
    public static void uploadToS3Test() {
        Boolean success = true;
        try {
            S3Service.uploadToS3('xml', 'Profile', 'test.xml', 'body');    
        } catch (Exception e) {
            success = false;
        }
        System.assertEquals(true, success, 'Expected success == true');
    }

    @isTest
    public static void getS3SignedUrlTest() {
        String url = S3Service.getS3SignedUrl('xml', 'Profile', 'test.xml');
        System.assertEquals('https://test.com', url, 'Expected "https://test.com"');
    }

    @isTest
    public static void deleteFilesFromS3Test() {
        Boolean success = true;
        try {
            Test.startTest();
            S3Service.deleteFilesFromS3('xml', 'Profile', new List<String>{'test.xml'});
            Test.stopTest();
        } catch (Exception e) {
            success = false;
        }
        System.assertEquals(true, success, 'Expected success == true');
    }
}
