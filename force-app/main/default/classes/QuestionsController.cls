public with sharing class QuestionsController {
    @AuraEnabled(cacheable=true)
    public static List<Question__c> getAllQuestions(Boolean active){
        return [select Id, Question_Text__c, Question_Data_Type__c, Question_Category__c, Answer_Options__c, Active__c from Question__c where Active__c =: active WITH SECURITY_ENFORCED order by createddate desc];
    }

    @AuraEnabled
    public static List<Question_Answer_Option__c> getAnswerOptions(String quesId){
        System.debug('Ques ID # '+quesId);
        return [select Id, Answer__c, Answer_Text__c, Question__c, Question_Text__c from Question_Answer_Option__c where Question__c =:quesId WITH SECURITY_ENFORCED];
    }

    @AuraEnabled
    public static void deleteQuestion(String questionId){
        System.debug('question deletable>> ' + Schema.sObjectType.caresp__Question__c.isDeletable());
        if(String.isNotBlank(questionId)){
            if(Schema.sObjectType.caresp__Question__c.isDeletable()) {//added by sg
            delete as user [select Id from Question__c where Id = :questionId WITH SECURITY_ENFORCED];
            }
        }
    }
}