@isTest
public class QuestionBankTriggerHandlerTest {
    @testSetup static void setUpData() {
        // Create Question Bank
        Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question bank', null, true);
        Question_Bank__c questionBank1 = testFactory.createQuestionBank('Demo question bank1', null, false);
        questionBank1.Active__c = false;
        insert questionBank1;
        //Create Question
        Question__c ques = testFactory.createQuestion(questionBank.Id, null, null,true);
    }
    
	@isTest public static void testExistingQuestionBank() 
    {
        Question_Bank__c questionBank = [Select id, Question_Text__c from Question_Bank__c limit 1];
        system.debug(questionBank);
        
         try{
            questionBank.Question_Text__c = 'Demo question bank1';
            update questionBank;
            system.assertEquals('Demo question bank1', questionBank.Question_Text__c);
        }
        catch(Exception e)
        {
            System.debug('This Question already exists');
            System.Assert(e.getMessage().contains('This Question already exists'));
        } 
        
    }    
	@isTest public static void testQuestionInUse()
    {
        Question_Bank__c questionBank = [Select id, Question_Text__c from Question_Bank__c limit 1];
        system.debug(questionBank);
        
        try{
            
            questionBank.Question_Text__c = 'Demo question bank';
            update questionBank;
            system.debug(questionBank);
            
        }
        catch(Exception e)
        {
            system.debug(e.getMessage());
            System.Assert(e.getMessage().contains('This Question cannot be edited'));
            
        }
            
    }
    
    @isTest public static void testQuestionInUseDelete(){
        try{
                 Question_Bank__c questionBank1 = [Select id, Question_Text__c from Question_Bank__c limit 1];
				 Delete questionBank1;
            }
           catch(Exception e)
           {
               system.assert(e.getMessage().contains('This Question cannot be deleted'));
           }
    }
    @isTest public static void testToUpdateQuestionBank()
    {
       Question_Bank__c questionBankTest = [Select id, Question_Text__c, Active__c from Question_Bank__c limit 1];
        
        try{
            
                questionBankTest.Active__c = false;
        		system.debug(questionBankTest);
            	update questionBankTest;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage());
            System.Assert(e.getMessage().contains('This Question cannot be de-activated'));
            
        }

    }
    
    @isTest public static void testDeleteUndelete()
    {
        Question_Bank__c questionBankTest = [Select id, Question_Text__c,Active__c,IsDeleted from Question_Bank__c where Active__c = false];
        delete questionBankTest;
        Question_Bank__c deletedRecord = [SELECT Id,IsDeleted FROM Question_Bank__c WHERE Id = :questionBankTest.Id ALL ROWS];
        System.assertEquals(true, deletedRecord.IsDeleted, 'Record was not soft-deleted.');
        Undelete questionBankTest;
        Question_Bank__c undeletedRecord = [SELECT Id, Active__c,IsDeleted FROM Question_Bank__c WHERE Id = :questionBankTest.Id];
        System.assertEquals(false, undeletedRecord.IsDeleted, 'Record was not undeleted.');
    }
}