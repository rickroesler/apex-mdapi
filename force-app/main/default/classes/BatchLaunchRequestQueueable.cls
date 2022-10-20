public class BatchLaunchRequestQueueable implements Queueable, Schedulable {
    public class BatchLaunchRequestException extends Exception {}

    private static final String BATCH_LAUNCH_REQUEST_ENDPOINT = 'batch/launchRequest';

    public void execute(SchedulableContext ctx) {
        System.enqueueJob(this);
    }

    public void execute(QueueableContext ctx) {
        try {
            sendReadyNotificationToElements();
        } catch(Exception e) {
            system.debug(e.getTypeName() + ': ' + e.getMessage());
        }
    }

    private void sendReadyNotificationToElements() {
        // temporary for standalone; will be replace by call to Elements makeRequest()
        String endpoint = 'https://5d4b-172-114-128-36.ngrok.io/' + BATCH_LAUNCH_REQUEST_ENDPOINT;
        String publicKey = 'L82vG0W03qPXwNRXrl46';
        String authorization = UserInfo.getOrganizationId() + '.' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOF(publicKey + '.' + UserInfo.getOrganizationId() + '.1ZAiTn3FVvgOpwWBbGl1FFSuwkl8lt9pxuE8Fj5uAqDpusZRXa')));
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', authorization);
        req.setMethod('POST');
        req.setBody('{}'); // currently no information is sent to PKServer about the batch job to be launched

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) throw new BatchLaunchRequestException(res.getStatus() + ': ' + res.getBody());
    }
}
