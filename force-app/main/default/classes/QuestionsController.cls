// Controller class to manage Questions and related operations
public with sharing class QuestionsController {

    // Returns all questions filtered by active status
    @AuraEnabled(cacheable=true)
    public static List<caresp__Question__c> getAllQuestions(Boolean active) {
        
        return [
                SELECT Id, caresp__Question_Text__c, caresp__Question_Data_Type__c, caresp__Question_Category__c, 
                    caresp__Answer_Options__c, caresp__Active__c 
                FROM caresp__Question__c 
                WHERE caresp__Active__c = :active 
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 10000
            ];
    }

    // Returns all answer options for a given question ID
    @AuraEnabled
    public static List<caresp__Question_Answer_Option__c> getAnswerOptions(String quesId) {
        Id questionId;
        if(String.isNotBlank(quesId)){
         	questionId = Id.valueOf(quesId);   
        }else{
            questionId = null;
        }
        
        return [
                SELECT Id, caresp__Answer__c, caresp__Answer_Text__c, caresp__Question__c, caresp__Question_Text__c 
                FROM caresp__Question_Answer_Option__c 
                WHERE caresp__Question__c = :questionId 
                WITH USER_MODE
                LIMIT 10000
            ];
    }

    // Deletes a question by its ID if deletable
    @AuraEnabled
    public static void deleteQuestion(String questionId) {
        
        Id validatedQuestionId;
        if(String.isNotBlank(questionId)){
         	validatedQuestionId = Id.valueOf(questionId);   
        }else{
            validatedQuestionId = null;
        }
        
        System.debug(LoggingLevel.Error ,'question deletable>> ' + Schema.sObjectType.caresp__Question__c.isDeletable());
            
            // Permission checks (High fix)
            if (!Schema.sObjectType.caresp__Question__c.isAccessible() || 
                !Schema.sObjectType.caresp__Question__c.isDeletable()) {
                throw new AuraHandledException('Insufficient permissions to delete questions');
            }
            
            // Query the record first to ensure it exists and user has access
            List<caresp__Question__c> questionsToDelete = [
                SELECT Id 
                FROM caresp__Question__c 
                WHERE Id = :validatedQuestionId 
                WITH USER_MODE
                LIMIT 1
            ];
            
            // Delete the question using USER MODE
            Database.delete(questionsToDelete[0], AccessLevel.USER_MODE);
    }
}