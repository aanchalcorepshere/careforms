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
        //Boolean formsAvailable = false;
        if (formsAvailable == false) {
            throw new AuraHandledException(ERROR_FORMS_UNAVAILABLE);
        }
    }

    /** Returns the raw flag value. Callers must treat null as enabled. */
    public static Boolean isFormsAvailable() {
        return System.FeatureManagement.checkPackageBooleanValue(PARAM_FORMS_AVAILABLE);
    }

    /** Payload for LWC feature gating (null flag = enabled). */
    public class FormsFeatureGateDto {
        @AuraEnabled
        public Boolean formsEnabled { get; set; }
        @AuraEnabled
        public String unavailableMessage { get; set; }
    }

    /**
     * Read-only gate for Forms UI. Null FormsAvailable is treated as enabled.
     */
    @AuraEnabled(cacheable=true)
    public static FormsFeatureGateDto getFormsFeatureGate() {
        FormsFeatureGateDto dto = new FormsFeatureGateDto();
        Boolean raw = System.FeatureManagement.checkPackageBooleanValue(PARAM_FORMS_AVAILABLE);
        //Boolean raw = false;
        dto.formsEnabled = (raw != false);
        dto.unavailableMessage = dto.formsEnabled ? null : ERROR_FORMS_UNAVAILABLE;
        return dto;
    }
}