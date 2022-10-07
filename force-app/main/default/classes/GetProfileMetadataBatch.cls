public with sharing class GetProfileMetadataBatch
    implements Database.Batchable<List<String>>, Database.AllowsCallouts, Database.Stateful {

    private List<List<String>> timedOutChunks;
    private Map<String, Datetime> lastSavedDatetimes = new Map<String, Datetime>();

    public GetProfileMetadataBatch() {
        this.timedOutChunks = new List<List<String>>();
    }

    public GetProfileMetadataBatch(List<List<String>> timedOutChunks) {
        this.timedOutChunks = timedOutChunks;
    }

    public List<List<String>> start(Database.BatchableContext ctx) {
        List<List<String>> dynamicChunks = new List<List<String>>();

        Boolean isRetry; // for testing
        if (timedOutChunks.isEmpty()) {
            ProfileMetadata.updateProfileMetadataRecords();
            dynamicChunks = ProfileMetadata.getDynamicChunks();
            isRetry = false; // for testing
        } else {
            dynamicChunks.addAll(this.timedOutChunks);
            this.timedOutChunks.clear();
            isRetry = true; // for testing
        }

        if (!isRetry) return new List<List<String>>{ dynamicChunks[0], dynamicChunks[1], dynamicChunks[2] }; // for testing
        return dynamicChunks;
        
    }

    public void execute(Database.BatchableContext ctx, List<List<String>> chunks){
        system.debug(chunks);
        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (chunks.size() != 1) {
            system.debug('chunk size error: ' + chunks.size());
            return;
        }
        List<String> encodedFullNames = chunks[0];

        MetadataService.MetadataPort service = MetadataService.createService();
        try {
            MetadataService.ReadProfileResult result = (MetadataService.ReadProfileResult) service.readMetadata('Profile', encodedFullNames);
            List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) result.getRecords();
            for (MetadataService.Profile rawProfile: profiles) {
                Boolean success = ProfileMetadata.persistProfile(rawProfile);
                if (success) {
                    lastSavedDatetimes.put(rawProfile.fullName, Datetime.now());  // this is the encoded fullName
                }
            }    
        } catch (CalloutException e) {
            system.debug('WebService Callout Exception: ' + e.getMessage());
            this.timedOutChunks.add(encodedFullNames);
        } catch (Exception e) {
            system.debug('Other Exception: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext ctx){
        ProfileMetadata.persistLastSavedDatetimes(this.lastSavedDatetimes);
        
        if (this.timedOutChunks.isEmpty()) {
            // post platform event
            system.debug('finished processing');
        } else {
            List<List<String>> smallerChunks = splitChunks(this.timedOutChunks);
            Database.executeBatch(new GetProfileMetadataBatch(smallerChunks), 1);
        }
    }

    private List<List<String>> splitChunks(List<List<String>> chunks) {
        List<List<String>> splitChunks = new List<List<String>>();
        List<String> largeProfiles = new List<String>();

        for (List<String> chunk: chunks) {
            Integer chunkSize = chunk.size();
            if (chunkSize == 1) {
                largeProfiles.add(chunk[0]);
                continue;
            }

            List<String> newChunk = new List<String>();
            while (newChunk.size() < chunkSize / 2) {
                newChunk.add(chunk.remove(0));
            }

            splitChunks.add(newChunk);
            splitChunks.add(chunk);
        }

        if (!largeProfiles.isEmpty()) ProfileMetadata.markTooBig(largeProfiles);

        return splitChunks;
    }
}
