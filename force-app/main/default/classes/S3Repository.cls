public class S3Repository {
    
    public class S3RepositoryException extends Exception {}

    private static final String S3_SIGNED_URL_ENDPOINT = 'api/v1/salesforce/s3SignedUrl';
    private static final String S3_DELETE_FILES_ENDPOINT = 'api/v1/salesforce/s3Files';

    public static String getS3SignedUrl(String fileType, String metadataType, String fileName) {
        // temporary for standalone; will be replace by call to Elements makeRequest()
        String endpoint = 'https://a5f2-172-114-128-36.ngrok.io/' + S3_SIGNED_URL_ENDPOINT + '/' + fileType;
        String publicKey = 'L82vG0W03qPXwNRXrl46';
        String authorization = UserInfo.getOrganizationId() + '.' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOF(publicKey + '.' + UserInfo.getOrganizationId() + '.1ZAiTn3FVvgOpwWBbGl1FFSuwkl8lt9pxuE8Fj5uAqDpusZRXa')));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', authorization);
        req.setMethod('POST');
        req.setBody(JSON.serialize(new FileIdentifier(metadataType, fileName)));

        HttpResponse res = new Http().send(req);
        
        String url = (String) JSON.deserialize(res.getBody(), String.class);
        return url;
    }

    // TODO: throw an exception if there is an error writing to S3
    public static void putXmlToS3(String url, String xml) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod('PUT');
        req.setBody(xml);

        HttpResponse res = new Http().send(req);
    }

    @future(callout=true)
    public static void deleteXmlFilesFromS3(String fileType, String metadataType, List<String> fileNamesToDelete) {
        List<FileIdentifier> fileIds = new List<FileIdentifier>();
        for (String fileName: fileNamesToDelete) {
            fileIds.add(new FileIdentifier(metadataType, fileName));
        }

        // temporary for standalone 
        String endpoint = 'https://a5f2-172-114-128-36.ngrok.io/' + S3_DELETE_FILES_ENDPOINT + '/' + fileType;
        String publicKey = 'L82vG0W03qPXwNRXrl46';
        String authorization = UserInfo.getOrganizationId() + '.' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOF(publicKey + '.' + UserInfo.getOrganizationId() + '.1ZAiTn3FVvgOpwWBbGl1FFSuwkl8lt9pxuE8Fj5uAqDpusZRXa')));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', authorization);
        req.setMethod('DELETE');
        req.setTimeout(30000);
        req.setBody(JSON.serialize(fileIds));

        HttpResponse res = new Http().send(req);
    }

    class FileIdentifier {
        String metadataType;
        String fileName;

        FileIdentifier(String metadataType, String fileName) {
            this.metadataType = metadataType;
            this.fileName = fileName;
        }
    }
}
