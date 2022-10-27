public class BatchLaunchRequest implements Schedulable {
    public class BatchLaunchRequestException extends Exception {}

    public BatchLaunchRequest() {}  // currently nothing to do in the constructor

    public void execute(SchedulableContext ctx) {
        System.enqueueJob(new ElementsNotification());
    }

    @TestVisible class ElementsNotification implements Queueable, Database.AllowsCallouts {
        private final String BATCH_LAUNCH_REQUEST_ENDPOINT = '/api/v1/salesforce/batch/launchRequest';
        private final List<String> BATCH_RUNNING_STATUSES = new List<String>{'Holding','Queued','Preparing','Processing'};
        private final String BATCH_CLASS_NAME = 'GetMetadataXmlBatch';
        private final String BATCH_CLASS_NAMESPACE = 'Q9';
    
        public void execute(QueueableContext ctx) {
            try {
                if (!isBatchRunning(BATCH_CLASS_NAMESPACE, BATCH_CLASS_NAME)) sendReadyNotificationToElements();
            } catch(Exception e) {
                system.debug(e.getTypeName() + ': ' + e.getMessage());
            }
        }

        private Boolean isBatchRunning(String batchClassNamespace, String batchClassName) {
            List<AsyncApexJob> batchJobs = [SELECT Id
                                              FROM AsyncApexJob
                                             WHERE ApexClass.NamespacePrefix = :batchClassNamespace
                                               AND ApexClass.Name = :batchClassName
                                               AND Status IN :BATCH_RUNNING_STATUSES];
            return (!batchJobs.isEmpty());
        }

        @TestVisible private ElementsApi.Result sendReadyNotificationToElements() {
            String body = '{}'; // currently no information is sent to PKServer about the batch job to be launched

            ElementsApi.Result result = ElementsApi.makeRequest(
                'Batch Launch Request',
                'POST',
                ElementsUtils.getApiEndpoint(BATCH_LAUNCH_REQUEST_ENDPOINT),
                null,
                body
            );

            if (!result.isSuccess()) throw new BatchLaunchRequestException('BatchLaunchRequest: ' + result.getErrorMessage());
    
            return result;
        }
    }
}
