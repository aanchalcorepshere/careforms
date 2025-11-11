@isTest 
public class CreateNewQuestionCtrlTest {
    @testSetup static void setUpData() 
    { 
        Question_Bank__c questionBank1 = testFactory.createQuestionBank('Demo question', null, true);
        
        Question__c ques1 = testFactory.createQuestion(questionBank1.Id, null, 'Text', true);
        ques1.Question_Text__c = 'Demo question';
        Answer__c ans = testFactory.createAnswer(null, 'Demo answer text', true, true);
        Question_Answer_Option__c quesAnsOpt1 = testFactory.createQuestionAnswerOption(ans.Id, ques1.Id, null, 'demo', true);
    }
    static testmethod void testCheckDuplicateAndEditable(){
        Question__c ques = [SELECT Id,Question_Bank__c, Question_Text__c, Question_Data_type__c FROM Question__c limit 1];
        Answer__c ans = [SELECT Id FROM Answer__c limit 1];
        
        List<String> ansList = new List<String>();
        ansList.add(ans.Id);
        
        String resp = CreateNewQuestionCtrl.checkDuplicate(ques.Question_Bank__c, ques.Question_Data_type__c, ansList);
        system.debug('###' +resp);
        //CreateNewQuestionCtrl.checkDuplicate(ques.Question_Text__c, ques.Question_Data_type__c, null);
        system.assertEquals('Duplicate', resp);
        
   
    }
    
    static testmethod void testCreateQuestion(){
        Question_Bank__c questionBank = [SELECT Id FROM Question_Bank__c limit 1];
        Question__c ques = testFactory.createQuestion(questionBank.Id, null, 'Text', false);
        //ques.Question_Text__c = 'Test Question 2';
       // CreateNewQuestionCtrl.checkDuplicate(questionBank.Id, ques.Question_Data_type__c, null);

        String quesId = CreateNewQuestionCtrl.createQuestion(ques);
        System.assertNotEquals(quesId, null, 'Question ID should not be null');
      //System.assertEquals(ques.Id, quesId);
    }
    
    static testmethod void testUpdateQuestion(){
        Question__c ques = [SELECT Id, Question_Data_type__c FROM Question__c limit 1];
        String quesId = CreateNewQuestionCtrl.updateQuestion(ques);
        system.assertEquals(ques.Id, quesId);
    }
    
    static testmethod void testCreateAnsOptions(){
        Question_Bank__c questionBank1 = testFactory.createQuestionBank('Demo question12', null, true);
        Question__c ques1 = testFactory.createQuestion(questionBank1.Id, null, 'Text', true);
        
        Question_Bank__c questionBank2 = testFactory.createQuestionBank('Demo question1212', null, true);
        Question__c ques2 = testFactory.createQuestion(questionBank2.Id, null, 'Text', true);
        Answer__c ans = [SELECT Id FROM Answer__c limit 1];
        
        Question_Answer_Option__c quesAnsOpt1 = testFactory.createQuestionAnswerOption(ans.Id, ques1.Id, null, 'demo1234', false);
        Question_Answer_Option__c quesAnsOpt2 = testFactory.createQuestionAnswerOption(ans.Id, ques2.Id, null, 'demo1234', false);
        
        List<Question_Answer_Option__c> quesAnsOptList = new List<Question_Answer_Option__c>();
        quesAnsOptList.add(quesAnsOpt1);
        quesAnsOptList.add(quesAnsOpt2);
        system.debug(quesAnsOptList[0].question__c);
        system.debug(quesAnsOptList[1].question__c);
        system.debug(quesAnsOptList);
        CreateNewQuestionCtrl.createAnsOptions(quesAnsOptList, true);   
        system.assertEquals('demo1234', quesAnsOptList[0].Question_Text__c);
    }
    
    static testmethod void testGetQuestionData(){
        Question__c ques = [SELECT Id, Question_Data_type__c FROM Question__c limit 1];
        CreateNewQuestionCtrl.getQuestionData(ques.Id);
        CreateNewQuestionCtrl.checkEditable(ques.Id);
        system.assertEquals('Text', CreateNewQuestionCtrl.getQuestionData(ques.Id).quesDataType);
    }
}