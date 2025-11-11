// Trigger helper class for handling Assessment__c trigger events.
public with sharing class AssessmentTriggerHelper implements ITriggerHandler {

    // Handles logic before Assessment__c records are inserted.
    public void BeforeInsert(List<SObject> newItems)
    {}

    // Handles logic before Assessment__c records are updated.
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}  

    // Handles logic before Assessment__c records are deleted.
    public void BeforeDelete(Map<Id, SObject> oldItems){
        checkAssessmentInUse((Map<Id, Assessment__c>)oldItems);
    }

    // Handles logic after Assessment__c records are inserted.
    public void AfterInsert(Map<Id, SObject> newItems)
    {}

    // Handles logic after Assessment__c records are updated.
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}

    // Handles logic after Assessment__c records are deleted.
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}

    // Handles logic after Assessment__c records are undeleted.
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}

    // Validates if an Assessment__c record is used in Outcome__c before allowing delete.
    public static void checkAssessmentInUse(Map<Id, caresp__Assessment__c> oldItems){
        List<caresp__Outcome__c> outcomeList = new List<caresp__Outcome__c>();

        outcomeList = [select Id, Assessment__c from Outcome__c where Assessment__c in :oldItems.keySet() WITH USER_MODE];

        System.debug(LoggingLevel.Error, 'outcomeList >> '+outcomeList);

        for(caresp__Outcome__c outcome:outcomeList){
            for(caresp__Assessment__c assessment : oldItems.values()){
                if(outcome.caresp__Assessment__c == assessment.Id){
                    assessment.addError('This Assessment cannot be deleted.');
                }
            }
        }
    }
}