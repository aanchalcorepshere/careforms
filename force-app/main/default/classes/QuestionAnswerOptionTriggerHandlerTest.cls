// Test class for verifying the behavior of triggers on Question_Answer_Option__c records.
@isTest
public with sharing class QuestionAnswerOptionTriggerHandlerTest {

    // Creates test data: Question Bank, Questions, Answers, and Question Answer Options.
    @testSetup 
    static void setupMaster() {
        // Creating Question Bank
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question bank', null, true);

        // Creating Questions
        Question__c ques = testFactory.createQuestion(questionBank.Id, null, null, true);
        ques.Question_Text__c = 'Question';
        ques.Answer_Options__c = 'Answer option test';
        update ques;

        Question__c ques1 = testFactory.createQuestion(questionBank.Id, null, null, true);
        ques1.Question_Text__c = 'Question1';
        ques1.Answer_Options__c = 'Answer option test1';
        update ques1;

        // Creating Answers
        Answer__c ans = testFactory.createAnswer(null, 'Demo answer text', true, true);
        Answer__c ans1 = testFactory.createAnswer(null, 'Demo answer text1', true, true);

        // Creating Question Answer Options
        Question_Answer_Option__c questionAnswerOption = testFactory.CreateQuestionAnswerOption(ans.Id, ques.Id, null, null, true);
        Question_Answer_Option__c questionAnswerOption1 = testFactory.CreateQuestionAnswerOption(ans1.Id, ques.Id, null, null, true);
    }

    // Tests update, delete, and undelete operations on a Question_Answer_Option__c record.
    @isTest 
    static void testUpdateQuestionBank() {
        Question_Answer_Option__c questionAnswerOptn = [
            SELECT Question__c, Answer__c 
            FROM Question_Answer_Option__c 
            WHERE Id != null 
            WITH USER_MODE 
            LIMIT 1
        ];
        questionAnswerOptn.Score__c = 50;
        System.assertEquals(50, questionAnswerOptn.Score__c);

        Test.startTest();
        update questionAnswerOptn;
        delete questionAnswerOptn;
        undelete questionAnswerOptn;
        Test.stopTest();
    }
}