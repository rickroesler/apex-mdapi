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
        
        MetadataService.MetadataPort service = MetadataService.createService();
        try {
            MetadataService.ReadProfileResult result = (MetadataService.ReadProfileResult) service.readMetadata('Profile', encodedFullNames);
            List<MetadataService.Profile> rawProfiles = (List<MetadataService.Profile>) result.getRecords();

            system.debug('heap 1: ' + Limits.getHeapSize());
            if (Limits.getHeapSize() > Limits.getLimitHeapSize()) {
                this.unprocessedProfiles.add(encodedFullNames[0]);
                return;
            }

            while (rawProfiles.size() > 0) {
                MetadataService.Profile rawProfile = rawProfiles.remove(0);  // manage heap
                String fullName = rawProfile.fullName; // this is the encoded fullName
                Profile profile = new Profile(rawProfile);
                system.debug('heap 2: ' + Limits.getHeapSize());
                rawProfile = null; // manage heap
                system.debug('heap 3: ' + Limits.getHeapSize());
                Boolean success = ProfileMetadata.persistProfile(profile);
                if (success) {
                    lastSavedDatetimes.put(fullName, Datetime.now());
                }
            }    
        } catch (CalloutException e) {
            system.debug('WebService Callout Exception: ' + e.getMessage());
            this.unprocessedProfiles.add(encodedFullNames[0]);
        } catch (Exception e) {
            system.debug('Other Exception: ' + e.getMessage());
            this.unprocessedProfiles.add(encodedFullNames[0]);
        }
    }

    public void finish(Database.BatchableContext ctx){
        ProfileMetadata.persistLastSavedDatetimes(this.lastSavedDatetimes);
        
        if (!this.unprocessedProfiles.isEmpty()) {
            ProfileMetadata.markTooBig(this.unprocessedProfiles);
        }

        // call webhook
    }
}
