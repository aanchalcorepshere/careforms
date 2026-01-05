/**
 * @description Interface for extensible additional lookup retrieval and saving logic in Assessment module.
 * Client orgs can implement this interface to customize how additional lookup records are retrieved and saved
 * during assessment launch. This interface supports any parent-child object relationship configuration.
 */
global interface IAssessmentAdditionalLookupProvider {
    
    /**
     * Retrieves list of additional lookup options available for assessment launch.
     * @param recordId The ID of the source record (parent object)
     * @param objectName The API name of the source object (e.g., caresp__Referral__c)
     * @return JSON string of PicklistWrapper array with lookup record Id and Name
     */
    String getAdditionalLookupOptions(String recordId, String objectName);
    
    /**
     * Saves the additional lookup association to the Outcome record.
     * @param outcomeId The ID of the Outcome record
     * @param lookupRecordId The ID of the selected lookup record
     * @param objectName The API name of the source object
     */
    void saveAdditionalLookupAssociation(Id outcomeId, String lookupRecordId, String objectName);
    
    /**
     * Filters assessments based on custom logic (e.g., Objects__c and filter field values).
     * This method is optional - if not implemented, package uses default filtering logic.
     * @param recordId The ID of the source record (parent object)
     * @param objectName The API name of the source object (e.g., caresp__Referral__c)
     * @param assessmentIds JSON string of assessment IDs to filter
     * @return JSON string of filtered assessment IDs
     */
    String filterAssessments(String recordId, String objectName, String assessmentIds);
}