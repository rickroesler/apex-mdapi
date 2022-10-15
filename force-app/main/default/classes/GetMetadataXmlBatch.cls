public class GetMetadataXmlBatch
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    private List<String> unprocessedProfiles = new List<String>();
    private Map<String, Datetime> lastSavedDatetimes = new Map<String, Datetime>();

    private String sessionId;
    private String metadataType;
    private MetadataXmlBatchHelper helper;

    public GetMetadataXmlBatch(String sessionId, String metadataType) {
        this.sessionId = sessionId;
        this.metadataType = metadataType;
        this.helper = new MetadataXmlBatchHelper(sessionId, metadataType);
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
        
        ReadMetadataApi readMetadataApi = new ReadMetadataApi(this.sessionId, this.metadataType, encodedFullNames);
        system.debug(Limits.getHeapSize());
        String xml = readMetadataApi.executeRequest();
        system.debug(Limits.getHeapSize());

        String fileName = helper.getFileName(encodedFullNames[0]);
        String url = S3Repository.getS3PresignedUrl(this.metadataType, fileName);
        S3Repository.putXmlToS3(url, xml);
    }

    public void finish(Database.BatchableContext ctx){
        if (!this.lastSavedDatetimes.keySet().isEmpty()) {
            this.helper.persistLastSavedDatetimes(this.lastSavedDatetimes);
        }

        if (!this.unprocessedProfiles.isEmpty()) {
            this.helper.markTooBig(this.unprocessedProfiles);
        }
    }
}
