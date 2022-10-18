public class GetMetadataXmlBatch
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    private List<String> unprocessedFiles = new List<String>();
    private List<String> timedOutFiles = new List<String>();
    private Map<String, Datetime> lastSavedDatetimes = new Map<String, Datetime>();
    private String sessionId; // probably get rid of this
    private String metadataType;
    private MetadataXmlBatchHelper helper;

    // we're probably NOT going to pass the sessionId to the batch
    public GetMetadataXmlBatch(String sessionId, String metadataType) {
        this.isRetry = false;
        this.sessionId = sessionId;
        this.metadataType = metadataType;
        this.helper = new MetadataXmlBatchHelper(sessionId, metadataType); // probably need to move this start()
    }

    public List<String> start(Database.BatchableContext ctx) {
        if (this.isRetry) return retryFiles;

        return this.helper.getItemsToUpdate();
    }

    public void execute(Database.BatchableContext ctx, List<String> encodedFullNames){
        system.debug(encodedFullNames);
        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (encodedFullNames.size() != 1) {
            system.debug('trying to process ' + encodedFullNames.size() + 'profiles.');
            return;
        }
        
        ReadMetadataApi readMetadataApi = new ReadMetadataApi(this.sessionId, this.metadataType, encodedFullNames);
        system.debug(Limits.getHeapSize());
        try {
            String xml = readMetadataApi.executeRequest();
        } catch (CalloutException e) {
            // if read timed out, then add to timedOutFiles list and alert that it's too big

            // if invalid_grant (expired refresh token), then add to unprocessedFiles list
            // i don't think this should ever happen
        } catch (Exception e) {
            this.unprocessedFiles.add(encodedFullNames[0]);
        }
        system.debug(Limits.getHeapSize());

        String fileName = MetadataXmlBatchHelper.getFileName(encodedFullNames[0]);
        String url = S3Repository.getS3PresignedUrl(this.metadataType, fileName);
        try {
            S3Repository.putXmlToS3(url, xml);
        } catch (Exception e) { // TODO:create a new S3RepositoryException
            this.unprocessedFiles.add(encodedFullNames[0]);
        }
    }

    public void finish(Database.BatchableContext ctx){
        if (!this.lastSavedDatetimes.keySet().isEmpty()) {
            MetadataXmlBatchHelper.persistLastSavedDatetimes(this.metadataType, this.lastSavedDatetimes);
        }

        if (!this.timedOutFiles.isEmpty()) {
            MetadataXmlBatchHelper.markTooBig(this.metadataType, this.timedOutFiles);
        }
    }
}
