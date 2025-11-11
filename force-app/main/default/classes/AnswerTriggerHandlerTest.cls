// Test class for AnswerTriggerHandler to validate trigger logic for update and delete restrictions
@isTest
public with sharing class AnswerTriggerHandlerTest {

    // Tests the checkAnswerInUse method for edit, delete, and deactivate constraints
    @isTest 
    static void testcheckAnswerInUse() {
        User testUser = testFactory.getTestClassUser();

        System.runAs(testUser) {
            // Create necessary test data
            caresp__Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question', null, true);
            caresp__Question__c ques = testFactory.createQuestion(questionBank.Id, null, null, true);
            caresp__Answer__c ans1 = testFactory.createAnswer(null, 'Demo answer text234', true, true);
            caresp__Answer__c ans2 = testFactory.createAnswer(null, 'Demo answer text', false, true);
            caresp__Question_Answer_Option__c quesAnsOpt = testFactory.createQuestionAnswerOption(ans1.Id, ques.Id, null, 'demo', true);

            List<Answer__c> ansList = new List<Answer__c>{ans1, ans2};

            // Try editing answer text - should throw "cannot be edited" error
            try {
                ans1.caresp__Answer_Text__c = 'Demo answer';
                ans2.caresp__Answer_Text__c = 'Demo answer123';
                update ansList;
            } catch(Exception e) {
                System.assert(e.getMessage().contains('This Answer cannot be edited.'));
            } 

            // Try deleting answer linked to Question_Answer_Option__c - should throw "cannot be deleted" error
            try {
                delete ans1;
            } catch(Exception e) {
                System.assert(e.getMessage().contains('This Answer cannot be deleted.'));
            } 

            // Try deactivating answer - should throw "cannot be de-activated" error
            try {
                ans1.caresp__Answer_Text__c = 'Demo answer text234'; // revert back to original text
                ans1.caresp__Active__c = false;
                update ans1;
            } catch(Exception e) {
                System.debug(e);
                System.assert(e.getMessage().contains('This Answer cannot be de-activated.'));
            }

            // Try delete + undelete on unrelated answer - should succeed
            delete ans2;
            undelete ans2;
        }
    }     
}