public with sharing class CreateNewQuestionCtrl {
    @AuraEnabled
    public static String checkDuplicate(String quesBankId, String dataType, List<String> ansOptions){
        String resp = 'unique';
        Map<String, List<String>> quesAnsOpMap = new Map<String, List<String>>();

        Map<String, caresp__Question__c> quesMap = new Map<String, caresp__Question__c>([select Id, Question_Data_type__c from Question__c where Question_Bank__c =: quesBankId and Question_Data_type__c =: dataType WITH SECURITY_ENFORCED]);

        if(quesMap!=null){
            List<caresp__Question_Answer_Option__c> quesAnsList = [Select Id, Answer__c, Question__c from Question_Answer_Option__c where Question__c in :quesMap.keySet() WITH SECURITY_ENFORCED];

            if(quesAnsList!=null && quesAnsList.size()>0){
                for(caresp__Question_Answer_Option__c qao: quesAnsList){
                    if(!quesAnsOpMap.containsKey(qao.caresp__Question__c)){
                        quesAnsOpMap.put(qao.caresp__Question__c, new List<String>());
                        quesAnsOpMap.get(qao.caresp__Question__c).add(qao.caresp__Answer__c);
                    }else{
                        quesAnsOpMap.get(qao.caresp__Question__c).add(qao.caresp__Answer__c);
                    }
                }   
            }
			
            if (ansOptions != Null && ansOptions.size() > 0)
            {
                ansOptions.sort();
            }
            
            if(quesAnsOpMap!=null){
                for(String q: quesAnsOpMap.keySet()){
                    quesAnsOpMap.get(q).sort();
                    if(ansOptions.equals(quesAnsOpMap.get(q)) && quesAnsOpMap.get(q).equals(ansOptions) && resp=='unique' ){
                        resp='Duplicate';
                    }
                }
            }
        }

        return resp;
    }

    @AuraEnabled
    public static Boolean checkEditable(String recId){
        List<caresp__Assessment_Question__c> aqList = [select Id from Assessment_Question__c where Question__c = :recId WITH SECURITY_ENFORCED];

        if(aqList!=null && aqList.size()>0){
            return false;
        }
        return true;
    }

   @AuraEnabled
public static String createQuestion(Question__c question) {
    System.debug('question>>> ' + question);
    if (question != null && Schema.sObjectType.caresp__Question__c.isCreateable()) { 
        // Prepare the list of records and strip inaccessible fields
        List<caresp__Question__c> questionList = new List<caresp__Question__c>{ question };
        List<caresp__Question__c> safeQuestions = Security.stripInaccessible(AccessType.CREATABLE, questionList).getRecords();
         System.debug('safeQuestions>>> ' + safeQuestions);

        // Perform the insert operation and capture the result
        List<Database.SaveResult> results = Database.insert(safeQuestions, false, AccessLevel.USER_MODE);

        // Check if the first operation succeeded and return the ID
        if (results[0].isSuccess()) {
            return safeQuestions[0].Id; // Return the ID of the successfully inserted record
        }
    }
    return null; // Return null if creation fails or permissions are insufficient
}


    @AuraEnabled
    public static string updateQuestion(caresp__Question__c question){
        List<caresp__Question_Answer_Option__c> ansOpList = new List<caresp__Question_Answer_Option__c>();

        ansOpList = [select Id from Question_Answer_Option__c where Question__c =: question.Id WITH SECURITY_ENFORCED];

        if(ansOpList!=null && ansOpList.size()>0 && Schema.sObjectType.caresp__Question_Answer_Option__c.isDeletable()){
            //System.debug('ansOpList >> '+ansOpList);
            delete as user Security.stripInaccessible(AccessType.READABLE, ansOpList).getRecords();

            //delete ansOpList;
        }
        if (Schema.sObjectType.caresp__Question__c.isUpdateable()) {//added by sg
            update as user Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Question__c>{question}).getRecords();

          //  update question;
        }
        return question.Id;
    }

    @AuraEnabled
    public static void createAnsOptions(List<caresp__Question_Answer_Option__c> ansOptions, Boolean isEdit){
        /* if(isEdit){
delete (new List<Question_Answer_Option__c>([select Id from Question_Answer_Option__c where Question__c =:ansOptions[0].Question__c]));
} */
        if (Schema.sObjectType.caresp__Question_Answer_Option__c.isCreateable()) {//added by sg
            insert as user Security.stripInaccessible(AccessType.CREATABLE, ansOptions).getRecords();

            //insert ansOptions;
        }
    }
    
    @AuraEnabled
    public static QuestionWrapper getQuestionData(String recordId){
        QuestionWrapper quesWrapper = new QuestionWrapper();
        List<caresp__Question_Answer_Option__c> ansOpList = new List<caresp__Question_Answer_Option__c>();
        Question__c quesRec = [select Id, Question_Bank__c, Question_Data_type__c, Question_Category__c, Question_Text__c, Is_Dependent__c from Question__c where Id=:recordId WITH SECURITY_ENFORCED];
        ansOpList = [select Id, Answer__c, Answer_Text__c, Sequence__c from Question_Answer_Option__c where Question__c=:quesRec.Id WITH SECURITY_ENFORCED];
        quesWrapper.Id = quesRec.Id;
        quesWrapper.quesDataType = quesRec.caresp__Question_Data_type__c;
        quesWrapper.quesCategory = quesRec.caresp__Question_Category__c;
        quesWrapper.quesText = quesRec.caresp__Question_Text__c;
        quesWrapper.quesBank = quesRec.caresp__Question_Bank__c;
        quesWrapper.isDependent = quesRec.caresp__Is_Dependent__c;
        quesWrapper.ansList = ansOpList;
        
        return quesWrapper;
    }
    
    public class QuestionWrapper{
        @AuraEnabled public String Id;
        @AuraEnabled public String quesDataType;
        @AuraEnabled public String quesCategory;
        @AuraEnabled public String quesText;
        @AuraEnabled public String quesBank;
        @AuraEnabled public Boolean isDependent;
        @AuraEnabled public List<caresp__Question_Answer_Option__c> ansList;
    }
}