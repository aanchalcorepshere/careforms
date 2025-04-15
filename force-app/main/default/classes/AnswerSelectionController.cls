public with sharing class AnswerSelectionController {
    @AuraEnabled(cacheable=true)
    public static List<Answer__c> getActiveAnswers(String searchTerm){
        List<Answer__c> answerList = new List<Answer__c>();
        String searchTermConverted = '';
        if((searchTerm==null || searchTerm=='')){
            answerList = [select Id, Answer_Text__c from Answer__c where Active__c=true WITH SECURITY_ENFORCED order by lastmodifieddate desc];
        }else{
            searchTermConverted = '%'+searchTerm+'%';
            for(Answer__c ans:[select Id, Answer_Text__c from Answer__c where Active__c=true and Answer_Text__c like :searchTermConverted WITH SECURITY_ENFORCED order by lastmodifieddate desc]){
                answerList.add(ans);
            }
        }
        System.debug('answerList ## '+answerList);
        return answerList;
    }
}