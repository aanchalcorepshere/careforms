// Test class for AnswerSelectionController to verify active answer retrieval logic
@isTest
public with sharing class AnswerSelectionControllerTest {

    // Setup method to insert test Answer__c records
    @testSetup 
    static void setupMaster() {
        Answer__c ansTestData = testFactory.createAnswer(null, 'Test Answer', true, true);
        Answer__c ansTestData2 = testFactory.createAnswer(null, 'Test Answer2', true, true);
    }

    // Test method to validate getActiveAnswers behavior with and without search term
    static testMethod void testGetActiveAnswers() {
        List<Answer__c> ansList = new List<Answer__c>();
        
        // Search term as null
        ansList = AnswerSelectionController.getActiveAnswers(null);
        Integer listSize = ansList.size();
        System.assertEquals(listSize, 2);

        // Providing specific search term
        ansList = AnswerSelectionController.getActiveAnswers('Test Answer2');
        listSize = ansList.size();
        System.assertEquals(listSize, 1);
    }

    static testMethod void testGetActiveAnswersNull() {
        List<Answer__c> ansList = new List<Answer__c>();
        
        // Search term as null
        ansList = AnswerSelectionController.getActiveAnswers('T');
        Integer listSize = ansList.size();
    }
}