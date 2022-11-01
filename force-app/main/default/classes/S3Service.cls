public class S3Service {
    
    public class S3ServiceException extends Exception {}

    private static final String S3_SIGNED_URL_ENDPOINT = '/api/v1/salesforce/s3SignedUrl';
    private static final String S3_DELETE_FILES_ENDPOINT = '/api/v1/salesforce/s3Files';
    private static final Integer S3_API_TIMEOUT = 30000;

    public static void uploadToS3(String metadataType, String fileType, String fileName, String fileBody) {
        try {
            String url = getS3SignedUrl(fileType, metadataType, fileName);
            putXmlToS3(url, fileBody);
        } catch (S3ServiceException e) {
            throw new S3ServiceException(e.getMessage());
        }
    }

    @TestVisible private static String getS3SignedUrl(String fileType, String metadataType, String fileName) {
        try {
            ElementsApi.Result result = ElementsApi.makeRequest(
                'Get S3 Signed Url',
                'POST',
                ElementsUtils.getApiEndpoint(S3_SIGNED_URL_ENDPOINT + '/' + fileType),
                null,
                JSON.serialize(new FileIdentifier(metadataType, fileName))
            );

            if (!result.isSuccess()) throw new S3ServiceException('S3Service: URL_ERROR: ' + result.getErrorMessage());

            String url = (String) JSON.deserialize(result.returnJson, String.class);
            return url;
        } catch (Exception e) {
            throw new S3ServiceException('S3Service: URL_ERROR: ' + e.getMessage());
        }
    }

    private static void putXmlToS3(String url, String xml) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod('PUT');
        req.setBody(xml);
        req.setTimeout(S3_API_TIMEOUT);

        try {
            if (!Test.isRunningTest()) {
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() != 200) throw new S3ServiceException('S3Service: PUT_TO_S3_ERROR: ' + res.getBody());
            }
        } catch (Exception e) {
            throw new S3ServiceException('S3Service: PUT_TO_S3_ERROR: ' + e.getMessage());
        }
    }

    @future(callout=true)
    public static void deleteFilesFromS3(String fileType, String metadataType, List<String> fileNamesToDelete) {
        List<FileIdentifier> fileIds = new List<FileIdentifier>();
        for (String fileName: fileNamesToDelete) {
            fileIds.add(new FileIdentifier(metadataType, fileName));
        }

        try {
            ElementsApi.Result result = ElementsApi.makeRequest(
                'Delete S3 Files',
                'DELETE',
                ElementsUtils.getApiEndpoint(S3_DELETE_FILES_ENDPOINT + '/' + fileType),
                null,
                JSON.serialize(fileIds)
            );

            if (!result.isSuccess()) throw new S3ServiceException('S3Service: FILE_DELETE_ERROR: ' + result.getErrorMessage());

            DeleteResult deleteResult = (DeleteResult) JSON.deserialize(result.returnJson, DeleteResult.class);
            if (deleteResult.Errors != null && !deleteResult.Errors.isEmpty()) {
                List<String> keys;
                for (DeleteError e: deleteResult.Errors) {
                    keys.add(e.Key);
                }
                // log errors    
                throw new S3ServiceException('S3Service: FILE_DELETE_ERROR: Failed to delete files: ' + String.join(keys, ','));
            }
        } catch (Exception e) {
            throw new S3ServiceException('S3Service: FILE_DELETE_ERROR: ' + e.getMessage());
        }
    }

    class FileIdentifier {
        String metadataType;
        String fileName;

        FileIdentifier(String metadataType, String fileName) {
            this.metadataType = metadataType;
            this.fileName = fileName;
        }
    }

    class DeleteResult {
        List<Deleted> Deleted;
        List<DeleteError> Errors;

    }

    class Deleted {
        String Key;
        String VersionId;
        Boolean DeleteMarker;
        String DeleteMarkerVersionId;
    }

    class DeleteError {
        String Key;
        String VersionId;
        String Code;
        String Message;
    }
}
