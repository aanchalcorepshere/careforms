public with sharing class AnswerTriggerHandler implements ITriggerHandler
{
	public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        checkAnswerInUse((Map<Id, caresp__Answer__c>)newItems, (Map<Id, caresp__Answer__c>)oldItems);
    }  
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        checkAnswerInUse(new Map<Id, caresp__Answer__c>(), (Map<Id, caresp__Answer__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems)
    {}
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}
    
    public static void checkAnswerInUse(Map<Id, Answer__c> mapOfAnswer, Map<Id, caresp__Answer__c> oldItems){
        List<caresp__Question_Answer_Option__c> quesAnsList = new List<caresp__Question_Answer_Option__c>();
        
        if(Trigger.isUpdate){
            quesAnsList = [select Id, Answer__c from Question_Answer_Option__c where Answer__c in :mapOfAnswer.keySet() WITH SECURITY_ENFORCED];
        }else if(Trigger.isDelete){
            quesAnsList = [select Id, Answer__c from Question_Answer_Option__c where Answer__c in :oldItems.keySet() WITH SECURITY_ENFORCED];
        }

        System.debug('quesAnsList >> '+quesAnsList);

        for(caresp__Question_Answer_Option__c quesAns:quesAnsList){
            if(Trigger.isUpdate){
                for(caresp__Answer__c ans : mapOfAnswer.values()){
                    if(quesAns.caresp__Answer__c == ans.Id){
                        if(ans.caresp__Answer_Text__c != oldItems.get(ans.Id).caresp__Answer_Text__c){
                            ans.addError('This Answer cannot be edited.');
                        }else if((ans.caresp__Active__c != oldItems.get(ans.Id).caresp__Active__c) && ans.caresp__Active__c == false){
                            ans.addError('This Answer cannot be de-activated.');
                        }
                    }
                }
            }else if(Trigger.isDelete){
                for(caresp__Answer__c ans : oldItems.values()){
                    if(quesAns.caresp__Answer__c == ans.Id){
                        ans.addError('This Answer cannot be deleted.');
                    }
                }
            }
        }
    }

}