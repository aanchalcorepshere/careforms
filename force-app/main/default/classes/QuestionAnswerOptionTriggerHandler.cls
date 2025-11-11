// Trigger handler for managing insert, update, and delete logic on Question_Answer_Option__c records.
public with sharing class QuestionAnswerOptionTriggerHandler implements ITriggerHandler {
    
    // Handles logic before inserting Question_Answer_Option__c records.
    public void BeforeInsert(List<SObject> newItems) {
        doUpdateQuestionText((List<Question_Answer_Option__c>)newItems, true, true);
    }
    
    // Handles logic before updating Question_Answer_Option__c records.
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

    // Handles logic before deleting Question_Answer_Option__c records.
    public void BeforeDelete(Map<Id, SObject> oldItems) {}

    // Handles logic after inserting Question_Answer_Option__c records.
    public void AfterInsert(Map<Id, SObject> newItems) {
        doRoll((List<Question_Answer_Option__c>)newItems.values(), null, null, true, false, false);
    }

    // Handles logic after updating Question_Answer_Option__c records.
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        doRoll((List<Question_Answer_Option__c>)newItems.values(), null, (Map<Id, Question_Answer_Option__c>)oldItems, false, true, false);
    }

    // Handles logic after deleting Question_Answer_Option__c records.
    public void AfterDelete(Map<Id, SObject> oldItems) {
        doRoll(null, (List<Question_Answer_Option__c>)oldItems.values(), null, false, false, true);
    }

    // Placeholder for logic after undeleting Question_Answer_Option__c records.
    public void AfterUndelete(Map<Id, SObject> oldItems) {}

    // Recalculates and updates the Answer_Options__c field on related Question__c records based on trigger context.
    public static void doRoll(List<caresp__Question_Answer_Option__c> newTrigger, List<caresp__Question_Answer_Option__c> oldTrigger, Map<Id, caresp__Question_Answer_Option__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete
    ) {
        // Input validation (High fix)
        if ((isInsert || isUpdate) && newTrigger == null) {
            return;
        }
        if (isDelete && oldTrigger == null) {
            return;
        }
        if (isUpdate && oldMap == null) {
            return;
        }
        
        try {
            Set<Id> quesIdSet = new Set<Id>();
            Map<Id, String> questIdAndAnsOptsMap = new Map<Id, String>();
            List<caresp__Question__c> questListToBeUpdated = new List<caresp__Question__c>();

            if (isInsert || isUpdate) {
                for (caresp__Question_Answer_Option__c qaOpt : newTrigger) {
                    // Null safety checks (High fix)
                    if (qaOpt != null && qaOpt.caresp__Question__c != null) {
                        if (isInsert || (isUpdate && oldMap.containsKey(qaOpt.Id) && 
                            qaOpt.caresp__Sequence__c != oldMap.get(qaOpt.Id).caresp__Sequence__c)) {
                            if (String.isNotEmpty(qaOpt.caresp__Answer_Text__c)) {
                                quesIdSet.add(qaOpt.caresp__Question__c);
                            }
                        }
                    }
                }
            }

            if (isDelete) {
                for (caresp__Question_Answer_Option__c oldQAOpt : oldTrigger) {
                    // Null safety checks (High fix)
                    if (oldQAOpt != null && oldQAOpt.caresp__Question__c != null) {
                        if (String.isNotEmpty(oldQAOpt.caresp__Answer_Text__c)) {
                            quesIdSet.add(oldQAOpt.caresp__Question__c);
                        }
                    }
                }
            }

            if (!quesIdSet.isEmpty()) {
                // Fixed object and field names with namespace (Critical fix)
                for (caresp__Question_Answer_Option__c qaOpt : [
                    SELECT caresp__Question__c, caresp__Answer_Text__c 
                    FROM caresp__Question_Answer_Option__c 
                    WHERE caresp__Question__c IN :quesIdSet 
                    WITH USER_MODE 
                    ORDER BY caresp__Sequence__c
                    LIMIT 10000
                ]) {
                    if (qaOpt.caresp__Question__c != null && String.isNotEmpty(qaOpt.caresp__Answer_Text__c)) {
                        if (!questIdAndAnsOptsMap.containsKey(qaOpt.caresp__Question__c)) {
                            questIdAndAnsOptsMap.put(qaOpt.caresp__Question__c, qaOpt.caresp__Answer_Text__c);
                        } else {
                            questIdAndAnsOptsMap.put(qaOpt.caresp__Question__c, 
                                questIdAndAnsOptsMap.get(qaOpt.caresp__Question__c) + '|' + qaOpt.caresp__Answer_Text__c);
                        }
                    }
                }

                // Fixed object and field names with namespace (Critical fix)
                for (caresp__Question__c ques : [
                    SELECT Id, caresp__Answer_Options__c 
                    FROM caresp__Question__c 
                    WHERE Id IN :quesIdSet 
                    WITH USER_MODE
                    LIMIT 10000
                ]) {
                    if (ques != null) {
                        String answerOptions = questIdAndAnsOptsMap.containsKey(ques.Id) ? 
                            questIdAndAnsOptsMap.get(ques.Id) : '';
                        
                        questListToBeUpdated.add(
                            new caresp__Question__c(
                                Id = ques.Id,
                                caresp__Answer_Options__c = answerOptions
                            )
                        );
                    }
                }

                // Consistent security model (High fix)
                if (!questListToBeUpdated.isEmpty()) {
                    if (Schema.sObjectType.caresp__Question__c.isUpdateable()) {
                        Database.update(
                            Security.stripInaccessible(AccessType.UPDATABLE, questListToBeUpdated).getRecords(),
                            AccessLevel.USER_MODE
                        );
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in doRoll: ' + e.getMessage());
            throw new System.DmlException('Failed to update question answer options: ' + e.getMessage());
        }
    }

    // Sets the Question_Text__c field on Question_Answer_Option__c during before insert.
    public static void doUpdateQuestionText(List<caresp__Question_Answer_Option__c> newTrigger, Boolean isInsert, Boolean isBefore) {
        // Input validation (High fix)
        if (newTrigger == null || newTrigger.isEmpty()) {
            return;
        }
        
        if (isInsert && isBefore) {
            try {
                // Use proper Id type to prevent SOQL injection (Critical fix)
                List<Id> quesIdList = new List<Id>();
                for (caresp__Question_Answer_Option__c ansOp : newTrigger) {
                    // Null safety check (High fix)
                    if (ansOp != null && ansOp.caresp__Question__c != null) {
                        quesIdList.add(ansOp.caresp__Question__c);
                    }
                }

                // Early return if no valid question IDs found
                if (quesIdList.isEmpty()) {
                    return;
                }

                // Fixed object and field names with namespace (Critical fix)
                Map<Id, caresp__Question__c> quesMap = new Map<Id, caresp__Question__c>(
                    [SELECT Id, caresp__Question_Text__c 
                    FROM caresp__Question__c 
                    WHERE Id IN :quesIdList 
                    WITH USER_MODE
                    LIMIT 10000]
                );

                // Update question text with proper null safety (High fix)
                for (caresp__Question_Answer_Option__c ansOp : newTrigger) {
                    if (ansOp != null && ansOp.caresp__Question__c != null) {
                        caresp__Question__c relatedQuestion = quesMap.get(ansOp.caresp__Question__c);
                        if (relatedQuestion != null) {
                            ansOp.caresp__Question_Text__c = relatedQuestion.caresp__Question_Text__c;
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error in doUpdateQuestionText: ' + e.getMessage());
                throw new System.DmlException('Failed to update question text: ' + e.getMessage());
            }
        }
    }
}