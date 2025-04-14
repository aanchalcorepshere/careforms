public with sharing class QuestionBankTriggerHandler implements ITriggerHandler
{
    public void BeforeInsert(List<SObject> newItems)
    {
        checkDuplicateQuestion((List<Question_Bank__c>)newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        checkQuestionInUse((Map<Id, Question_Bank__c>)newItems,  (Map<Id, Question_Bank__c>)oldItems);
        checkDuplicateQuestion((List<Question_Bank__c>)newItems.values());
    }  
    
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {
        checkQuestionInUse((Map<Id, Question_Bank__c>)oldItems, new Map<Id, Question_Bank__c>());
    }
    
    public void AfterInsert(Map<Id, SObject> newItems)
    {}
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}
    
    public static void checkDuplicateQuestion(List<Question_Bank__c> listOfQusBank)
    {
        List<caresp__Question_Bank__c> existingQuesBank = [select Id, Question_Text__c from Question_Bank__c WITH SECURITY_ENFORCED LIMIT 50000];

            for(caresp__Question_Bank__c rec:listOfQusBank){
                if(String.isBlank(rec.caresp__Question_Text__c)){
                    rec.addError('Question text is required.');
                }else{
                 	for(caresp__Question_Bank__c existingRec:existingQuesBank){
                        String s = rec.caresp__Question_Text__c;
                        if(String.isNotBlank(s)){
                            if(s.trim().equalsIgnoreCase(existingRec.caresp__Question_Text__c.trim()) && rec.Id != existingRec.Id){
                                rec.addError('This Question already exists.');
                            }
                        }
                    }   
                }
            }
    }

    public static void checkQuestionInUse(Map<Id, caresp__Question_Bank__c> mapOfQuesBank, Map<Id, caresp__Question_Bank__c> oldItems){
        if(Trigger.isUpdate){
            List<caresp__Question__c> quesList = [select Id, Question_Bank__c from Question__c where Question_Bank__c in :mapOfQuesBank.keySet() WITH SECURITY_ENFORCED];

            for(caresp__Question__c ques:quesList){
                for(caresp__Question_Bank__c qb : mapOfQuesBank.values()){
                    if(ques.caresp__Question_Bank__c == qb.Id){
                        if(qb.caresp__Question_Text__c != oldItems.get(qb.Id).caresp__Question_Text__c){
                            qb.addError('This Question cannot be edited.');
                        }else if((qb.caresp__Active__c != oldItems.get(qb.Id).caresp__Active__c) && qb.caresp__Active__c == false){
                            qb.addError('This Question cannot be de-activated.');
                        }
                    }
                }
            }
        }else if(Trigger.isDelete){
            List<caresp__Question__c> quesList = [select Id, Question_Bank__c from Question__c where Question_Bank__c in :mapOfQuesBank.keySet() WITH SECURITY_ENFORCED];
            
            for(caresp__Question__c ques:quesList){
                for(caresp__Question_Bank__c qb : mapOfQuesBank.values()){
                    if(ques.caresp__Question_Bank__c == qb.Id){
                        qb.addError('This Question cannot be deleted.');
                    }
                }
            }
        }
    }

}