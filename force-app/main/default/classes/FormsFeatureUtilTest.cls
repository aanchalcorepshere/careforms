@isTest
private class FormsFeatureUtilTest {

    @isTest
    static void testAssertFormsAvailable_whenTrue_doesNotThrow() {
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', true);
        Test.startTest();
        try {
            FormsFeatureUtil.assertFormsAvailable();
            System.assert(true, 'No exception expected when FormsAvailable is true.');
        } catch (AuraHandledException e) {
            System.assert(false, 'Exception should NOT be thrown when FormsAvailable is true.');
        }
        Test.stopTest();
    }

    @isTest
    static void testAssertFormsAvailable_whenFalse_throwsException() {
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', false);
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            FormsFeatureUtil.assertFormsAvailable();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'AuraHandledException must be thrown when FormsAvailable is false.');
    }

    @isTest
    static void testAssertFormsAvailable_whenNull_doesNotThrow() {
        // Do NOT call setPackageBooleanValue — leave null to simulate unset LMO state
        Test.startTest();
        try {
            FormsFeatureUtil.assertFormsAvailable();
            System.assert(true, 'No exception expected when FormsAvailable is null.');
        } catch (AuraHandledException e) {
            System.assert(false, 'Exception should NOT be thrown when FormsAvailable is null.');
        }
        Test.stopTest();
    }

    @isTest
    static void testIsFormsAvailable() {
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', true);
        System.assertEquals(true, FormsFeatureUtil.isFormsAvailable());
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', false);
        System.assertEquals(false, FormsFeatureUtil.isFormsAvailable());
    }

    @isTest
    static void testGetFormsFeatureGate_whenTrue() {
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', true);
        FormsFeatureUtil.FormsFeatureGateDto dto = FormsFeatureUtil.getFormsFeatureGate();
        System.assertEquals(true, dto.formsEnabled, 'formsEnabled must be true when parameter is true.');
        System.assertEquals(null, dto.unavailableMessage, 'Message must be null when enabled.');
    }

    @isTest
    static void testGetFormsFeatureGate_whenFalse() {
        System.FeatureManagement.setPackageBooleanValue('FormsAvailable', false);
        FormsFeatureUtil.FormsFeatureGateDto dto = FormsFeatureUtil.getFormsFeatureGate();
        System.assertEquals(false, dto.formsEnabled, 'formsEnabled must be false when parameter is false.');
        System.assertEquals(
            'The Forms module is not available for your subscription. Please contact your administrator.',
            dto.unavailableMessage
        );
    }
}