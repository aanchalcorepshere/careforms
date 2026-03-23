public with sharing class FormsFeatureUtil {

    private static final String PARAM_FORMS_AVAILABLE = 'FormsAvailable';
    private static final String ERROR_FORMS_UNAVAILABLE =
        'The Forms module is not available for your subscription. Please contact your administrator.';

    /**
     * Throws AuraHandledException if FormsAvailable is explicitly false.
     * Null (unset by LMO) is treated as enabled — preserves access for all
     * existing subscribers before this parameter was introduced.
     */
    public static void assertFormsAvailable() {
        Boolean formsAvailable = System.FeatureManagement.checkPackageBooleanValue(PARAM_FORMS_AVAILABLE);
        if (formsAvailable == false) {
            throw new AuraHandledException(ERROR_FORMS_UNAVAILABLE);
        }
    }

    /** Returns the raw flag value. Callers must treat null as enabled. */
    public static Boolean isFormsAvailable() {
        return System.FeatureManagement.checkPackageBooleanValue(PARAM_FORMS_AVAILABLE);
    }
}
