public with sharing class GetProfileMetadataBatch implements Database.Batchable<List<String>>, Database.AllowsCallouts {
    private static final Integer MAX_READ_SIZE = 10; // max number of items in a single readMetadata() call

    public GetProfileMetadataBatch() {

    }

    public List<List<String>> start(Database.BatchableContext ctx) {
        return null;
    }

    public void execute(Database.BatchableContext ctx, List<List<String>> chunks){
        system.debug(chunks);
        // by design, there should only ever be a single chunk (ie, a single list of profile fullNames)
        if (chunks.size() != 1) {
            system.debug('chunk size error: ' + chunks.size());
            return;
        }
        List<String> fullNames = chunks[0];

    }

    public void finish(Database.BatchableContext ctx){}
}
