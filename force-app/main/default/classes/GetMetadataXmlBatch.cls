public class GetMetadataXmlBatch
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    public class MetadataXmlBatchException extends Exception {}

    private static final String FILE_TYPE = 'xml';

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

        // currently, there should only ever be a single chunk (ie, a single profile fullName)
        // TODO: figure out how to handle readMetadata() requests with multiple fullNames (but not > 10!)
        if (encodedFullNames.size() != 1) {
            system.debug('trying to process ' + encodedFullNames.size() + 'profiles.');
            return;
        }
        String encodedFullName = encodedFullNames[0];

        ReadMetadataApi readMetadataApi = new ReadMetadataApi(this.sessionId, this.metadataType, encodedFullNames);
        try {
            String xml = readMetadataApi.executeRequest();
            String fileName = MetadataXmlBatchHelper.getFileName(encodedFullName);
            S3Service.uploadToS3(this.metadataType, FILE_TYPE, fileName, xml);
            lastSavedDatetimes.put(encodedFullName, Datetime.now());
        } catch (MetadataService.MetadataServiceException e) {
            if (e.getMessage() == 'Read timed out') this.timedOutFiles.add(encodedFullName);
            // log the error
        } catch (S3Service.S3ServiceException e) {
            // log the error
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

    class Parameters {
        String sessionId;
        String metadataType;
    }
}
