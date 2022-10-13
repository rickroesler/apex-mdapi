public with sharing class GetProfileMetadataBatch
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    private List<String> unprocessedProfiles = new List<String>();
    private Map<String, Datetime> lastSavedDatetimes = new Map<String, Datetime>();

    public List<String> start(Database.BatchableContext ctx) {
        ProfileMetadata.updateProfileMetadataRecords();
        return ProfileMetadata.getProfilesToUpdate();
    }

    public void execute(Database.BatchableContext ctx, List<String> encodedFullNames){
        system.debug(encodedFullNames);
        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (encodedFullNames.size() != 1) {
            system.debug('trying to process ' + encodedFullNames.size() + 'profiles.');
            return;
        }
        
        ReadMetadataApi readMetadataApi = new ReadMetadataApi('Profile', encodedFullNames);
        system.debug(Limits.getHeapSize());
        String xml = readMetadataApi.executeRequest();
        system.debug(Limits.getHeapSize());
    }

    public void finish(Database.BatchableContext ctx){
        ProfileMetadata.persistLastSavedDatetimes(this.lastSavedDatetimes);
        
        if (!this.unprocessedProfiles.isEmpty()) {
            ProfileMetadata.markTooBig(this.unprocessedProfiles);
        }

        // call webhook
    }
}
