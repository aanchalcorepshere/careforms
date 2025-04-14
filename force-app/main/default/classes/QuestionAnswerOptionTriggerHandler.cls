public with sharing class QuestionAnswerOptionTriggerHandler implements ITriggerHandler{
    
    public void BeforeInsert(List<SObject> newItems)
    {
        doUpdateQuestionText((List<Question_Answer_Option__c>)newItems, true, true);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {}
    
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {}
    
    public void AfterInsert(Map<Id, SObject> newItems)
    {
        doRoll((List<Question_Answer_Option__c>)newItems.values(), null, null, true, false, false);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {
        doRoll((List<Question_Answer_Option__c>)newItems.values(), null, (Map<Id, Question_Answer_Option__c>)oldItems, false, true, false);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {
        doRoll(null, (List<Question_Answer_Option__c>)oldItems.values(), null, false, false, true);
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {}
    
    public static void doRoll(List<caresp__Question_Answer_Option__c> newTrigger,List<caresp__Question_Answer_Option__c> oldTrigger, Map<Id, caresp__Question_Answer_Option__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete){
        Set<Id> quesIdSet = new Set<Id>();
        Map<Id, String> questIdAndAnsOptsMap = new Map<Id, String>();
        List<caresp__Question__c> questListToBeUpdated = new List<caresp__Question__c>();
        
        if (isInsert || isUpdate) {
            for (caresp__Question_Answer_Option__c qaOpt : newTrigger) {           
                if (isInsert || (isUpdate && qaOpt.caresp__Sequence__c != oldMap.get(qaOpt.Id).caresp__Sequence__c)) {
                    if (String.isNotEmpty(qaOpt.caresp__Answer_Text__c)) { 
                        quesIdSet.add(qaOpt.caresp__Question__c);
                    }
                }
            }
        }
        if (isDelete) {
            for (caresp__Question_Answer_Option__c oldQAOpt : oldTrigger) {
                if (String.isNotEmpty(oldQAOpt.caresp__Answer_Text__c)) {
                    quesIdSet.add(oldQAOpt.caresp__Question__c);
                }
            }
           
        }
        if (quesIdSet.size() > 0) {
            for (caresp__Question_Answer_Option__c qaOpt : [ SELECT Question__c, Answer_Text__c FROM Question_Answer_Option__c WHERE Question__c IN :quesIdSet WITH SECURITY_ENFORCED ORDER BY Sequence__c]) {
                if (!questIdAndAnsOptsMap.containsKey(qaOpt.caresp__Question__c)) {
                    questIdAndAnsOptsMap.put(qaOpt.caresp__Question__c, qaOpt.caresp__Answer_Text__c);
                } else {
                    questIdAndAnsOptsMap.put(qaOpt.caresp__Question__c, questIdAndAnsOptsMap.get(qaOpt.caresp__Question__c) + '|' + qaOpt.caresp__Answer_Text__c);
                } 
            }
            for (caresp__Question__c ques : [ SELECT Id, Answer_Options__c FROM Question__c WHERE Id IN :quesIdSet WITH SECURITY_ENFORCED] ) {
                ques.caresp__Answer_Options__c = (questIdAndAnsOptsMap.containsKey(ques.Id)) ? questIdAndAnsOptsMap.get(ques.Id) : '';
                questListToBeUpdated.add(new caresp__Question__c(Id = ques.Id, caresp__Answer_Options__c = ques.caresp__Answer_Options__c));
            }
            if (questListToBeUpdated.size() > 0) {
                if (Schema.sObjectType.caresp__Question__c.isUpdateable()) {//added by sg
                    update  Security.stripInaccessible(AccessType.UPDATABLE, questListToBeUpdated).getRecords();

                   // update questListToBeUpdated;
                }
            }            
        }
    }  
   
    public static void doUpdateQuestionText(List<Question_Answer_Option__c> newTrigger, Boolean isInsert, Boolean isBefore){
        if(isInsert && isBefore){
            List<String> quesIdList = new List<String>();
            for(caresp__Question_Answer_Option__c ansOp:newTrigger){
                quesIdList.add(ansOp.Question__c);
            }
            
            Map<Id, caresp__Question__c> quesMap = new Map<Id, caresp__Question__c>([select Id, Question_Text__c from Question__c where Id in :quesIdList WITH SECURITY_ENFORCED]);
            
            for(caresp__Question_Answer_Option__c ansOp:newTrigger){
                ansOp.caresp__Question_Text__c = quesMap.get(ansOp.caresp__Question__c).caresp__Question_Text__c;
            }
        }
    }
}