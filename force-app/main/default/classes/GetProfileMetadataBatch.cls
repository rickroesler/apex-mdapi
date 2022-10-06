public with sharing class GetProfileMetadataBatch
    implements Database.Batchable<List<String>>, Database.AllowsCallouts, Database.Stateful {

    private List<List<String>> timedOutChunks;

    public GetProfileMetadataBatch() {
        this.timedOutChunks = new List<List<String>>();
    }

    public GetProfileMetadataBatch(List<List<String>> timedOutChunks) {
        this.timedOutChunks = timedOutChunks;
    }

    public List<List<String>> start(Database.BatchableContext ctx) {
        List<List<String>> dynamicChunks = new List<List<String>>();

        if (timedOutChunks.isEmpty()) {
            ProfileMetadata.updateProfileMetadataRecords();
            dynamicChunks = ProfileMetadata.getDynamicChunks();
        } else {
            dynamicChunks.addAll(this.timedOutChunks);
            this.timedOutChunks.clear();
        }

        return dynamicChunks;
        // return new List<List<String>>{ dynamicChunks[0], dynamicChunks[1], dynamicChunks[2] };
    }

    public void execute(Database.BatchableContext ctx, List<List<String>> chunks){
        system.debug(chunks);
        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (chunks.size() != 1) {
            system.debug('chunk size error: ' + chunks.size());
            return;
        }
        List<String> fullNames = chunks[0];

        MetadataService.MetadataPort service = MetadataService.createService();
        try {
            MetadataService.ReadProfileResult result = (MetadataService.ReadProfileResult) service.readMetadata('Profile', fullNames);
            List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) result.getRecords();
            for (MetadataService.Profile rawProfile: profiles) {
                
                ProfileMetadata.persistProfile(profile);
            }    
        } catch (CalloutException e) {
            system.debug('WebService Callout Exception: ' + e.getMessage());
            this.timedOutChunks.add(fullNames);
        } catch (Exception e) {
            system.debug('Other Exception: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext ctx){
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
