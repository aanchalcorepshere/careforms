// Controller class to fetch active Answer__c records based on search criteria
public with sharing class AnswerSelectionController {

    // Method to retrieve active Answer__c records, with optional search filtering on Answer_Text__c
    @AuraEnabled(cacheable=true)
    public static List<caresp__Answer__c> getActiveAnswers(String searchTerm) {
        try {
            List<caresp__Answer__c> answerList = new List<caresp__Answer__c>();
            
            // Input validation and sanitization (Critical fix)
            String sanitizedSearchTerm = null;
            if (String.isNotBlank(searchTerm)) {
                sanitizedSearchTerm = String.escapeSingleQuotes(searchTerm.trim());
                
                // Validate search term length for performance
                if (sanitizedSearchTerm.length() < 2) {
                    sanitizedSearchTerm = null; // Treat as no search term if too short
                }
            }
            
            // Single query approach for better performance (High fix)
            if (String.isBlank(sanitizedSearchTerm)) {
                // Query without search filter
                answerList = [
                    SELECT Id, caresp__Answer_Text__c 
                    FROM caresp__Answer__c 
                    WHERE caresp__Active__c = true 
                    WITH USER_MODE 
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1000
                ];
            } else {
                // Query with search filter
                String searchPattern = '%' + sanitizedSearchTerm + '%';
                answerList = [
                    SELECT Id, caresp__Answer_Text__c 
                    FROM caresp__Answer__c 
                    WHERE caresp__Active__c = true 
                      AND caresp__Answer_Text__c LIKE :searchPattern 
                    WITH USER_MODE 
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1000
                ];
            }
            
            System.debug(LoggingLevel.DEBUG, 'Found ' + answerList.size() + ' active answers');
            return answerList;
            
        }catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getActiveAnswers: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while retrieving answers: ' + ex.getMessage());
        }
    }
}