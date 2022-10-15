public class S3Repository {
    


    public static String getS3PresignedUrl(String metadataType, String fileName) {
        // temporary for standalone 
        String endpoint = 'https://5d4b-172-114-128-36.ngrok.io/api/v1/s3/presignedUrl';
        String publicKey = 'L82vG0W03qPXwNRXrl46';
        String authorization = UserInfo.getOrganizationId() + '.' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOF(publicKey + '.' + UserInfo.getOrganizationId() + '.1ZAiTn3FVvgOpwWBbGl1FFSuwkl8lt9pxuE8Fj5uAqDpusZRXa')));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', authorization);
        req.setMethod('POST');
        req.setBody(JSON.serialize(new FileIdentifier(metadataType, fileName)));

        HttpResponse res = new Http().send(req);
        
        UrlResponse urlResponse = (UrlResponse) JSON.deserialize(res.getBody(), UrlResponse.class);
        system.debug(urlResponse.fileName);
        system.debug(urlResponse.url);
        return urlResponse.url;
    }

    // should probably return a boolean or other status
    public static void putXmlToS3(String url, String xml) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod('PUT');
        req.setBody(xml);

        HttpResponse res = new Http().send(req);
        system.debug(res.getStatus());
    }

    @future(callout=true)
    public static void deleteXmlFilesFromS3(String metadataType, List<String> fileNamesToDelete) {
        List<FileIdentifier> fileIds = new List<FileIdentifier>();
        for (String fileName: fileNamesToDelete) {
            fileIds.add(new FileIdentifier(metadataType, fileName));
        }

        // temporary for standalone 
        String endpoint = 'https://5d4b-172-114-128-36.ngrok.io/api/v1/s3/deleteXmlFiles';
        String publicKey = 'L82vG0W03qPXwNRXrl46';
        String authorization = UserInfo.getOrganizationId() + '.' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOF(publicKey + '.' + UserInfo.getOrganizationId() + '.1ZAiTn3FVvgOpwWBbGl1FFSuwkl8lt9pxuE8Fj5uAqDpusZRXa')));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', authorization);
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setBody(JSON.serialize(fileIds));

        HttpResponse res = new Http().send(req);
        system.debug(res.getStatus());
        system.debug(res.getBody());
    }

    class FileIdentifier {
        String metadataType;
        String fileName;

        FileIdentifier(String metadataType, String fileName) {
            this.metadataType = metadataType;
            this.fileName = fileName;
        }
    }

    class UrlResponse {
        String fileName;
        String url;
    }
}
