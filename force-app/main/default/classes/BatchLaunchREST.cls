@RestResource(urlMapping = '/batchLauncher')
global with sharing class BatchLaunchREST {
    class BatchLaunchException extends Exception {}

    @HttpPost
    // Returns the AsyncApexJob Id of the batch.
    // This implementation assumes that we're going to launch a single pre-defined batch.
    // This batch is then responsible for launching any additional batch jobs (chaining).
    global static String doPost() {
        String result;
    
        // this may not be necessary, but like chicken soup, it can't hurt
        Auth.SessionManagement.setSessionLevel(Auth.SessionLevel.HIGH_ASSURANCE);
        
        List<String> sessionIdParts = UserInfo.getSessionId().split('!');
        String metadataType = 'Profile';

        try {
            result = Database.executeBatch(new GetMetadataXmlBatch(sessionIdParts, metadataType), 1);
        } catch (GetMetadataXmlBatch.MetadataXmlBatchException e) {
            // what do we return here??
        }

        return result;
    }
}
