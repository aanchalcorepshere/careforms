@isTest
public with sharing class AssessmentWizardControllerTest {
    
    @testSetup static void setupMaster(){
        Assessment__c assessmentTestData=TestFactory.createAssessment(null, 'Test Assessment',true);
        List<Question__c> quesList = new List<Question__c>();
        Question__c ques1=TestFactory.createQuestion(null,null,'Radio Box',false);
        Question__c ques2=TestFactory.createQuestion(null,null,'Picklist',false);
        Question__c ques3=TestFactory.createQuestion(null,null,'Text',false);
        ques1.Question_Text__c='Poor appetite or overeating?';
        ques2.Question_Text__c='Feeling tired or having little';
        ques3.Question_Text__c='What is your occupation?';
        quesList.add(ques1);
        quesList.add(ques2);
        quesList.add(ques3);
        insert quesList;
        List<Answer__c> ansList = new List<Answer__c>();
        Answer__c ans1=TestFactory.createAnswer(null,'Not at all',true,false);
        Answer__c ans2=TestFactory.createAnswer(null,'Several Days',true,false);
        Answer__c ans3=TestFactory.createAnswer(null,'More than half the days',true,false);
        Answer__c ans4=TestFactory.createAnswer(null,'Nearly every day',true,false);
        ansList.add(ans1);
        ansList.add(ans2);
        ansList.add(ans3);
        ansList.add(ans4);
        insert ansList;
        List<Question_Answer_Option__c> qaoList = new List<Question_Answer_Option__c>();
        Question_Answer_Option__c qao1=TestFactory.createQuestionAnswerOption(ans1.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao2=TestFactory.createQuestionAnswerOption(ans2.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao3=TestFactory.createQuestionAnswerOption(ans3.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao4=TestFactory.createQuestionAnswerOption(ans4.Id,ques1.Id,null,'Poor appetite or overeating?',false);
        Question_Answer_Option__c qao5=TestFactory.createQuestionAnswerOption(ans1.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao6=TestFactory.createQuestionAnswerOption(ans2.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao7=TestFactory.createQuestionAnswerOption(ans3.Id,ques2.Id,null,'Feeling tired or having little',false);
        Question_Answer_Option__c qao8=TestFactory.createQuestionAnswerOption(ans4.Id,ques2.Id,null,'Feeling tired or having little',false);
        qaoList.add(qao1);
        qaoList.add(qao2);
        qaoList.add(qao3);
        qaoList.add(qao4);
        qaoList.add(qao5);
        qaoList.add(qao6);
        qaoList.add(qao7);
        qaoList.add(qao8);
        insert qaoList;
        List<Assessment_Question__c> aqList = new List<Assessment_Question__c>();
        Assessment_Question__c assessQues1=TestFactory.createAssessmentQuestion(null, ques1.Id, assessmentTestData.Id, 'Client_Service__c|test_field__c', true, 1, 1, 'General', 'Default Section', false);
		assessQues1.Score__c = qao1.Id+'|10;'+qao2.Id+'|20;'+qao3.Id+'|30;'+qao4.Id+'|40';
        aqList.add(assessQues1);
        Assessment_Question__c assessQues2=TestFactory.createAssessmentQuestion(null, ques2.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues2.Dependent_Sequence__c = 'A';
        assessQues2.Score__c = qao5.Id+'|10;'+qao6.Id+'|20;'+qao7.Id+'|30;'+qao8.Id+'|40';
        aqList.add(assessQues2);
        Assessment_Question__c assessQues3=TestFactory.createAssessmentQuestion(null, ques3.Id, assessmentTestData.Id, null, true, null, null, 'Dependent', null, false);
        assessQues3.Dependent_Sequence__c = 'i';
        aqList.add(assessQues3);
        insert aqList;
        List<Dependent_Question__c> depQuesList = new List<Dependent_Question__c>();
        Dependent_Question__c depQues1=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues2.Id, assessQues1.Id, qao1.Id,null,false);
        depQuesList.add(depQues1);
        Dependent_Question__c depQues2=TestFactory.createDependentQuestion(assessmentTestData.Id, assessQues3.Id, assessQues2.Id, qao5.Id,null,false);
        depQuesList.add(depQues2);
        insert depQuesList;
        Outcome__c outcomeASTestData=TestFactory.createOutcome(null, 'Test Outcome Assigned Service',assessmentTestData.Id,false);
        outcomeASTestData.Status__c='Draft';
        outcomeASTestData.Assessment_Date__c=system.today();
        insert outcomeASTestData;
        Scoring__c score = testFactory.createScoring( null, assessmentTestData.Id, 0, 50, 'Green', 'Green Status' , true );
    }

    static testMethod void testCheckAssessmentWizardMethods()
    {
        List<Assessment__c> assessmentList =[select id from Assessment__c limit 1];
        List<Question__c> quesList = [select Id, Question_Text__c, Question_Data_Type__c from Question__c];
        System.debug('quesList >> '+quesList);
        List<Answer__c> ansList = [select Id, Answer_Text__c from Answer__c];
        List<Question_Answer_Option__c> qaoList = [select Id, Question_Text__c from Question_Answer_Option__c];
        Assessment__c assessmentRec = [select Id from Assessment__c];
        List<String> objList =new List<String>{'Assessment__c','Outcome__c'};
		String assessment = AssessmentWizardController.createAssessmentRecord('Test Class Assessment', '', true,null,null);
        System.assertNotEquals(assessment, null, 'Assessment ID should not be null');
        AssessmentWizardController.checkAssessmentNameDuplicate('Another test Name', assessmentRec.Id);
        String checkDuplicate = AssessmentWizardController.checkAssessmentNameDuplicate('Test Assessment', '');
        System.assertEquals(checkDuplicate, 'Duplicate', 'Duplicate assessment check should return "Duplicate Assessment"');
        AssessmentWizardController.checkAssessmentInUse(assessmentRec.Id);
        AssessmentWizardController.getObjectNames();
        //AssessmentWizardController.getCompatibleFields('Referral__c', 'Referral_Status__c');
        AssessmentWizardController.getCompatibleFieldsBoolPick(new List<String>{'caresp__Assessment__c'});
        AssessmentWizardController.getFieldTypeAndValues('Contact|LeadSource');
        AssessmentWizardController.getQuestionsForSelection(true);
        String jsonStr = '[{"level":"level1","parent":"none","grandparent":"none","quesId":"'+quesList[0].Id+'","quesText":"Poor appetite or overeating?", "dataType":"Radio Box","quesAnsOptions":"Not at all|Several Days|More than half the days|Nearly every day","sequence":1,"sfSeq":1,"score":[],"section":"Default Section","sectionSequence":"1","unique":"Default Section_level1_'+quesList[0].Id+'_1","dependentAllowed":true,"dependentQuesData":[{"ansOpId":"'+qaoList[0].Id+'","ansOpText":"Not at all","dependentQuesList":[{"level":"level2","parent":"'+quesList[0].Id+'","sequence":1,"sfSeq":"A","dependentAllowed":true,"ansOpId":"'+qaoList[0].Id+'","quesId":"'+quesList[1].Id+'","quesText":"Feeling tired or having little","dataType":"Picklist","quesAnsOptions":"Not at all|Several Days|More than half the days|Nearly every day","unique":"Default Section_level2_'+quesList[1].Id+'_A","dependentQuesData":[{"ansOpText":"Not at all","ansOpId":"'+qaoList[4].Id+'","dependentQuesList":[{"level":"level3","parent":"'+quesList[1].Id+'","grandparent":"'+quesList[0].Id+'","sequence":1,"sfSeq":"i","dependentAllowed":true,"ansOpId":"'+qaoList[4].Id+'","grandParentAnsOpId":"'+qaoList[0].Id+'","quesId":"'+quesList[2].Id+'","quesText":"What is your occupation?","dataType":"Text","quesAnsOptions":null,"unique":"Default Section_level3_'+quesList[2].Id+'_i","aqId":""}]},{"ansOpText":"Several Days","ansOpId":"'+qaoList[5].Id+'","dependentQuesList":[]},{"ansOpText":"More than half the days","ansOpId":"'+qaoList[6].Id+'","dependentQuesList":[]},{"ansOpText":"Nearly every day","ansOpId":"'+qaoList[7].Id+'","dependentQuesList":[]}],"aqId":""}],"score":"10"},{"ansOpId":"'+qaoList[1].Id+'","ansOpText":"Several Days","dependentQuesList":[],"score":"20"},{"ansOpId":"'+qaoList[2].Id+'","ansOpText":"More than half the days","dependentQuesList":[],"score":"30"},{"ansOpId":"'+qaoList[3].Id+'","ansOpText":"Nearly every day","dependentQuesList":[],"score":"40"}],"maxScore":40,"objectname":"Client_Service__c","fieldlist":[{"value":"notes__c","label":"Notes(Client_Service__c)"},{"value":"other_info__c","label":"Other Info(Client_Service__c)"},{"value":"test_field__c","label":"Test Field(Client_Service__c)"}],"fieldname":"test_field__c","scorelist":"'+qaoList[0].Id+'|10;'+qaoList[1].Id+'|20;'+qaoList[2].Id+'|30;'+qaoList[3].Id+'|40","aqId":""}]';
        System.debug('jsonStr >> '+jsonStr);
        System.debug('assessment >> '+assessment);
        AssessmentWizardController.saveQuestions(assessmentRec.Id, jsonStr, '', new List<String>());
        AssessmentWizardController.updateJsonData(assessmentList);
        AssessmentWizardController.updateCompletionFieldData(assessmentRec.Id,'','');
        AssessmentWizardController.getCompatibleFields('caresp__Assessment__c');
       
    }
}