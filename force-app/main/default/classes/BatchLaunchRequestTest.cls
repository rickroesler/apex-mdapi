@isTest
public class BatchLaunchRequestTest {
    @isTest
    private static void sendReadyNotificationTest() {
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

    @isTest
    private static void testStartScheduleJob() {
        ElementsSettingsController esc = (new ElementsSettingsControllerBundle()).esc;

        Test.startTest();
        esc.profileMetadataScheduleHours = 0;
        esc.profileMetadataScheduleMinutes = 0;
        esc.startProfileMetadataScheduleJob();
        Test.stopTest();

        System.assertEquals(ApexPages.getMessages().isEmpty(), true);//No messages at all
    }
}
