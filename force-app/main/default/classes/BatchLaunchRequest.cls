public class BatchLaunchRequest implements Schedulable {
    public class BatchLaunchRequestException extends Exception {}

    public BatchLaunchRequest() {}  // currently nothing to do in the constructor

    public void execute(SchedulableContext ctx) {
        System.enqueueJob(new ElementsNotification());
    }

    class ElementsNotification implements Queueable, Database.AllowsCallouts {
        private final String BATCH_LAUNCH_REQUEST_ENDPOINT = '/api/v1/salesforce/batch/launchRequest';

        public void execute(QueueableContext ctx) {
            try {
                sendReadyNotificationToElements();
            } catch(Exception e) {
                system.debug(e.getTypeName() + ': ' + e.getMessage());
            }
        }

        private void sendReadyNotificationToElements() {
            String body = '{}'; // currently no information is sent to PKServer about the batch job to be launched

            ElementsApi.Result result = ElementsApi.makeRequest(
                'Batch Launch Request',
                'POST',
                ElementsUtils.getApiEndpoint(BATCH_LAUNCH_REQUEST_ENDPOINT),
                null,
                body
            );

            if (!result.isSuccess()) throw new BatchLaunchRequestException('BatchLaunchRequest: ' + result.getErrorMessage());
        }
    }
}
