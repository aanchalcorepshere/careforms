public with sharing class AssessmentQuestionnaireController {

    @AuraEnabled
    public static string checkLookupOnOutcomeObject(String objName){
        String ret;
        if(String.isNotBlank(objName)){
            if(!objName.contains('__c')){
                objName = objName+'__c';
            }
            String q = 'select Id, '+ String.escapeSingleQuotes(objName) +' from caresp__Outcome__c WITH SECURITY_ENFORCED limit 1';
            try{
                caresp__Outcome__c outcomeRec = Database.query(q);
                ret = 'has lookup';
            }catch(Exception e){
                System.debug('error > '+e.getMessage());   
                ret = e.getMessage();
            }
        }
        return ret;
    }
    
    @AuraEnabled(cacheable = true)
    public static string getAssessments(String objectName){
        List<PicklistWrapper> resp = new List<PicklistWrapper>();
        List<caresp__Assessment__c> assessmentList = [select Id, Name from Assessment__c where Active__c = true WITH SECURITY_ENFORCED];

        if(assessmentList!=null && assessmentList.size()>0){
            for(caresp__Assessment__c assess:assessmentList){
                resp.add(new PicklistWrapper(assess.Name, assess.Name+'|'+assess.Id));
            }
        }
        System.debug('resp '+resp);
        return JSON.serialize(resp);
    }

    @AuraEnabled(cacheable = true)
    public static List<PicklistWrapper> getDraftAssessments(String recordId){
        List<PicklistWrapper> respList = new List<PicklistWrapper>();
        List<caresp__Outcome__c> outcomeList = [select Id, Assessment__r.Name, Assessment_Date__c/* , Client__r.Full_Name__c */ from Outcome__c where Record_Id__c =: recordId and Status__c = 'Draft' WITH SECURITY_ENFORCED];

        if(outcomeList!=null && outcomeList.size()>0){
            for(caresp__Outcome__c outcome : outcomeList){
                Date d = Date.valueOf(outcome.caresp__Assessment_Date__c);
                String dateString = d.format();
                respList.add(new PicklistWrapper(outcome.caresp__Assessment__r.Name+' - '+dateString, outcome.Id));
                //respList.add(new PicklistWrapper(outcome.Assessment__r.Name+' ('+outcome.Client__r.Full_Name__c+') - '+dateString, outcome.Id));
            }
        }
        return respList;
    }

    @AuraEnabled
    public static caresp__Assessment__c getAssessmentDetails(String assessmentId){
        List<caresp__Assessment__c> assessmentList = [select Id, Name, Assessment_Description__c from Assessment__c where Id =: assessmentId WITH SECURITY_ENFORCED];

        return assessmentList[0];
    }

    @AuraEnabled
    public static DraftWrapper getDraftAssessmentDetails(String outcomeId){
        List<caresp__Outcome__c> outcomeList = [select Id, Assessment_Date__c, Init_Object__c, Assessment__c, Draft_Responses__c from Outcome__c where Id =: outcomeId WITH SECURITY_ENFORCED];

        DraftWrapper draftResp = new DraftWrapper();

        if(outcomeList!=null && outcomeList.size()>0){
            draftResp.assessmentRec = getAssessmentDetails(outcomeList[0].caresp__Assessment__c);
            draftResp.outcomeRec = outcomeList[0];
        }

        return draftResp;
    }
    
    @AuraEnabled
    public static string getQuestions(String assessmentId){
        List<String> quesWithAnsOpList = new List<String>();
        List<caresp__Question_Answer_Option__c> quesAnsList = new List<caresp__Question_Answer_Option__c>();
        List<QuestionsWrapper> wrapperList = new List<QuestionsWrapper>();
        Map<String, List<PicklistWrapper>> quesIdQuesAnsMap = new Map<String, List<PicklistWrapper>>();

        Map<String, caresp__Assessment_Question__c> assessmentQuestionMap = new Map<String, caresp__Assessment_Question__c>([select Id,Question__c, Question__r.Question_data_type__c, Question__r.Question_text__c, sequence__c,Section_Sequence__c, Required__c, Type__c, Field_Update__c, Section__c from Assessment_Question__c where Assessment__r.Id =: assessmentId and Type__c='General' WITH SECURITY_ENFORCED order by sequence__c]);
        System.debug('assessmentQuestionMap>>> ' + assessmentQuestionMap);
        if(!assessmentQuestionMap.isEmpty()){
            for(String aqId : assessmentQuestionMap.keySet()){
                String dataType = assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_data_type__c;
                if(dataType == 'Radio Box' || dataType == 'Picklist' || dataType == 'Checkbox'){
                    quesWithAnsOpList.add(assessmentQuestionMap.get(aqId).caresp__Question__c);
                }
            }

            if(quesWithAnsOpList!=null && quesWithAnsOpList.size()>0){
                quesAnsList = [select Id, Question__c, Answer__c, Answer_Text__c, Sequence__c from Question_Answer_Option__c where Question__c in :quesWithAnsOpList WITH SECURITY_ENFORCED order by Question__c, Sequence__c];
                System.debug('quesAnsList>>> ' + quesAnsList);
                if(quesAnsList!=null && quesAnsList.size()>0){
                    for(caresp__Question_Answer_Option__c qao : quesAnsList){
                        if(!quesIdQuesAnsMap.containsKey(qao.caresp__Question__c)){
                            quesIdQuesAnsMap.put(qao.caresp__Question__c, new List<PicklistWrapper>());
                            quesIdQuesAnsMap.get(qao.caresp__Question__c).add(new PicklistWrapper(qao.caresp__Answer_Text__c, qao.Id+'|'+qao.caresp__Answer_Text__c));
                        }else{
                            quesIdQuesAnsMap.get(qao.caresp__Question__c).add(new PicklistWrapper(qao.caresp__Answer_Text__c, qao.Id+'|'+qao.caresp__Answer_Text__c));
                        }
                    }
                }
            }

            for(String aqId : assessmentQuestionMap.keySet()){
                String dataType = assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_data_type__c;
                wrapperList.add(new QuestionsWrapper('level1',aqId, assessmentQuestionMap.get(aqId).Id, assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_text__c, dataType, String.valueOf(assessmentQuestionMap.get(aqId).caresp__Sequence__c), null, null, assessmentQuestionMap.get(aqId).caresp__Field_Update__c!=null?assessmentQuestionMap.get(aqId).caresp__Field_Update__c:'' , assessmentQuestionMap.get(aqId).caresp__Section__c, assessmentQuestionMap.get(aqId).caresp__Section_Sequence__c, assessmentQuestionMap.get(aqId).caresp__Required__c,dataType=='Text'?true:false, dataType=='Number'?true:false, dataType=='Checkbox'?true:false, dataType=='Radio Box'?true:false, dataType=='Picklist'?true:false,dataType=='Long Text Area'?true:false, dataType=='Date'?true:false, dataType=='Currency'?true:false, dataType=='Telephone'?true:false, '', quesIdQuesAnsMap.get(assessmentQuestionMap.get(aqId).caresp__Question__c)));
            }
        }
System.debug('JSON.serialize(wrapperList)>>> ' + JSON.serialize(wrapperList));
        return JSON.serialize(wrapperList);
    }

    @AuraEnabled
    public static string getDependentQuestions(String grandParent, String parent, String ansOp, String level){
        List<String> dependentList = new List<String>();
        List<String> quesWithAnsOpList = new List<String>();
        List<caresp__Question_Answer_Option__c> quesAnsList = new List<caresp__Question_Answer_Option__c>();
        List<QuestionsWrapper> wrapperList = new List<QuestionsWrapper>();
        Map<String, List<PicklistWrapper>> quesIdQuesAnsMap = new Map<String, List<PicklistWrapper>>();

        List<caresp__Dependent_Question__c> dependentQuestionList = [select Dependent_Question__c from Dependent_Question__c where Parent_Question__c =: parent and Question_Answer_Option__c =: ansOp WITH SECURITY_ENFORCED];

        System.debug('dependentQuestionList >> '+dependentQuestionList);

        if(dependentQuestionList!=null && dependentQuestionList.size()>0){
            for(caresp__Dependent_Question__c dep : dependentQuestionList){
                dependentList.add(dep.caresp__Dependent_Question__c);
            }
        }

        Map<String, caresp__Assessment_Question__c> assessmentQuestionMap = new Map<String, caresp__Assessment_Question__c>([select Id,Question__c, Question__r.Question_data_type__c, Question__r.Question_text__c, Dependent_Sequence__c, Type__c, Section__c,Section_Sequence__c, Required__c from Assessment_Question__c where Id in : dependentList and Type__c='Dependent' WITH SECURITY_ENFORCED order by Dependent_Sequence__c]);

        System.debug('assessmentQuestionMap >> '+assessmentQuestionMap);

        if(!assessmentQuestionMap.isEmpty()){
            for(String aqId : assessmentQuestionMap.keySet()){
                String dataType = assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_data_type__c;
                if(dataType == 'Radio Box' || dataType == 'Picklist' || dataType == 'Checkbox'){
                    quesWithAnsOpList.add(assessmentQuestionMap.get(aqId).caresp__Question__c);
                }
            }

            if(quesWithAnsOpList!=null && quesWithAnsOpList.size()>0){
                quesAnsList = [select Id, Question__c, Answer__c, Answer_Text__c, Sequence__c from Question_Answer_Option__c where Question__c in :quesWithAnsOpList WITH SECURITY_ENFORCED order by Question__c, Sequence__c];

                if(quesAnsList!=null && quesAnsList.size()>0){
                    for(caresp__Question_Answer_Option__c qao : quesAnsList){
                        if(!quesIdQuesAnsMap.containsKey(qao.Question__c)){
                            quesIdQuesAnsMap.put(qao.caresp__Question__c, new List<PicklistWrapper>());
                            quesIdQuesAnsMap.get(qao.caresp__Question__c).add(new PicklistWrapper(qao.caresp__Answer_Text__c, qao.Id+'|'+qao.caresp__Answer_Text__c));
                        }else{
                            quesIdQuesAnsMap.get(qao.caresp__Question__c).add(new PicklistWrapper(qao.caresp__Answer_Text__c, qao.Id+'|'+qao.caresp__Answer_Text__c));
                        }
                    }
                }
            }

            for(String aqId : assessmentQuestionMap.keySet()){
                String dataType = assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_data_type__c;

                wrapperList.add(new QuestionsWrapper(level == 'level1'?'level2':'level3',aqId, assessmentQuestionMap.get(aqId).Id, assessmentQuestionMap.get(aqId).caresp__Question__r.caresp__Question_text__c, dataType, String.valueOf(assessmentQuestionMap.get(aqId).caresp__Dependent_Sequence__c), grandParent, parent, '', assessmentQuestionMap.get(aqId).caresp__Section__c, assessmentQuestionMap.get(aqId).caresp__Section_Sequence__c, assessmentQuestionMap.get(aqId).caresp__Required__c,dataType=='Text'?true:false, dataType=='Number'?true:false, dataType=='Checkbox'?true:false, dataType=='Radio Box'?true:false, dataType=='Picklist'?true:false, dataType=='Long Text Area'?true:false, dataType=='Date'?true:false, dataType=='Currency'?true:false, dataType=='Telephone'?true:false,  '', quesIdQuesAnsMap.get(assessmentQuestionMap.get(aqId).caresp__Question__c)));
            }
        }

        System.debug('wrapperList => '+JSON.serialize(wrapperList));
        return JSON.serialize(wrapperList);
    }

    @AuraEnabled
    public static String saveDraftResponses(String recordId, String assessmentId, String assessmentName, Date assessmentDate, String objName, String draftResponses, String draftOutcomeId){
        Id objRecId = (Id) recordId;
        caresp__Outcome__c newOutcome = new caresp__Outcome__c();
    
        // Ensure the object name has the "__c" suffix
        if (String.isNotBlank(objName) && !objName.endsWith('__c')) {
            objName += '__c';
        }
    
        // Assign fields only if they are createable
        if (Schema.sObjectType.caresp__Outcome__c.fields.Name.isCreateable()) {
            newOutcome.Name = assessmentName + ' Outcome';
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Assessment__c.isCreateable()) {
            newOutcome.caresp__Assessment__c = assessmentId;
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Draft_Responses__c.isCreateable()) {
            newOutcome.caresp__Draft_Responses__c = draftResponses;
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Status__c.isCreateable()) {
            newOutcome.caresp__Status__c = 'Draft';
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Assessment_Date__c.isCreateable()) {
            newOutcome.caresp__Assessment_Date__c = assessmentDate;
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Object__c.isCreateable()) {
            newOutcome.caresp__Object__c = objName;
        }
        if (Schema.sObjectType.caresp__Outcome__c.fields.caresp__Record_Id__c.isCreateable()) {
            newOutcome.caresp__Record_Id__c = recordId;
        }
    
        // Validate dynamic field access before using put()
        if (Schema.sObjectType.caresp__Outcome__c.fields.getMap().containsKey(objName) &&
        Schema.sObjectType.caresp__Outcome__c.fields.getMap().get(objName).getDescribe().isCreateable()) {
            newOutcome.put(objName, objRecId);
        }
    
        List<caresp__Outcome__c> creatableRecords = new List<caresp__Outcome__c>();
        List<caresp__Outcome__c> updatableRecords = new List<caresp__Outcome__c>();
    
        // Separate records for insert and update
        if (Schema.sObjectType.caresp__Outcome__c.isCreateable() && newOutcome.Id == null) {
            creatableRecords.add(newOutcome);
        } else if (Schema.sObjectType.caresp__Outcome__c.isUpdateable() && newOutcome.Id != null) {
            updatableRecords.add(newOutcome);
        }
    
        // Perform insert operation for creatable records
        if (!creatableRecords.isEmpty()) {
            List<caresp__Outcome__c> insertedRecords = 
                Security.stripInaccessible(AccessType.CREATABLE, creatableRecords).getRecords();
            if (!insertedRecords.isEmpty() && Schema.sObjectType.caresp__Outcome__c.isCreateable() ) {
                insert as user insertedRecords;
                newOutcome.Id = insertedRecords[0].Id;
            }
        }
    
        // Perform update operation for updatable records
        if (!updatableRecords.isEmpty() && Schema.sObjectType.caresp__Outcome__c.isUpdateable()) {
            List<caresp__Outcome__c> updatedRecords = 
                Security.stripInaccessible(AccessType.UPDATABLE, updatableRecords).getRecords();
            if (!updatedRecords.isEmpty()) {
                update as user updatedRecords;
            }
        }
    
        return newOutcome.Id;

    } 

    @AuraEnabled
    public static String getTodayDate(){
        DateTime now = DateTime.now();
        System.debug('String.valueOf(now.getDate()) >> '+now.format('MM/dd/yyyy'));
        return String.valueOf(now.format('MM/dd/yyyy'));
    } 

    @AuraEnabled
    public static String saveResponses(String recordId, String objName, String assessmentId, String assessmentName, String responses, Date assessmentDate, String draftOutcomeId) {
        try {
            // Parse the input responses
            List<Object> fullMap = (List<Object>) JSON.deserializeUntyped(responses);
            if (fullMap == null || fullMap.isEmpty()) {
                throw new AuraHandledException('Responses data is missing or invalid.');
            }

            // Create or update the Outcome record
            String outcomeId = handleOutcome(recordId, objName, assessmentId, assessmentName, assessmentDate, draftOutcomeId);

            // Prepare Assessment Question Score Map
            Map<String, Integer> qaoScoreMap = getAssessmentQuestionScores(assessmentId);

            // Handle Responses and Calculate Overall Score
            Integer overallScore = 0;
            List<caresp__Response__c> responseList = handleResponses(fullMap, assessmentId, outcomeId, qaoScoreMap, overallScore);

            // Insert Responses
            if (!responseList.isEmpty() && caresp__Response__c.sObjectType.getDescribe().isCreateable()) {
                insert Security.stripInaccessible(AccessType.CREATABLE, responseList).getRecords();
            }

            // Update Outcome Record
            updateOutcome(overallScore, outcomeId, assessmentId);

            // Update Object Fields based on Field Value Map
            Map<String, String> fieldValueMap = getFieldValueMap(fullMap);
            if (!fieldValueMap.isEmpty()) {
                updateObjectFields(recordId, objName, fieldValueMap);
            }

            return outcomeId;
        } catch (Exception ex) {
            System.debug('Error in saveResponses: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while saving responses: ' + ex.getMessage());
        }
    }

    // Helper Method: Handle Outcome Record Creation or Update
    private static String handleOutcome(String recordId, String objName, String assessmentId, String assessmentName, Date assessmentDate, String draftOutcomeId) {
        if (String.isNotBlank(draftOutcomeId)) {
            return draftOutcomeId;
        }
        if(String.isNotBlank(objName)){
                if(!objName.contains('__c')){
                    objName = objName+'__c';
                }
            }

        caresp__Outcome__c outcome = new caresp__Outcome__c();
        outcome.Name = assessmentName + ' Outcome';
        outcome.caresp__Assessment__c = assessmentId;
        outcome.caresp__Status__c = 'Complete';
        outcome.caresp__Assessment_Date__c = assessmentDate;
        outcome.caresp__Object__c = objName;
        outcome.put(objName, recordId);
        List<caresp__Outcome__c> recordsToInsert  = new List<caresp__Outcome__c>();
        

        if (caresp__Outcome__c.sObjectType.getDescribe().isCreateable()) {
            recordsToInsert = Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Outcome__c> { outcome }).getRecords();
            insert recordsToInsert;
        
        }
        return recordsToInsert[0].Id;

    // throw new AuraHandledException('Insufficient permissions to create Outcome.');
    }

    // Helper Method: Get Assessment Question Scores
    private static Map<String, Integer> getAssessmentQuestionScores(String assessmentId) {
        Map<String, Integer> qaoScoreMap = new Map<String, Integer>();
        List<caresp__Assessment_Question__c> assessmentQuestions = [
            SELECT Id, Score__c FROM caresp__Assessment_Question__c
            WHERE caresp__Assessment__c = :assessmentId AND Score__c != null WITH SECURITY_ENFORCED
        ];

        for (caresp__Assessment_Question__c question : assessmentQuestions) {
            if (String.isNotBlank(question.caresp__Score__c)) {
                for (String score : question.caresp__Score__c.split(';')) {
                    qaoScoreMap.put(score.substringBefore('|'), Integer.valueOf(score.substringAfter('|')));
                }
            }
        }
        return qaoScoreMap;
    }

    // Helper Method: Handle Responses
    private static List<caresp__Response__c> handleResponses(
        List<Object> fullMap, 
        String assessmentId, 
        String outcomeId, 
        Map<String, Integer> qaoScoreMap, Integer overallScore) 
        {
        List<caresp__Response__c> responseList = new List<caresp__Response__c>();
        Integer backendSeq = 1;

        for (Object obj : fullMap) {
            System.debug('CHECK OBJ VALUE >>' +obj);
            Map<String, Object> responseMap = (Map<String, Object>) obj;
            caresp__Response__c response = createResponse(responseMap, assessmentId, outcomeId, qaoScoreMap, backendSeq);
            overallScore += response.caresp__Score__c != null ? Integer.valueOf(response.caresp__Score__c.intValue()) : 0;
            responseList.add(response);

            backendSeq++;  
            system.debug('handleResponses backendSeq  >>>' +backendSeq);

            // Pass by reference, no need to reassign responseList
            handleDependentResponses(responseMap, assessmentId, outcomeId, qaoScoreMap, responseList, backendSeq, overallScore);
        }

        return responseList;
    }

    // Helper Method: Create Response Record
    private static caresp__Response__c createResponse(Map<String, Object> responseMap, String assessmentId, String outcomeId, Map<String, Integer> qaoScoreMap, Integer backendSeq) {
        caresp__Response__c response = new caresp__Response__c();
        response.caresp__Sequence__c = (String) responseMap.get('sequence');
        response.caresp__Assessment_Question__c = (Id) responseMap.get('assessmentQuesId');
        response.caresp__Response__c = (String) responseMap.get('response');
        response.caresp__Assessment__c = assessmentId;
        response.caresp__Outcome__c = outcomeId;
        response.caresp__Backend_Sequence__c = backendSeq;

        String respId = (String) responseMap.get('responseId');
        if (String.isNotBlank(respId) && qaoScoreMap.containsKey(respId)) {
            response.caresp__Score__c = qaoScoreMap.get(respId);
        } else {
            response.caresp__Score__c = 0;
        }

        return response;
    }

    private static void handleDependentResponses(
        Map<String, Object> responseMap, 
        String assessmentId, 
        String outcomeId, 
        Map<String, Integer> qaoScoreMap, 
        List<caresp__Response__c> responseList, 
        Integer backendSeq, 
        Integer overallScore
    ) {
        // Handle dependentQuestions
        processDependentList(responseMap, 'dependentQuestions', assessmentId, outcomeId, qaoScoreMap, responseList, backendSeq, overallScore);

        // Handle dependentDependentQuestions (Grandchild level)
        processDependentList(responseMap, 'dependentDependentQuestions', assessmentId, outcomeId, qaoScoreMap, responseList, backendSeq, overallScore);
    }

    private static void processDependentList(
        Map<String, Object> responseMap,
        String key,
        String assessmentId, 
        String outcomeId, 
        Map<String, Integer> qaoScoreMap, 
        List<caresp__Response__c> responseList, 
        Integer backendSeq, 
        Integer overallScore
    ) {
        List<Object> dependentResponses = (List<Object>) responseMap.get(key);
        
        if (dependentResponses != null) {
            for (Object depResponseObj : dependentResponses) {
                Map<String, Object> depResponseMap = (Map<String, Object>) depResponseObj;
                
                System.debug('Processing ' + key + ': ' + depResponseMap);

                caresp__Response__c depResponse = createResponse(depResponseMap, assessmentId, outcomeId, qaoScoreMap, backendSeq);
                overallScore += depResponse.caresp__Score__c != null ? Integer.valueOf(depResponse.caresp__Score__c.intValue()) : 0;
                responseList.add(depResponse);

                backendSeq++; // Increment before recursion

                // Recursively process deeper levels
                handleDependentResponses(depResponseMap, assessmentId, outcomeId, qaoScoreMap, responseList, backendSeq, overallScore);
            }
        }
    }


    // Helper Method: Update Outcome Record
    private static void updateOutcome(Integer overallScore, String outcomeId, String assessmentId) {
        List<caresp__Scoring__c> scoringRecords = [
            SELECT Id, Color__c, Status__c
            FROM caresp__Scoring__c
            WHERE min_score__c <= :overallScore AND max_score__c >= :overallScore AND caresp__Assessment__c = :assessmentId WITH SECURITY_ENFORCED
        ];
        caresp__Outcome__c outcome = new caresp__Outcome__c(Id = outcomeId, caresp__Status__c = 'Complete');
        if (!scoringRecords.isEmpty()) {
            caresp__Scoring__c scoring = scoringRecords[0];
            if (String.isNotBlank(scoring.caresp__Color__c)) {
                outcome.caresp__Color__c = scoring.caresp__Color__c;
            }
            if (String.isNotBlank(scoring.caresp__Status__c)) {
                outcome.caresp__Outcome__c = scoring.caresp__Status__c;
            }
        }
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Outcome__c> { outcome }).getRecords();
    }

    // Helper Method: Update Object Fields
    private static void updateObjectFields(String recordId, String objName, Map<String, String> fieldValueMap) {
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objName);
        if (sObjType == null) {
            throw new AuraHandledException('Invalid object type: ' + objName);
        }

        SObject record = sObjType.newSObject();
        record.put('Id', recordId);

        for (String field : fieldValueMap.keySet()) {
            record.put(field, fieldValueMap.get(field));
        }

        update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject> { record }).getRecords();
    }

    // Helper Method: Extract Field Value Map
    private static Map<String, String> getFieldValueMap(List<Object> fullMap) {
        Map<String, String> fieldValueMap = new Map<String, String>();

        for (Object obj : fullMap) {
            Map<String, Object> responseMap = (Map<String, Object>) obj;
            String fieldUpdate = (String) responseMap.get('fieldUpdate');
            String response = (String) responseMap.get('response');

            if (String.isNotBlank(fieldUpdate) && String.isNotBlank(response)) {
                fieldValueMap.put(fieldUpdate, response);
            }
        }

        return fieldValueMap;
    }

  

    public class QuestionsWrapper{
        @AuraEnabled public String level;
        @AuraEnabled public String assessmentQuesId;
        @AuraEnabled public String quesId;
        @AuraEnabled public String quesText;
        @AuraEnabled public String dataType;
        @AuraEnabled public String sequence;
        @AuraEnabled public String grandParent;
        @AuraEnabled public String parent;
        @AuraEnabled public String fieldUpdate;
        @AuraEnabled public String section;
        @AuraEnabled public Decimal sectionSequence;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean isText;
        @AuraEnabled public Boolean isNumber;
        @AuraEnabled public Boolean isCheckbox;
        @AuraEnabled public Boolean isRadio;
        @AuraEnabled public Boolean isCombobox;
        @AuraEnabled public Boolean isLongText;
        @AuraEnabled public Boolean isDate;
        @AuraEnabled public Boolean isCurrency;
        @AuraEnabled public Boolean isPhone;
        @AuraEnabled public String response;
        @AuraEnabled public List<PicklistWrapper> quesAnsList;
        public QuestionsWrapper(String level, String assessmentQuesId, String quesId, String quesText, String dataType, String sequence, String grandParent, String parent, String fieldUpdate, String section, Decimal sectionSequence, Boolean required, Boolean isText, Boolean isNumber, Boolean isCheckbox, Boolean isRadio, Boolean isCombobox, Boolean isLongText, Boolean isDate, Boolean isCurrency, Boolean isPhone,String response, List<PicklistWrapper> quesAnsList){
            this.level = level;
            this.assessmentQuesId = assessmentQuesId;
            this.quesId = quesId;
            this.quesText = quesText;
            this.dataType = dataType;
            this.sequence = sequence;
            this.grandParent = grandParent;
            this.parent = parent;
            this.fieldUpdate = fieldUpdate;
            this.section = section;
            this.sectionSequence = sectionSequence;
            this.required = required;
            this.isText = isText;
            this.isNumber = isNumber;
            this.isCheckbox = isCheckbox;
            this.isRadio = isRadio;
            this.isCombobox = isCombobox;
            this.isLongText = isLongText;
            this.isDate = isDate;
            this.isCurrency = isCurrency;
            this.isPhone = isPhone;
            this.response = response;
            this.quesAnsList = quesAnsList;
        }
    }

    public class ResponseWrapper{
        @AuraEnabled public String initialObject;
        @AuraEnabled public String referralId;
        @AuraEnabled public List<PicklistWrapper> clientList;
        public ResponseWrapper(){

        }
        public ResponseWrapper(String initialObject, String referralId, List<PicklistWrapper> clientList){
            this.initialObject = initialObject;
            this.referralId = referralId;
            this.clientList = clientList;
        }
    }

    public class PicklistWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public class DraftWrapper{
        @AuraEnabled public caresp__Assessment__c assessmentRec;
        @AuraEnabled public caresp__Outcome__c outcomeRec;
        public DraftWrapper(){

        }
    }
    public class StatusModuleCheckWrapper
    {
        @AuraEnabled
        public String asRefStatus{get;set;}
        @AuraEnabled
        public String asRefModule{get;set;}
    }
}