/**
 * Test class for QuestionsController.
 * It verifies functionality for retrieving, deleting questions, and their associated answer options.
 */
@isTest
public with sharing class QuestionsControllerTest {
    
    // Creates test data for Question_Bank, Question, Answer, and Question_Answer_Option
    @testSetup static void setupMaster(){
        Question_Bank__c qbTestData = testFactory.createQuestionBank('Test Question', null, true);
        Question__c quesTestData = testFactory.createQuestion(qbTestData.Id, null, 'Radio Box', false);
        quesTestData.Question_Text__c = 'Test Question';
        quesTestData.Answer_Options__c = 'AnsOption1|AnsOption2';
        quesTestData.Active__c = true;
        insert quesTestData;

        Answer__c ansTestData = testFactory.createAnswer(null, 'Test Answer', true, true);
        Question_Answer_Option__c qaoTestData = testFactory.createQuestionAnswerOption(ansTestData.Id, quesTestData.Id, null, null, true);
    }

    // Tests retrieval of all questions and their answer options, and deletes a question
    static testMethod void testGetAllQuestions() {
        List<Question__c> quesList = QuestionsController.getAllQuestions(true);
        Integer quesCount = quesList.size();
        System.assertEquals(quesCount, 1);

        Question__c ques = [SELECT Id, Name FROM Question__c LIMIT 1];
        List<Question_Answer_Option__c> qaoList = QuestionsController.getAnswerOptions(ques.Id);
        Integer qaoCount = qaoList.size();
        System.assertEquals(qaoCount, 1);

        QuestionsController.deleteQuestion(ques.Id);
    }
}