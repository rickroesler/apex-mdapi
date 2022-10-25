@isTest
public class BatchLaunchRequestTest {
    @isTest
    public static void sendReadyNotificationTest() {
        Boolean success = true;
        try {
            BatchLaunchRequest.ElementsNotification notifier = new BatchLaunchRequest.ElementsNotification();
            ElementsApi.Result result = notifier.sendReadyNotificationToElements();
            if (!result.isSuccess()) success = false;
        } catch (Exception e) {
            success = false;
        }
        System.assertEquals(true, success, 'Expected success == true');
    }
}
