@isTest
public class CustomLookupLwcControllerTest {
    @isTest
    static void testFetchLookupData() {
        Question_Bank__c testQuesBank = TestFactory.createQuestionBank('Test Question Bank', '', true);
        Question__c testQuestion = TestFactory.createQuestion(testQuesBank.Id, '', 'Text', false);
        testQuestion.Question_Text__c='Test';
        insert testQuestion;
        List<Question__c> result = CustomLookupLwcController.fetchLookupData('Test', 'Question__c', 'Question_Text__c');
        System.assertEquals(1, result.size());
        System.assertEquals(testQuestion.Id, result[0].Id);
    }

    @isTest
    static void testFetchDefaultRecord() {
        Question_Bank__c testQuesBank = TestFactory.createQuestionBank('Test Question Bank', '', true);
        Question__c testQuestion = TestFactory.createQuestion(testQuesBank.Id, '', 'Text', false);
        testQuestion.Question_Text__c='Test';
        insert testQuestion;
        Question__c result = (Question__c) CustomLookupLwcController.fetchDefaultRecord(testQuestion.Id, 'Question__c', 'Question_Text__c');
        System.assertNotEquals(null, result);
        System.assertEquals(testQuestion.Id, result.Id);
    }
}