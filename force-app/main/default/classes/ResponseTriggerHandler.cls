// Handles all trigger events for the Response__c object, including setting question text during insert.
public with sharing class ResponseTriggerHandler implements ITriggerHandler
{
    // Sets question text on Response__c records during before insert trigger.
    public void BeforeInsert(List<SObject> newItems)
    {
        updateQuestionTextOnResponse((List<Response__c>)newItems);        
    }

    // Placeholder for handling logic before update trigger.
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}  

    // Placeholder for handling logic before delete trigger.
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {}

    // Placeholder for handling logic after insert trigger.
    public void AfterInsert(Map<Id, SObject> newItems)
    {}

    // Placeholder for handling logic after update trigger.
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}

    // Placeholder for handling logic after delete trigger.
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}

    // Placeholder for handling logic after undelete trigger.
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}

    // Fetches related question text for each Response__c record and assigns it to Question_Text__c.
    public static void updateQuestionTextOnResponse(List<caresp__Response__c> listResp) {
        
        
        try {
            // Permission checks (High fix)
            if (!Schema.sObjectType.caresp__Response__c.isUpdateable()) {
                throw new System.NoAccessException();
            }
            
            // Use proper Id type for SOQL injection prevention (Critical fix)
            List<Id> asQuesIdList = new List<Id>();
            for(caresp__Response__c resp : listResp){
                // Null check to prevent issues (High fix)
                if(resp.caresp__Assessment_Question__c != null) {
                    asQuesIdList.add(resp.caresp__Assessment_Question__c);
                }
            }
            

            // Query assessment questions with related question text; enforces FLS and OLS.
            Map<Id, caresp__Assessment_Question__c> asQuesMap = new Map<Id, caresp__Assessment_Question__c>(
                [SELECT Id, caresp__Question__r.caresp__Question_Text__c 
                FROM caresp__Assessment_Question__c 
                WHERE Id IN :asQuesIdList 
                WITH USER_MODE]
            );

            // Update response records with question text
            for(caresp__Response__c resp : listResp){
                if(resp.caresp__Assessment_Question__c != null && 
                asQuesMap.containsKey(resp.caresp__Assessment_Question__c)){
                    caresp__Assessment_Question__c asQuestion = asQuesMap.get(resp.caresp__Assessment_Question__c);
                    if(asQuestion != null && asQuestion.caresp__Question__r != null) {
                        resp.caresp__Question_Text__c = asQuestion.caresp__Question__r.caresp__Question_Text__c;   
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error in updateQuestionTextOnResponse: ' + e.getMessage());
            throw new System.CalloutException('An unexpected error occurred while updating question text');
        }
    }
}