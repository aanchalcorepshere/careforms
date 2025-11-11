// Handler class for Question Bank trigger operations: insert, update, delete validations.
public with sharing class QuestionBankTriggerHandler implements ITriggerHandler
{
    // Handles logic before inserting Question Bank records.
    public void BeforeInsert(List<SObject> newItems)
    {
        checkDuplicateQuestion((List<caresp__Question_Bank__c>)newItems);
    }
    
    // Handles logic before updating Question Bank records.
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        checkQuestionInUse((Map<Id, caresp__Question_Bank__c>)newItems,  (Map<Id, caresp__Question_Bank__c>)oldItems);
        checkDuplicateQuestion((List<caresp__Question_Bank__c>)newItems.values());
    }  
    
    // Handles logic before deleting Question Bank records.
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {
        checkQuestionInUse((Map<Id, caresp__Question_Bank__c>)oldItems, new Map<Id, caresp__Question_Bank__c>());
    }
    
    // Placeholder for after insert logic.
    public void AfterInsert(Map<Id, SObject> newItems)
    {}
    
    // Placeholder for after update logic.
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    // Placeholder for after delete logic.
    public void AfterDelete(Map<Id, SObject> oldItems)
    {}
    
    // Placeholder for after undelete logic.
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}

    // Validates that question text is not blank and doesn't already exist.
    public static void checkDuplicateQuestion(List<caresp__Question_Bank__c> listOfQusBank)
    {
        List<caresp__Question_Bank__c> existingQuesBank = [
            SELECT Id, caresp__Question_Text__c 
            FROM caresp__Question_Bank__c 
            WITH USER_MODE 
            LIMIT 50000
        ];

        for(caresp__Question_Bank__c rec : listOfQusBank){
            if(String.isBlank(rec.caresp__Question_Text__c)){
                rec.addError('Question text is required.');
            } else {
                for(caresp__Question_Bank__c existingRec : existingQuesBank){
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

    // Checks if a question is in use before allowing updates or deletes.
    public static void checkQuestionInUse(Map<Id, caresp__Question_Bank__c> mapOfQuesBank, Map<Id, caresp__Question_Bank__c> oldItems){
        if(Trigger.isUpdate){
            List<caresp__Question__c> quesList = [
                SELECT Id, caresp__Question_Bank__c 
                FROM caresp__Question__c 
                WHERE caresp__Question_Bank__c IN :mapOfQuesBank.keySet() 
                WITH USER_MODE
            ];

            for(caresp__Question__c ques : quesList){
                for(caresp__Question_Bank__c qb : mapOfQuesBank.values()){
                    if(ques.caresp__Question_Bank__c == qb.Id){
                        if(qb.caresp__Question_Text__c != oldItems.get(qb.Id).caresp__Question_Text__c){
                            qb.addError('This Question cannot be edited.');
                        } else if((qb.caresp__Active__c != oldItems.get(qb.Id).caresp__Active__c) && qb.caresp__Active__c == false){
                            qb.addError('This Question cannot be de-activated.');
                        }
                    }
                }
            }
        } else if(Trigger.isDelete){
            List<caresp__Question__c> quesList = [
                SELECT Id, caresp__Question_Bank__c 
                FROM caresp__Question__c 
                WHERE caresp__Question_Bank__c IN :mapOfQuesBank.keySet() 
                WITH USER_MODE
            ];

            for(caresp__Question__c ques : quesList){
                for(caresp__Question_Bank__c qb : mapOfQuesBank.values()){
                    if(ques.caresp__Question_Bank__c == qb.Id){
                        qb.addError('This Question cannot be deleted.');
                    }
                }
            }
        }
    }
}