public class GetMetadataXmlBatch
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    public class MetadataXmlBatchException extends Exception {}

    private List<String> unprocessedFiles = new List<String>();
    private List<String> timedOutFiles = new List<String>();
    private Map<String, Datetime> lastSavedDatetimes = new Map<String, Datetime>();
    private String sessionId;
    private String metadataType;
    private MetadataXmlBatchHelper helper;

    public GetMetadataXmlBatch(List<String> sessionIdParts, String metadataType) {
        this.sessionId = sessionIdParts[0] + '!' + sessionIdParts[1];
        this.metadataType = metadataType;
        this.helper = new MetadataXmlBatchHelper(this.sessionId, this.metadataType);
    }

    public List<String> start(Database.BatchableContext ctx) {
        return this.helper.getItemsToUpdate();
    }

    public void execute(Database.BatchableContext ctx, List<String> encodedFullNames){
        system.debug(encodedFullNames);

        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (encodedFullNames.size() != 1) {
            system.debug('trying to process ' + encodedFullNames.size() + 'profiles.');
            return;
        }
        String encodedFullName = encodedFullNames[0];

        ReadMetadataApi readMetadataApi = new ReadMetadataApi(this.sessionId, this.metadataType, encodedFullNames);
        try {
            String xml = readMetadataApi.executeRequest();
            String fileName = MetadataXmlBatchHelper.getFileName(encodedFullName);
            String url = S3Repository.getS3SignedUrl(this.metadataType, fileName);
            S3Repository.putXmlToS3(url, xml);
            lastSavedDatetimes.put(encodedFullName, Datetime.now());
        } catch (SoapApi.SoapApiException e) {
            // if read timed out, then add to timedOutFiles list and alert that it's too big

            // if invalid_grant (expired refresh token), then add to unprocessedFiles list
            // i don't think this should ever happen
            this.unprocessedFiles.add(encodedFullName);
        } catch (S3Repository.S3RepositoryException e) {
            this.unprocessedFiles.add(encodedFullName);
        }
    }

    public void finish(Database.BatchableContext ctx){
        if (!this.lastSavedDatetimes.keySet().isEmpty()) {
            MetadataXmlBatchHelper.persistLastSavedDatetimes(this.metadataType, this.lastSavedDatetimes);
        }

        if (!this.timedOutFiles.isEmpty()) {
            MetadataXmlBatchHelper.markTooBig(this.metadataType, this.timedOutFiles);
        }

        // TODO: add unprocessedFiles handling
    }

    class Parameters {
        String sessionId;
        String metadataType;
    }
}
