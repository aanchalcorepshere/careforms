// Trigger handler class for Answer__c object to manage validation logic for DML operations
public with sharing class AnswerTriggerHandler implements ITriggerHandler {

    // Handles logic before inserting Answer__c records
    public void BeforeInsert(List<SObject> newItems) {
        // No logic implemented yet
    }
    
    // Handles logic before updating Answer__c records
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        try {
            checkAnswerInUse((Map<Id, caresp__Answer__c>)newItems, (Map<Id, caresp__Answer__c>)oldItems);
        } catch (Exception e) {
            throw new CalloutException('An error occurred while validating answer updates.');
        }
    }

    // Handles logic before deleting Answer__c records
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        try {
            checkAnswerInUse(new Map<Id, caresp__Answer__c>(), (Map<Id, caresp__Answer__c>)oldItems);
        } catch (Exception e) {
            throw new CalloutException('An error occurred while validating answer deletion.');
        }
    }

    // Handles logic after inserting Answer__c records
    public void AfterInsert(Map<Id, SObject> newItems) {
        // No logic implemented yet
    }

    // Handles logic after updating Answer__c records
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        // No logic implemented yet
    }

    // Handles logic after deleting Answer__c records
    public void AfterDelete(Map<Id, SObject> oldItems) {
        // No logic implemented yet
    }

    // Handles logic after undeleting Answer__c records
    public void AfterUndelete(Map<Id, SObject> oldItems) {
        // No logic implemented yet
    }

    // Validates if an Answer__c record is in use and restricts update/delete accordingly
    public static void checkAnswerInUse(Map<Id, caresp__Answer__c> mapOfAnswer, Map<Id, caresp__Answer__c> oldItems) {
        // Input validation (Critical fix)
        if ((Trigger.isUpdate && (mapOfAnswer == null || mapOfAnswer.isEmpty())) ||
            (Trigger.isDelete && (oldItems == null || oldItems.isEmpty()))) {
            return;
        }
        
        // Additional validation for update operations
        if (Trigger.isUpdate && oldItems == null) {
            return;
        }

        try {
            List<caresp__Question_Answer_Option__c> quesAnsList = new List<caresp__Question_Answer_Option__c>();

            if (Trigger.isUpdate) {
                quesAnsList = [
                    SELECT Id, caresp__Answer__c 
                    FROM caresp__Question_Answer_Option__c 
                    WHERE caresp__Answer__c IN :mapOfAnswer.keySet() 
                    WITH USER_MODE
                    LIMIT 10000
                ];
            } else if (Trigger.isDelete) {
                quesAnsList = [
                    SELECT Id, caresp__Answer__c 
                    FROM caresp__Question_Answer_Option__c 
                    WHERE caresp__Answer__c IN :oldItems.keySet() 
                    WITH USER_MODE
                    LIMIT 10000
                ];
            }

            System.debug(LoggingLevel.Debug, 'quesAnsList >> ' + quesAnsList);

            // Performance optimization - create lookup set for O(1) access (High fix)
            Set<Id> answersInUse = new Set<Id>();
            for (caresp__Question_Answer_Option__c quesAns : quesAnsList) {
                if (quesAns != null && quesAns.caresp__Answer__c != null) {
                    answersInUse.add(quesAns.caresp__Answer__c);
                }
            }

            if (Trigger.isUpdate) {
                // Process each answer that is in use (High fix - O(n) instead of O(n²))
                for (Id answerId : answersInUse) {
                    caresp__Answer__c currentAnswer = mapOfAnswer.get(answerId);
                    caresp__Answer__c oldAnswer = oldItems.get(answerId);
                    
                    if (currentAnswer != null && oldAnswer != null) {
                        // Safe textarea field comparison (Critical fix)
                        String currentText = currentAnswer.caresp__Answer_Text__c != null ? 
                            currentAnswer.caresp__Answer_Text__c : '';
                        String oldText = oldAnswer.caresp__Answer_Text__c != null ? 
                            oldAnswer.caresp__Answer_Text__c : '';
                        
                        if (!currentText.equals(oldText)) {
                            currentAnswer.addError('This Answer cannot be edited.');
                        } else if ((currentAnswer.caresp__Active__c != oldAnswer.caresp__Active__c) && 
                                currentAnswer.caresp__Active__c == false) {
                            currentAnswer.addError('This Answer cannot be de-activated.');
                        }
                    }
                }
            } else if (Trigger.isDelete) {
                // Add errors to answers that are in use (High fix - O(n) instead of O(n²))
                for (Id answerId : answersInUse) {
                    caresp__Answer__c answer = oldItems.get(answerId);
                    if (answer != null) {
                        answer.addError('This Answer cannot be deleted.');
                    }
                }
            }
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in checkAnswerInUse: ' + ex.getMessage());
            // Don't throw exception in trigger context, just log and add errors to records (High fix)
            Map<Id, caresp__Answer__c> recordsToAddError = Trigger.isUpdate ? mapOfAnswer : oldItems;
            if (recordsToAddError != null) {
                for (caresp__Answer__c answer : recordsToAddError.values()) {
                    if (answer != null) {
                        answer.addError('Error validating answer usage: ' + ex.getMessage());
                    }
                }
            }
        }
    }
}