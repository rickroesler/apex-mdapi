public class S3Service {
    
    public class S3ServiceException extends Exception {}

    private static final String S3_SIGNED_URL_ENDPOINT = 'api/v1/salesforce/s3SignedUrl';
    private static final String S3_DELETE_FILES_ENDPOINT = 'api/v1/salesforce/s3Files';
    private static final Integer S3_API_TIMEOUT = 30000;

    public static void uploadToS3(String metadataType, String fileType, String fileName, String fileBody) {
        try {
            String url = getS3SignedUrl(fileType, metadataType, fileName);
            putXmlToS3(url, fileBody);
        } catch (S3ServiceException e) {

        }
    }

    private static String getS3SignedUrl(String fileType, String metadataType, String fileName) {
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

        String url;
        try {
            HttpResponse res = new Http().send(req);
            String url = (String) JSON.deserialize(res.getBody(), String.class);
        } catch (Exception e) {
            throw new S3ServiceException('S3Service: URL_ERROR: ' + e.getMessage());
        }
        return url;
    }

    private static void putXmlToS3(String url, String xml) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod('PUT');
        req.setBody(xml);
        req.setTimeout(S3_API_TIMEOUT);

        HttpResponse res;
        try {
            res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                throw new S3ServiceException('S3Service: PUT_TO_S3_ERROR: ' + res.getBody());
            }
        } catch (Exception e) {
            throw new S3ServiceException('S3Service: PUT_TO_S3_ERROR: ' + e.getMessage());
        }
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
        req.setTimeout(S3_API_TIMEOUT);
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
