/**
 * Controller class for creating and managing questions and their answer options.
 */
public with sharing class CreateNewQuestionCtrl {
    
    /**
     * Checks if a question with the same answer options already exists in the question bank for a given data type.
     */
    @AuraEnabled
    public static String checkDuplicate(String quesBankId, String dataType, List<String> ansOptions) {
        // Validate ID format (Critical fix)
        Id validatedQuesBankId;
        if (!String.isBlank(quesBankId)) {
            validatedQuesBankId = Id.valueOf(quesBankId.trim());
        } else {
            // Handle invalid case (throw error / return null / log etc.)
            validatedQuesBankId = null;
        }
        System.debug('validatedQuesBankId >> '+validatedQuesBankId);
        
        try {
            String resp = 'unique';
            Map<String, List<String>> quesAnsOpMap = new Map<String, List<String>>();

            Map<String, caresp__Question__c> quesMap = new Map<String, caresp__Question__c>([
                select Id, caresp__Question_Data_type__c 
                from caresp__Question__c 
                where caresp__Question_Bank__c = :validatedQuesBankId 
                  and caresp__Question_Data_type__c = :dataType 
                WITH USER_MODE
                LIMIT 10000
            ]);

            if (!quesMap.isEmpty()) {
                List<caresp__Question_Answer_Option__c> quesAnsList = [
                    Select Id, caresp__Answer__c, caresp__Question__c 
                    from caresp__Question_Answer_Option__c 
                    where caresp__Question__c in :quesMap.keySet() 
                    WITH USER_MODE
                    LIMIT 10000
                ];

                if (quesAnsList != null && quesAnsList.size() > 0) {
                    for (caresp__Question_Answer_Option__c qao : quesAnsList) {
                        if (qao != null && qao.caresp__Question__c != null) {
                            if (!quesAnsOpMap.containsKey(qao.caresp__Question__c)) {
                                quesAnsOpMap.put(qao.caresp__Question__c, new List<String>());
                            }
                            if (String.isNotBlank(qao.caresp__Answer__c)) {
                                quesAnsOpMap.get(qao.caresp__Question__c).add(qao.caresp__Answer__c);
                            }
                        }
                    }   
                }
                
                // Safe list operations (High fix)
                if (ansOptions != null && ansOptions.size() > 0) {
                    ansOptions.sort();
                }
                
                if (!quesAnsOpMap.isEmpty()) {
                    for (String q : quesAnsOpMap.keySet()) {
                        List<String> existingAnswers = quesAnsOpMap.get(q);
                        if (existingAnswers != null) {
                            existingAnswers.sort();
                            if (ansOptions != null && ansOptions.equals(existingAnswers) && resp == 'unique') {
                                resp = 'Duplicate';
                                break; // Early exit for performance
                            }
                        }
                    }
                }
            }

            return resp;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in checkDuplicate: ' + ex.getMessage());
            throw new AuraHandledException('Failed to check for duplicates: ' + ex.getMessage());
        }
    }

    /**
     * Checks if a question record is editable by verifying if it is linked to any Assessment Questions.
     */
    @AuraEnabled
    public static Boolean checkEditable(String recId) {
        //Id validatedRecId = (recId != null) ? recId.trim().replaceAll('[^a-zA-Z0-9]', '') : null;
        Id validatedRecId;
        if (!String.isBlank(recId)) {
            validatedRecId = Id.valueOf(recId.trim());
        } else {
            // Handle invalid case (throw error / return null / log etc.)
            validatedRecId = null;
        }
        
        try {
            List<caresp__Assessment_Question__c> aqList = [
                select Id 
                from caresp__Assessment_Question__c 
                where caresp__Question__c = :validatedRecId 
                WITH USER_MODE
                LIMIT 1
            ];

            return aqList.isEmpty();
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in checkEditable: ' + ex.getMessage());
            throw new AuraHandledException('Failed to check editability: ' + ex.getMessage());
        }
    }

   /**
    * Creates a new question record after stripping inaccessible fields.
    */
   @AuraEnabled
   public static String createQuestion(caresp__Question__c question) {
       
       System.debug(LoggingLevel.Error ,'question>>> ' + question);
           
        // Prepare the list of records and strip inaccessible fields
        List<caresp__Question__c> questionList = new List<caresp__Question__c>{ question };
        List<caresp__Question__c> safeQuestions = Security.stripInaccessible(AccessType.CREATABLE, questionList).getRecords();
        System.debug(LoggingLevel.Error ,'safeQuestions>>> ' + safeQuestions);

        // Perform the insert operation with consistent security model (High fix)
        List<Database.SaveResult> results = Database.insert(safeQuestions, false, AccessLevel.USER_MODE);

        // Check if the first operation succeeded and return the ID (High fix)
        if (!results.isEmpty() && results[0].isSuccess()) {
            return safeQuestions[0].Id;
        }
        
        return null;
   }

    /**
     * Updates a question record and deletes related answer options if necessary.
     */
    @AuraEnabled
    public static String updateQuestion(caresp__Question__c question) {
        
        try {
            List<caresp__Question_Answer_Option__c> ansOpList = [
                select Id 
                from caresp__Question_Answer_Option__c 
                where caresp__Question__c = :question.Id 
                WITH USER_MODE
                LIMIT 10000
            ];

            // Delete existing answer options if they exist
            if (!ansOpList.isEmpty()) {
                List<caresp__Question_Answer_Option__c> deletableOptions = Security.stripInaccessible(
                    AccessType.READABLE, 
                    ansOpList
                ).getRecords();
                
                if (!deletableOptions.isEmpty()) {
                    Database.delete(deletableOptions, AccessLevel.USER_MODE);
                }
            }
            
            // Update the question with consistent security model (High fix)
            List<caresp__Question__c> questionsToUpdate = new List<caresp__Question__c>{question};
            List<caresp__Question__c> updatableQuestions = Security.stripInaccessible(
                AccessType.UPDATABLE, 
                questionsToUpdate
            ).getRecords();
            
            if (!updatableQuestions.isEmpty()) {
                Database.update(updatableQuestions, AccessLevel.USER_MODE);
                return updatableQuestions[0].Id;
            } else {
                throw new AuraHandledException('Insufficient permissions to update question');
            }
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in updateQuestion: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while updating question: ' + ex.getMessage());
        }
    }

    /**
     * Creates answer options for a question.
     */
    @AuraEnabled
    public static void createAnsOptions(List<caresp__Question_Answer_Option__c> ansOptions, Boolean isEdit) {
        try {
            List<caresp__Question_Answer_Option__c> creatableOptions = Security.stripInaccessible(
                AccessType.CREATABLE, 
                ansOptions
            ).getRecords();
            
            if (!creatableOptions.isEmpty()) {
                Database.insert(creatableOptions, AccessLevel.USER_MODE);
            }
            
        }catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in createAnsOptions: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while creating answer options: ' + ex.getMessage());
        }
    }
    
    /**
     * Retrieves question data and associated answer options.
     */
    @AuraEnabled
    public static QuestionWrapper getQuestionData(String recordId) {
        // Validate ID format (Critical fix)
        //String validatedRecordId = (recordId != null) ? recordId.trim().replaceAll('[^a-zA-Z0-9]', '') : null;
        Id validatedRecordId;
        if (!String.isBlank(recordId)) {
            validatedRecordId = Id.valueOf(recordId.trim());
        } else {
            // Handle invalid case (throw error / return null / log etc.)
            validatedRecordId = null;
        }
        
        try {
            QuestionWrapper quesWrapper = new QuestionWrapper();
            
            List<caresp__Question__c> questionList = [
                select Id, caresp__Question_Bank__c, caresp__Question_Data_type__c, caresp__Question_Category__c, 
                       caresp__Question_Text__c, caresp__Is_Dependent__c 
                from caresp__Question__c 
                where Id = :validatedRecordId 
                WITH USER_MODE
                LIMIT 1
            ];
            
            // Safe array access (High fix)
            if (questionList.isEmpty()) {
                throw new AuraHandledException('Question not found or insufficient permissions');
            }
            
            caresp__Question__c quesRec = questionList[0];
            
            List<caresp__Question_Answer_Option__c> ansOpList = [
                select Id, caresp__Answer__c, caresp__Answer_Text__c, caresp__Sequence__c 
                from caresp__Question_Answer_Option__c 
                where caresp__Question__c = :quesRec.Id 
                WITH USER_MODE
                ORDER BY caresp__Sequence__c
                LIMIT 10000
            ];
            
            quesWrapper.Id = quesRec.Id;
            quesWrapper.quesDataType = quesRec.caresp__Question_Data_type__c;
            quesWrapper.quesCategory = quesRec.caresp__Question_Category__c;
            quesWrapper.quesText = quesRec.caresp__Question_Text__c;
            quesWrapper.quesBank = quesRec.caresp__Question_Bank__c;
            quesWrapper.isDependent = quesRec.caresp__Is_Dependent__c;
            quesWrapper.ansList = ansOpList;
            
            return quesWrapper;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getQuestionData: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while retrieving question: ' + ex.getMessage());
        }
    }
    
    /**
     * Wrapper class to hold question details and answer options.
     */
    public class QuestionWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String quesDataType;
        @AuraEnabled public String quesCategory;
        @AuraEnabled public String quesText;
        @AuraEnabled public String quesBank;
        @AuraEnabled public Boolean isDependent;
        @AuraEnabled public List<caresp__Question_Answer_Option__c> ansList;
    }
}