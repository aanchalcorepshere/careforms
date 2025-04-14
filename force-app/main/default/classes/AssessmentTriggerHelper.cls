public with sharing class AssessmentTriggerHelper implements ITriggerHandler {
    public void BeforeInsert(List<SObject> newItems)
    {}
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}  
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        checkAssessmentInUse((Map<Id, Assessment__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems)
    {}
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}

    public static void checkAssessmentInUse(Map<Id, caresp__Assessment__c> oldItems){
        List<caresp__Outcome__c> outcomeList = new List<caresp__Outcome__c>();
        
        outcomeList = [select Id, Assessment__c from Outcome__c where Assessment__c in :oldItems.keySet() WITH SECURITY_ENFORCED];

        System.debug('outcomeList >> '+outcomeList);

        for(caresp__Outcome__c outcome:outcomeList){
            for(caresp__Assessment__c assessment : oldItems.values()){
                if(outcome.caresp__Assessment__c == assessment.Id){
                    assessment.addError('This Assessment cannot be deleted.');
                }
            }
        }
    }
}