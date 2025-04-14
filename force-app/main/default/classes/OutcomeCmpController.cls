public with sharing class OutcomeCmpController {
    @AuraEnabled(cacheable = true)
    public static List<caresp__Outcome__c> getOutcomes(String recordId){
        return [select Id, Name, Assessment__c, Assessment__r.Name, format(Assessment_Date__c) AssessmentDate, /* Client__c, Client__r.Full_Name__c, */ Outcome__c, Color__c, Status__c, Total_Score__c, Total_Max_Score__c, createdby.Id, createdby.name, format(CreatedDate) createDate, lastmodifiedby.Id, lastmodifiedby.name, format(lastModifiedDate) editDate from Outcome__c where Record_Id__c =:recordId and Status__c='Complete' AND InActive__c = false WITH SECURITY_ENFORCED order by lastmodifieddate desc];
    }

    @AuraEnabled(cacheable = true)
    public static OutcomeDetailsWrapper getOutcomeDetails(String outcomeId, String objName){
        outcomeId = String.escapeSingleQuotes(outcomeId);
        system.debug('objectName>>>> ' +objName);
        objName =   String.escapeSingleQuotes(objName);
        
        OutcomeDetailsWrapper respWrp = new OutcomeDetailsWrapper();
        String sfObjectName = objName;
        if(String.isNotBlank(objName)){
            if(!objName.contains('__c')){
                objName = objName+'__c';
            }
        }
        String query = 'select Id, Name, caresp__Outcome__c, caresp__Assessment__r.Name, caresp__Color__c, caresp__Status__c, caresp__Assessment_Date__c, caresp__Object__c, caresp__Total_Score__c, caresp__Total_Max_Score__c, createdby.name, CreatedDate, lastmodifiedby.Id, lastmodifiedby.name, lastmodifieddate, '+ String.escapeSingleQuotes(objName) +' from caresp__Outcome__c where Id =:outcomeId AND caresp__inActive__c = false WITH SECURITY_ENFORCED';

        caresp__Outcome__c outcome = Database.query(query);
        
        if(outcome != null){
            String strAssessmentDate=(String)outcome.Assessment_Date__c.format();

            respWrp.assessmentName = outcome.caresp__Assessment__r.Name;
            respWrp.assessmentStatus = outcome.caresp__Status__c;
            respWrp.assessmentDate = strAssessmentDate;
            respWrp.recordId = (String)outcome.get(objName);
            respWrp.objectName = sfObjectName;
            respWrp.outcome = outcome.caresp__Outcome__c;
            respWrp.color = outcome.caresp__Color__c;
            respWrp.createdBy = outcome.createdby.name;
            respWrp.lastModifiedBy = outcome.lastmodifiedby.name;
            respWrp.createdDate = String.valueOf(outcome.CreatedDate);
            respWrp.lastModifiedDate = String.valueOf(outcome.lastmodifieddate);
            respWrp.totalScore = Integer.valueOf(outcome.caresp__Total_Score__c);
            respWrp.totalMaxScore = Integer.valueOf(outcome.caresp__Total_Max_Score__c);
        }
        return respWrp;
    }


    

    @AuraEnabled(cacheable = true)
    public static List<QuestionsWrapper> getResponses(String outcomeId){
        List<String> numSeqList = new List<String>{'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26'};
        List<String> alphaSeqList = new List<String>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
        List<String> greekSeqList = new List<String>{'i','ii','iii','iv','v','vi','vii','viii','ix','x','xi','xii','xiii','xiv','xv','xvi','xvii','xviii','xix','xx','xxi','xxii','xxiii','xxiv','xxv','xxvi'};
        
        List<caresp__Response__c> responseList = new List<caresp__Response__c>();
        List<QuestionsWrapper> quesWrpList = new List<QuestionsWrapper>();

        responseList = [select Id, Question_Text__c, Backend_Sequence__c, Assessment_Question__r.Question__r.Question_Text__c, Assessment_Question__r.Question__r.Question_Data_type__c, Assessment_Question__r.Question__r.Answer_Options__c, Assessment_Question__r.Section__c, Sequence__c, Assessment_Question__r.Section_Sequence__c, Response__c from Response__c where Outcome__c =:outcomeId AND InActive__c = false WITH SECURITY_ENFORCED order by Backend_Sequence__c];

        Integer prevSectionSeq;
        String prevSection = '';

        if(responseList!=null && responseList.size() > 0){
            for(caresp__Response__c resp : responseList){
                String level = '';
                String seqForWrap = '';
                if(resp.caresp__Sequence__c != null){
                    String seq = resp.caresp__Sequence__c;
                    Integer count = seq.countMatches('-');
                    if(count == 0){
                        level = 'level1';
                        seqForWrap = seq;
                    }else if(count == 1){
                        level = 'level2';
                        seqForWrap = seq.subStringAfter('-');
                    }else{
                        level = 'level3';
                        seqForWrap = seq.substringAfterLast('-');
                    }
                }

                List<String> ansOpList = new List<String>();
                List<QuesAnswerWrapper> quesAnsWrpList = new List<QuesAnswerWrapper>();

                if(resp.caresp__Assessment_Question__r.caresp__Question__r.caresp__Question_Data_type__c == 'Radio Box' || resp.caresp__Assessment_Question__r.caresp__Question__r.caresp__Question_Data_type__c == 'Picklist' || resp.caresp__Assessment_Question__r.caresp__Question__r.caresp__Question_Data_type__c == 'Checkbox'){
                    String temp = resp.caresp__Assessment_Question__r.caresp__Question__r.caresp__Answer_Options__c;
                    System.debug('temp >> '+temp);
                    ansOpList = temp.split('\\|');
                    System.debug('ansOpList >> '+ansOpList);
                    if(ansOpList!=null && ansOpList.size()>0){
                        for(String ans : ansOpList){
                            quesAnsWrpList.add(new QuesAnswerWrapper(ans, ans));
                        }
                    }
                }

                prevSectionSeq = resp.caresp__Assessment_Question__r.caresp__Section_Sequence__c!=null?(Integer)resp.caresp__Assessment_Question__r.caresp__Section_Sequence__c:prevSectionSeq;
                System.debug('prevSectionSeq # '+prevSectionSeq);
                prevSection = String.isNotBlank(resp.caresp__Assessment_Question__r.caresp__Section__c)?resp.caresp__Assessment_Question__r.caresp__Section__c:prevSection;
                System.debug('prevSection # '+prevSection);

                quesWrpList.add(new QuestionsWrapper(level, (String)resp.Id, resp.Question_Text__c, 
                 resp.Assessment_Question__r.Question__r.Question_Data_type__c, resp.Backend_Sequence__c, 
                 seqForWrap, prevSection, prevSectionSeq, resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Text'?true:false, 
                 resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Number'?true:false,
                  resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Checkbox'?true:false, 
                  resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Radio Box'?true:false,
                   resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Picklist'?true:false,
                   resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Long Text Area'?true:false,
                   resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Currency'?true:false,
                   resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Date'?true:false,
                   resp.Assessment_Question__r.Question__r.Question_Data_type__c=='Telephone'?true:false,resp.Response__c, quesAnsWrpList));



                
            
            }
        }

        return quesWrpList;
    }

     public class QuestionsWrapper{
        @AuraEnabled public String level;
        @AuraEnabled public String responseId;
        @AuraEnabled public String quesText;
        @AuraEnabled public String dataType;
        @AuraEnabled public Decimal sequence;
        @AuraEnabled public String sfSeq;
        @AuraEnabled public String section;
        @AuraEnabled public Decimal sectionSequence;
        @AuraEnabled public Boolean isText;
        @AuraEnabled public Boolean isNumber;
        @AuraEnabled public Boolean isCheckbox;
        @AuraEnabled public Boolean isRadio;
        @AuraEnabled public Boolean isCombobox;
        @AuraEnabled public Boolean isLongText;
        @AuraEnabled public Boolean isCurrency;
        @AuraEnabled public Boolean isDate;
        @AuraEnabled public Boolean isPhone;
        @AuraEnabled public String response;
        @AuraEnabled public List<QuesAnswerWrapper> quesAnsList;
        public QuestionsWrapper(String level, String responseId, String quesText, String dataType, Decimal sequence, String sfSeq, String section, Decimal sectionSequence, Boolean isText, Boolean isNumber, Boolean isCheckbox, Boolean isRadio, Boolean isCombobox, Boolean isLongText, Boolean isCurrency, Boolean isDate, Boolean isPhone,String response, List<QuesAnswerWrapper> quesAnsList)
        {
            this.level = level;
            this.responseId = responseId;
            this.quesText = quesText;
            this.dataType = dataType;
            this.sequence = sequence;
            this.sfSeq = sfSeq;
            this.section = section;
            this.sectionSequence = sectionSequence;
            this.isText = isText;
            this.isNumber = isNumber;
            this.isCheckbox = isCheckbox;
            this.isRadio = isRadio;
            this.isCombobox = isCombobox;
            this.isLongText = isLongText;
            this.isCurrency = isCurrency;
            this.isDate = isDate;
            this.isPhone = isPhone;
            this.response = response;
            this.quesAnsList = quesAnsList;
        }
    }

    public class OutcomeDetailsWrapper{
        @AuraEnabled public String assessmentName {get;set;}
        @AuraEnabled public String assessmentStatus {get;set;}
        @AuraEnabled public String assessmentDate {get;set;}
        @AuraEnabled public String recordId {get;set;}
        @AuraEnabled public String objectName {get;set;}
        @AuraEnabled public String color {get;set;}
        @AuraEnabled public String outcome {get;set;}
        @AuraEnabled public String createdBy {get;set;}
        @AuraEnabled public String lastModifiedBy {get;set;}
        @AuraEnabled public String createdDate {get;set;}
        @AuraEnabled public String lastModifiedDate {get;set;}
        @AuraEnabled public Integer totalScore {get;set;}
        @AuraEnabled public Integer totalMaxScore {get;set;}
    }

    public class QuesAnswerWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public QuesAnswerWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}