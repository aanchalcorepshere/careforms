/* Test_Factory Class to Insert Records to be used in Test Classes */
@isTest
public with sharing class testFactory{
    public static Id getDefaultRT(Schema.DescribeSObjectResult dsr){
        Id rtID;
        for (Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()){
            if (rti.isDefaultRecordTypeMapping()){
                rtId = rti.getRecordTypeId();
            }
        }
        return rtId;
    }

        //Create Question Bank
    public static Question_Bank__c createQuestionBank(String questionText, String rtName, Boolean create ){
        Id qusBankRTId;
        if (rtName != null && rtName != '')
        {
            qusBankRTId = Schema.SObjectType.Question_Bank__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            qusBankRTId = testFactory.getDefaultRT(Question_Bank__c.SObjectType.getDescribe());
        }
        Question_Bank__c questionBank = new Question_Bank__c();
        questionBank.Question_Text__c = questionText;
        //questionBank.RecordTypeId     = qusBankRTId;
        
        if (create) insert questionBank;
        return questionBank;
    }
    //Create Question
    public static Question__c createQuestion(String questionBankId, String rtName, String questionDtype, Boolean create){
        Id qusRTId;
        if (rtName != null && rtName != ''){
            qusRTId = Schema.SObjectType.Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            qusRTId = testFactory.getDefaultRT(Question__c.SObjectType.getDescribe());
        }
        Question__c question = new Question__c();
        question.Question_Data_type__c = questionDtype;
        if (questionBankId != null && questionBankId != ''){
            question.Question_Bank__c = questionBankId;
        }
        //question.RecordTypeId     = qusRTId;

        if (create)
            insert question;
        return question;
    }

    //create Answer
    public static Answer__c createAnswer(string rtName, String ansText, Boolean isActive, Boolean create){
        Id ansRTId;
        if (rtName != null && rtName != ''){
            ansRTId = Schema.SObjectType.Answer__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            ansRTId = testFactory.getDefaultRT(Answer__c.SObjectType.getDescribe());
        }

        Answer__c ans = new Answer__c();
        //ans.RecordTypeId = ansRTId;
        ans.Answer_Text__c = ansText;
        ans.Active__c = isActive;

        if (create)
            insert ans;
        return ans;
    }

    // Create Question Answer Option
    public static Question_Answer_Option__c createQuestionAnswerOption(String answerId, String questionId, String rtName, String questionText, Boolean create){
        Id qusAnsOpRTId;
        if (rtName != null && rtName != ''){
            qusAnsOpRTId = Schema.SObjectType.Question_Answer_Option__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            qusAnsOpRTId = testFactory.getDefaultRT(Question_Answer_Option__c.SObjectType.getDescribe());
        }
        Question_Answer_Option__c questionAnswerOptn = new Question_Answer_Option__c();
        questionAnswerOptn.Answer__c = answerId;
        questionAnswerOptn.Question__c = questionId;
        questionAnswerOptn.Question_Text__c = questionText;
        

        if (create)
            insert questionAnswerOptn;
        return questionAnswerOptn;
    }

    //Create Response
  /*  public static Response__c createResponse(String rtName, Boolean create){
        Id respRTId;
        if (rtName != null && rtName != ''){
            respRTId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        } else{
            respRTId = testFactory.getDefaultRT(Response__c.SObjectType.getDescribe());
        }
        Response__c response = new Response__c();
        //response.RecordTypeId = respRTId;
        if (create)
            insert response;
        return response;
    }*/
 public static Response__c createResponse( String rtName, String assessmentId, String outcomeId, Boolean create ){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = TestFactory.getDefaultRT(Response__c.SObjectType.getDescribe());
        }
        Response__c response    = new Response__c();
        if(assessmentId !=null && assessmentId != '')
        {
        response.Assessment__c     = assessmentId;
        }
        if(outcomeId != null && outcomeId != '')
        {
            response.Outcome__c = outcomeId;
        }
        //response.RecordTypeId = respRTId;
        if (create) insert response;
        return response;
    }
	//create Assessment
    public static Assessment__c createAssessment(String rtName, String name, Boolean create){
        Id assessRTId;
        if (rtName != null && rtName != '')
        {
            assessRTId = Schema.SObjectType.Assessment__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessRTId = TestFactory.getDefaultRT(Assessment__c.SObjectType.getDescribe());
        }
        
        Assessment__c assessment = new Assessment__c();
        //assessment.RecordTypeId = assessRTId;
        assessment.name = name;
        
        if (create) insert assessment;
        return assessment;
    }

	//create Outcome
    public static Outcome__c createOutcome(String rtName, String name, Id assessId, Boolean create){
        Id outRTId;
        if (rtName != null && rtName != '')
        {
            outRTId = Schema.SObjectType.Outcome__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            outRTId = TestFactory.getDefaultRT(Outcome__c.SObjectType.getDescribe());
        }
        
        Outcome__c outcome = new Outcome__c();
        //outcome.RecordTypeId = outRTId;
        outcome.name = name;
        outcome.Assessment__c = assessId;
        
        if (create) insert outcome;
        return outcome;
    }

	//Create Account
    public static Account createAccount (String name, String rtName, Boolean create)
    {
        Id accRTId;
        if (rtName != null && rtName != '')
        {
            accRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            accRTId = TestFactory.getDefaultRT(Account.SObjectType.getDescribe());
        }
        Account acc = new Account();
        acc.Name = name;
        if (create) insert acc;
        return acc; 
    }
    
    //Create Contact
    public static Contact createContact (String lastName, string title, String rtName, ID accountId, Boolean create)
    {
        Id conRTId;
        if (rtName != null && rtName != '')
        {
            conRTId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            conRTId = TestFactory.getDefaultRT(Contact.SObjectType.getDescribe());
        }
        Contact con = new Contact();
        con.LastName = lastName;
        con.Title=title;
        con.Email='test@test.com';
        con.Phone='1234567890';
        con.AccountId = accountId;
        //con.RecordTypeId = conRTId;
        if (create) insert con;
        return con;
    }

	//create Assessment Question
    public static Assessment_Question__c createAssessmentQuestion(String rtName, Id questionId, Id assessmentId, String fieldUpdate, Boolean required, Integer sequence, Integer secSequence, String type, String section, Boolean create){
        Id assessQuesRTId;
        if (rtName != null && rtName != '')
        {
            assessQuesRTId = Schema.SObjectType.Assessment_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            assessQuesRTId = TestFactory.getDefaultRT(Assessment_Question__c.SObjectType.getDescribe());
        }
        
        Assessment_Question__c assessmentQues = new Assessment_Question__c();
        //assessmentQues.RecordTypeId = assessQuesRTId;
        assessmentQues.Assessment__c = assessmentId;
        assessmentQues.Question__c = questionId;
        assessmentQues.sequence__c = sequence; 
        assessmentQues.Section_Sequence__c = secSequence;
        assessmentQues.Required__c = required;
        assessmentQues.Type__c = type;
        assessmentQues.Field_Update__c = fieldUpdate;
        assessmentQues.Section__c = section;
        
        if (create) insert assessmentQues;
        return assessmentQues;
    }

    //Create Dependent Question
    public static Dependent_Question__c createDependentQuestion(String assessId, String dependentAssessmentQuesId, String parentAssessmentQuesId, String questionAnsOptId,String rtName,Boolean create ){
        Id dqRTId;
        if (rtName != null && rtName != '')
        {
            dqRTId = Schema.SObjectType.Dependent_Question__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            dqRTId = TestFactory.getDefaultRT(Dependent_Question__c.SObjectType.getDescribe());
        }
        Dependent_Question__c depQues = new Dependent_Question__c();
        depQues.Assessment__c=assessId;
        depQues.Dependent_Question__c=dependentAssessmentQuesId;
        depQues.Parent_Question__c=parentAssessmentQuesId;
        depQues.Question_Answer_Option__c=questionAnsOptId;
        //response.RecordTypeId = respRTId;
        if (create) insert depQues;
        return depQues;
    }

	//Create Scoring records
    public static Scoring__c createScoring(String rtName, String assessmentId, Integer minScore, Integer maxScore, String color, String status, Boolean create){
        Id respRTId;
        if (rtName != null && rtName != '')
        {
            respRTId = Schema.SObjectType.Scoring__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        }
        else
        {
            respRTId = TestFactory.getDefaultRT(Scoring__c.SObjectType.getDescribe());
        }
        Scoring__c scoringRec    = new Scoring__c();
        
        if(assessmentId !=null && assessmentId != '')
        {
        	scoringRec.Assessment__c     = assessmentId;
        }
        if(minScore != null)
        {
            scoringRec.Min_Score__c  = minScore;
        }
        if(maxScore != null)
        {
            scoringRec.Max_Score__c  = maxScore;
        }
        if(String.isNotBlank(status))
        {
            scoringRec.Status__c  = status;
        }
        //response.RecordTypeId = respRTId;
        if (create) insert scoringRec;
        return scoringRec;
    }
}