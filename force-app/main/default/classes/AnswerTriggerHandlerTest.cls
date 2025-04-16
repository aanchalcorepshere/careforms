@isTest
public with sharing class AnswerTriggerHandlerTest {
    @isTest static void testcheckAnswerInUse(){
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'sysadmin',
            Email = 'sysadmin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'sysadmin.' + DateTime.now().getTime() + '@example.com'
        );
        insert adminUser;
        
        
        List<String> permSetNames = new List<String>{
            'Assessment_Module_Admin',
                'Forms_Module_Admin',
                'Plans_Module_Admin'
                };
                    
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        for (PermissionSet ps : [
            SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames
        ]) {
            psaList.add(new PermissionSetAssignment(
                AssigneeId = adminUser.Id,
                PermissionSetId = ps.Id
            ));
        }
        
        if (!psaList.isEmpty()) {
            insert psaList;
            System.debug('Permission sets assigned successfully');
        } else {
            System.debug('No matching permission sets found');
        }
        System.runAs(adminUser) {
            caresp__Question_Bank__c questionBank = testFactory.createQuestionBank('Demo question', null, true);
            caresp__Question__c ques = testFactory.createQuestion(questionBank.Id, null, null, true);
            caresp__Answer__c ans1 = testFactory.createAnswer(null, 'Demo answer text234', true, true);
            caresp__Answer__c ans2 = testFactory.createAnswer(null, 'Demo answer text', false, true);
            caresp__Question_Answer_Option__c quesAnsOpt = testFactory.createQuestionAnswerOption(ans1.Id, ques.Id, null, 'demo',true); 
            List<Answer__c> ansList = new List<Answer__c>();
            ansList.add(ans1);
            ansList.add(ans2);
            try
            {   
                ans1.caresp__Answer_Text__c = 'Demo answer';
                ans2.caresp__Answer_Text__c = 'Demo answer123';
                update ansList;
            }
            catch(Exception e)
            {
                System.Assert(e.getMessage().contains('This Answer cannot be edited.'));
            } 
            
            try
            {  
                delete ans1;
            }
            catch(Exception e)
            {
                System.Assert(e.getMessage().contains('This Answer cannot be deleted.'));
            } 
            
            try
            {
                ans1.caresp__Answer_Text__c = 'Demo answer text234';
                ans1.caresp__Active__c = false;
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
}