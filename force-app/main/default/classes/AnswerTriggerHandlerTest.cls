@isTest
public with sharing class AnswerTriggerHandlerTest {
    @isTest static void testcheckAnswerInUse(){
        
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question', null, true);
        Question__c ques = testFactory.createQuestion(questionBank.Id, null, null, true);
        Answer__c ans1 = testFactory.createAnswer(null, 'Demo answer text234', true, true);
        Answer__c ans2 = testFactory.createAnswer(null, 'Demo answer text', false, true);
        Question_Answer_Option__c quesAnsOpt = testFactory.createQuestionAnswerOption(ans1.Id, ques.Id, null, 'demo',true); 
        List<Answer__c> ansList = new List<Answer__c>();
        ansList.add(ans1);
        ansList.add(ans2);
        
        try{   
            ans1.Answer_Text__c = 'Demo answer';
            ans2.Answer_Text__c = 'Demo answer123';
            update ansList;
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('This Answer cannot be edited.'));
        } 
        
        try{  
            
             delete ans1;
        }
        catch(Exception e)
        {
            System.Assert(e.getMessage().contains('This Answer cannot be deleted.'));
        } 
        
        try{
            ans1.Answer_Text__c = 'Demo answer text234';
            ans1.Active__c = false;
            update ans1;
        }
        catch(Exception e)
        {
            system.debug(e);
            System.Assert(e.getMessage().contains('This Answer cannot be de-activated.'));
        } 
        

        
       		delete ans2;
	        undelete ans2; 
        
    }
}