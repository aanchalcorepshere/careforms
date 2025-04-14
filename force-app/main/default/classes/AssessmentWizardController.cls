public with sharing class AssessmentWizardController { // NOPMD
    public AssessmentWizardController() {
        
    }
    
    @AuraEnabled
    public static String checkAssessmentNameDuplicate(String assessmentName, String assessmentId){
        String resp = '';
        List<caresp__Assessment__c> assessmentList = new List<caresp__Assessment__c>();
        System.debug('assessmentId >> '+assessmentId);
        if(String.isNotBlank(assessmentId)){
            assessmentList = [select Id from Assessment__c where Name =: assessmentName and Id != :assessmentId WITH SECURITY_ENFORCED];
        }else{
            assessmentList = [select Id from Assessment__c where Name =: assessmentName WITH SECURITY_ENFORCED];
        }
        
        if(assessmentList!=null && assessmentList.size()>0){
            resp = 'Duplicate';
        }
        
        return resp;
    }
    
    @AuraEnabled
    public static String checkAssessmentInUse(String assessmentId){
        String resp = '';
        System.debug('assessmentId >> '+assessmentId);
        if(String.isNotBlank(assessmentId)){
            List<caresp__Outcome__c> outcomeList = [select Id from Outcome__c where Assessment__c =: assessmentId WITH SECURITY_ENFORCED];
            
            if(outcomeList!=null && outcomeList.size()>0){
                resp = 'non-editable';
            }
        }
        
        return resp;
    }
    
    @AuraEnabled(cacheable = true)
    public static String getObjectNames(){
        List<ObjectsWrapper> objectsWrapperList = new List<ObjectsWrapper>();   
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            Schema.DescribeSObjectResult describeSObjectResultObj = objTyp.getDescribe();
            if(describeSObjectResultObj.isCreateable()){
                String name = objTyp.getDescribe().getName();
                String label = objTyp.getDescribe().getLabel();
                // Exclude all the unwanted Sobjects e.g. History, Share etc.
                if(!name.containsignorecase('history') && !name.containsignorecase('tag')&&
                   !name.containsignorecase('share') && !name.containsignorecase('feed') && !name.containsignorecase('changeevent')){
                       objectsWrapperList.add(new ObjectsWrapper(label+' ('+name+')', name));
                   }   
            }
        }
        
        return JSON.serialize(objectsWrapperList);
    }
    
    /*@AuraEnabled
public static String getChildObjectNames(String parentObj){    
Set<ObjectsWrapper> objectsWrapperList = new Set<ObjectsWrapper>();   
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
Schema.SObjectType otype = gd.get(parentObj);
Schema.DescribeSObjectResult describeSObjectResultObj = otype.getDescribe();
for (Schema.ChildRelationship cr: describeSObjectResultObj.getChildRelationships()) {
if(cr.getRelationshipName() != null){
Schema.SObjectType ctype = gd.get(String.valueOf(cr.getChildSObject()));
Schema.DescribeSObjectResult describeChildSObjectResultObj = ctype.getDescribe();
String name = cr.getChildSObject().getDescribe().getName();
String label = cr.getChildSObject().getDescribe().getLabel();
if(!name.containsignorecase('history') && !name.containsignorecase('tag')&&
!name.containsignorecase('share') && !name.containsignorecase('feed') && !name.containsignorecase('changeevent')){
objectsWrapperList.add(new ObjectsWrapper(label+' ('+name+')', name));
}
}
}

return JSON.serialize(objectsWrapperList);
}*/
    
    @AuraEnabled
    public static String getCompatibleFields(String objName){
        Set<ObjectsWrapper> objectsWrapperList = new Set<ObjectsWrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isCustom() == true && fieldMap.get(fieldName).getDescribe().isCreateable() == true && (String.valueOf(fieldMap.get(fieldName).getDescribe().getType()) == 'STRING' || String.valueOf(fieldMap.get(fieldName).getDescribe().getType()) == 'TEXTAREA')){
                objectsWrapperList.add(new ObjectsWrapper(fieldMap.get(fieldName).getDescribe().getLabel()+'('+objName+')', fieldName));
            }
        }
        
        return JSON.serialize(objectsWrapperList);
    }
    
    @AuraEnabled
    public static List<ObjectsWrapper> getCompatibleFieldsBoolPick(List<String> objNames){
        List<ObjectsWrapper> objectsWrapperList = new List<ObjectsWrapper>();
        for(String type : objNames){
            
            System.debug('Type >> ' +type);
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if (!schemaMap.containsKey(type)) { 
                System.debug('Invalid SObject type: ' + type);
                throw new AuraHandledException('Invalid SObject type: ' + type);
            }
            Schema.SObjectType leadSchema = schemaMap.get(type);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
            
            for (String fieldName: fieldMap.keySet()) {
                if(fieldMap.get(fieldName).getDescribe().isCreateable() == true && (String.valueOf(fieldMap.get(fieldName).getDescribe().getType())=='BOOLEAN' || String.valueOf(fieldMap.get(fieldName).getDescribe().getType())=='PICKLIST')){
                    objectsWrapperList.add(new ObjectsWrapper(fieldMap.get(fieldName).getDescribe().getLabel()+'('+type+')', type+'|'+fieldName));
                }
            }
        }
        
        return objectsWrapperList;
    }
    
    @AuraEnabled
    public static FieldValueWrapper getFieldTypeAndValues(String fieldValue){
        
        FieldValueWrapper wrp = new FieldValueWrapper();
        String objName = fieldValue.subStringBefore('|');
        String fieldApi = fieldValue.subStringAfter('|');
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.SObjectType otype = gd.get(objName);
        Schema.DescribeSObjectResult describeSObjectResultObj = otype.getDescribe();
        Map<String, Schema.SObjectField> M = describeSObjectResultObj.fields.getMap();
        Schema.SObjectField field = M.get(fieldApi);
        Schema.DisplayType FldType = field.getDescribe().getType();
        
        // System.debug('FldType >> '+FldType);
        
        if(String.valueOf(FldType) == 'PICKLIST' || String.valueOf(FldType) == 'BOOLEAN'){
            wrp.fieldType = String.valueOf(FldType);
            
            if(String.valueOf(FldType) == 'PICKLIST'){
                List<ObjectsWrapper> fieldValues = new List<ObjectsWrapper>();
                List<String> pickListValuesList= new List<String>();
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType leadSchema = schemaMap.get(fieldApi);
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    pickListValuesList.add(pickListVal.getLabel());
                    fieldValues.add(new ObjectsWrapper(pickListVal.getLabel(), pickListVal.getLabel()));
                }
                wrp.fieldValueList = fieldValues;
                // System.debug('pickListValuesList >> '+pickListValuesList);
            }
            //  System.debug('wrp >>> '+wrp);
            
        }
        
        return wrp;
    }
    
    @AuraEnabled(cacheable = true)
    public static string getQuestionsForSelection(Boolean isDependent){
        
        List<String> quesWithAnsOps = new List<String>();
        List<QuestionsWrapper> quesWrapperList = new List<QuestionsWrapper>();
        
        List<caresp__Question_Answer_Option__c> quesAnsOpList = new List<caresp__Question_Answer_Option__c>();
        
        Map<String, List<caresp__Question_Answer_Option__c>> quesAnsOpMap = new Map<String, List<caresp__Question_Answer_Option__c>>();
        
        List<caresp__Question__c> quesList = [SELECT Id, Active__c, Answer_Options__c, Question_Data_type__c, Question_Text__c, Question_Category__c FROM Question__c WITH SECURITY_ENFORCED LIMIT 50000];
        
        //  System.debug('quesList >> '+quesList);
        
        for(caresp__Question__c ques: quesList){
            if(ques.caresp__Question_Data_type__c == 'Radio Box' || ques.caresp__Question_Data_type__c == 'Picklist'){
                quesWithAnsOps.add(ques.Id);
            }
        }
        
        if(quesWithAnsOps!=null && quesWithAnsOps.size()>0){
            quesAnsOpList = [select Id, Answer__c, Answer_Text__c, Question__c, Question_Text__c, Sequence__c from Question_Answer_Option__c where Question__c in :quesWithAnsOps WITH SECURITY_ENFORCED order by Sequence__c ];
            
            for(caresp__Question_Answer_Option__c ansOp:quesAnsOpList){
                if(!quesAnsOpMap.containsKey(ansOp.Question__c)){
                    quesAnsOpMap.put(ansOp.caresp__Question__c, new List<caresp__Question_Answer_Option__c>());
                    quesAnsOpMap.get(ansOp.caresp__Question__c).add(ansOp);
                }else{
                    quesAnsOpMap.get(ansOp.caresp__Question__c).add(ansOp);
                }
            }
        }
        
        for(caresp__Question__c ques: quesList){
            //  System.debug('ques >> '+ques);
            quesWrapperList.add(new QuestionsWrapper(ques.Id, ques.caresp__Question_Text__c, ques.caresp__Question_Data_type__c, ques.caresp__Answer_Options__c, quesAnsOpMap.get(ques.Id)!=null?quesAnsOpMap.get(ques.Id):null));
        }
        
        return JSON.serialize(quesWrapperList);
    }
    
    @AuraEnabled
    public static caresp__Assessment__c getEditJson(String assessmentId){
        return [select Id, Assessment_Detail_JSON__c, Field_Update_JSON__c, Questions_JSON__c, Scoring_JSON__c, Section_JSON__c from Assessment__c where id =: assessmentId WITH SECURITY_ENFORCED];
    }
    
    @AuraEnabled
    public static String createAssessmentRecord(String assessmentName, String description, Boolean active, String editAssessmentId, String objName) {
        caresp__Assessment__c newAssessment = new caresp__Assessment__c();
        System.debug('editAssessmentId >> ' + editAssessmentId);
        if (String.isNotBlank(editAssessmentId)) {
            newAssessment.Id = editAssessmentId; // If updating an existing record
        }
        
        // Populate fields
        newAssessment.Name = assessmentName;
        newAssessment.caresp__active__c = active;
        newAssessment.caresp__Assessment_Description__c = description;
        newAssessment.caresp__Object__c = String.isNotBlank(objName) ? objName : '';
        
        if (Schema.sObjectType.caresp__Assessment__c.isCreateable() || Schema.sObjectType.caresp__Assessment__c.isUpdateable()) {
            System.debug('Permission Check: true');
            
            // Separate creatable and updatable logic
            if (Schema.sObjectType.caresp__Assessment__c.isCreateable() && Schema.sObjectType.caresp__Assessment__c.fields.Name.isCreateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__active__c.isCreateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__Assessment_Description__c.isCreateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__Object__c.isCreateable() && newAssessment.Id == null) {
                // Handle insert (creatable)
                List<caresp__Assessment__c> creatableRecords = Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Assessment__c>{ newAssessment }).getRecords();
                insert as user creatableRecords;
                System.debug('Insert successful. ID: ' + creatableRecords[0].Id);
                return creatableRecords[0].Id; // Return the inserted record ID
            } 
            else if ( newAssessment.Id != null && Schema.sObjectType.caresp__Assessment__c.isUpdateable() && Schema.sObjectType.caresp__Assessment__c.fields.Name.isUpdateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__active__c.isUpdateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__Assessment_Description__c.isUpdateable() && Schema.sObjectType.caresp__Assessment__c.fields.caresp__Object__c.isUpdateable() ) 
            {
                // Handle update (updatable)
                List<caresp__Assessment__c> updatableRecords = Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Assessment__c>{ newAssessment }).getRecords();
                
                update as user updatableRecords;
                System.debug('Update successful. ID: ' + updatableRecords[0].Id);
                return updatableRecords[0].Id; // Return the updated record ID
            }
        } 
        else {
            //  System.debug('Permission Check: false');
            return null; // Return null if neither creatable nor updatable
        }
        //System.debug('Permissions denied.');
        return null; // Return null if permissions are insufficient
    }
    
    
    @AuraEnabled
    public static List<Assessment_Question__c> saveQuestions(String assessmentId, String quesData, String editAssessmentId, List<String> aqToBeDeleted) {
        List<Object> fullMap = (List<Object>) JSON.deserializeUntyped(quesData);
        System.debug('fullMap >> ' + fullMap);
        List<Assessment_Question__c> assessQuesList = new List<Assessment_Question__c>();
        Map<String, Map<String, List<String>>> parentQuesAnsOpDepQueslevel1Map = new Map<String, Map<String, List<String>>>();
        Map<String, Map<String, List<String>>> parentQuesAnsOpDepQueslevel2Map = new Map<String, Map<String, List<String>>>();
        Map<String, String> uniqueIdAssessQuesMap = new Map<String, String>();
        // Process main questions and dependencies
        for (Object obj : fullMap) {
            Map<String, Object> questionData = (Map<String, Object>) obj;
            Assessment_Question__c mainQuestion = processMainQuestion(assessmentId, questionData);
            assessQuesList.add(mainQuestion);
            // Process level 1 dependencies
            processDependencies(assessmentId, questionData, mainQuestion, parentQuesAnsOpDepQueslevel1Map, parentQuesAnsOpDepQueslevel2Map, assessQuesList);
        }
        // Upsert questions with security check
        if(!assessQuesList.isEmpty()){
            upsertAssessmentQuestions(assessQuesList);
        }
        // Build unique ID map
        if(String.isNotBlank(assessmentId)){
            uniqueIdAssessQuesMap = buildUniqueIdMap(assessmentId);
        }
        // Handle dependency relationships
        List<Dependent_Question__c> allDependencies = new List<Dependent_Question__c>();
        allDependencies.addAll(createDependencies(parentQuesAnsOpDepQueslevel1Map, uniqueIdAssessQuesMap, assessmentId));
        allDependencies.addAll(createDependencies(parentQuesAnsOpDepQueslevel2Map, uniqueIdAssessQuesMap, assessmentId));
        // Cleanup existing dependencies if editing
        if (String.isNotBlank(editAssessmentId)) {
            deleteExistingDependencies(editAssessmentId);
        }
        // Insert new dependencies
        if(!allDependencies.isempty()){
            insertDependencies(allDependencies);
        }
        // Cleanup deleted questions
        if(!aqToBeDeleted.isempty()){
            deleteQuestions(aqToBeDeleted);
        }
        return assessQuesList;
    }
    
    // Helper method to process main question
    private static Assessment_Question__c processMainQuestion(String assessmentId, Map<String, Object> questionData) {
        try{
            Assessment_Question__c q = new Assessment_Question__c(
                Assessment__c = assessmentId,
                Question__c = (Id) questionData.get('quesId'),
                Type__c = 'General',
                Section__c = (String) questionData.get('section'),
                Section_Sequence__c = questionData.get('sectionSequence') != null ? Decimal.valueOf((String) questionData.get('sectionSequence')) : null,
                Field_Update__c = (String) questionData.get('fieldname') ?? '',
                Score__c = (String) questionData.get('scorelist') ?? '',
                Max_Score__c = questionData.get('maxScore') != null ? Decimal.valueOf((Integer) questionData.get('maxScore')) : 0,
                Required__c =  questionData.get('required') != null ? (Boolean) questionData.get('required'): false ,
                Sequence__c = Decimal.valueOf((Integer) questionData.get('sfSeq')),
                unique_id__c = (String) questionData.get('unique')
            );
            if (String.isNotBlank((String) questionData.get('aqId'))) 
            {	
                q.Id = (Id) questionData.get('aqId');
            }
            return q;
        } 
        catch (Exception e) {
            System.debug('Error in processMainQuestion: ' + e.getMessage());
            throw new AuraHandledException('Error processing main question. Please check the input data.');
        }
    }
    
    // Helper method to process dependencies
    private static void processDependencies(String assessmentId, Map<String, Object> parentData, Assessment_Question__c parentQuestion, 
                                            Map<String, Map<String, List<String>>> level1Map, 
                                            Map<String, Map<String, List<String>>> level2Map, 
                                            List<Assessment_Question__c> assessQuesList) {
                                                
                                                try{
                                                    List<Object> level1Dependencies = (List<Object>) parentData.get('dependentQuesData');
                                                    if (level1Dependencies == null)
                                                    {
                                                        return;
                                                        
                                                    } 
                                                    
                                                    for (Object depObj : level1Dependencies) {
                                                        Map<String, Object> depData = (Map<String, Object>) depObj;
                                                        List<Object> depQuestions = (List<Object>) depData.get('dependentQuesList');
                                                        if (depQuestions == null) 
                                                        {
                                                            continue;
                                                        }
                                                        
                                                        String answerOptionId = (String) depData.get('ansOpId');
                                                        processDependencyLevel(assessmentId, depQuestions, parentQuestion, answerOptionId, level1Map, level2Map, assessQuesList);
                                                    }
                                                }
                                                catch (Exception e) {
                                                    System.debug('Error in processDependencies: ' + e.getMessage());
                                                    throw new AuraHandledException('Error processing dependencies.');
                                                }
                                                
                                            }
    
    // Helper method to process dependency levels
    private static void processDependencyLevel(String assessmentId, List<Object> depQuestions, 
                                               Assessment_Question__c parentQuestion, String answerOptionId,
                                               Map<String, Map<String, List<String>>> parentMap,
                                               Map<String, Map<String, List<String>>> childMap,
                                               List<Assessment_Question__c> assessQuesList) {
                                                   
                                                   try{
                                                       for (Object quesObj : depQuestions) 
                                                       {
                                                           Map<String, Object> quesData = (Map<String, Object>) quesObj;
                                                           Assessment_Question__c depQuestion = createDependentQuestion(assessmentId, quesData);
                                                           assessQuesList.add(depQuestion);
                                                           
                                                           // Add to parent map
                                                           if (!parentMap.containsKey(parentQuestion.unique_id__c)) {
                                                               parentMap.put(parentQuestion.unique_id__c, new Map<String, List<String>>());
                                                           }
                                                           if (!parentMap.get(parentQuestion.unique_id__c).containsKey(answerOptionId)) {
                                                               parentMap.get(parentQuestion.unique_id__c).put(answerOptionId, new List<String>());
                                                           }
                                                           parentMap.get(parentQuestion.unique_id__c).get(answerOptionId).add(depQuestion.unique_id__c);
                                                           
                                                           // Process nested dependencies
                                                           List<Object> nestedDeps = (List<Object>) quesData.get('dependentQuesData');
                                                           if (nestedDeps != null) {
                                                               for (Object nestedDepObj : nestedDeps) {
                                                                   Map<String, Object> nestedDepData = (Map<String, Object>) nestedDepObj;
                                                                   List<Object> nestedDepQuestions = (List<Object>) nestedDepData.get('dependentQuesList');
                                                                   if (nestedDepQuestions != null) {
                                                                       processDependencyLevel(assessmentId, nestedDepQuestions, depQuestion, 
                                                                                              (String) nestedDepData.get('ansOpId'), childMap, null, assessQuesList);
                                                                   }
                                                               }
                                                           }
                                                       }
                                                   }
                                                   catch (Exception e) {
                                                       System.debug('Error in processDependencyLevel: ' + e.getMessage());
                                                       throw new AuraHandledException('Error processing dependency levels.');
                                                   }
                                               }
    
    // Helper to create dependent question
    private static Assessment_Question__c createDependentQuestion(String assessmentId, Map<String, Object> quesData) {
        try{
            Assessment_Question__c q = new Assessment_Question__c(
                Assessment__c = assessmentId,
                Question__c = (Id) quesData.get('quesId'),
                Type__c = 'Dependent',
                Dependent_Sequence__c = (String) quesData.get('sfSeq'),
                Required__c = quesData.get('required') != null?(Boolean) quesData.get('required') : false ,
                unique_id__c = (String) quesData.get('unique')
            );
            if (String.isNotBlank((String) quesData.get('aqId')))
            {
                q.Id = (Id) quesData.get('aqId');
            }
            
            return q;
        } 
        catch (Exception e) {
            System.debug('Error in createDependentQuestion: ' + e.getMessage());
            throw new AuraHandledException('Error createDependentQuestion.');
        }
    }
    
    // Helper to handle dependency creation
    private static List<Dependent_Question__c> createDependencies(Map<String, Map<String, List<String>>> dependencyMap, 
                                                                  Map<String, String> uniqueIdMap, String assessmentId) {
                                                                      try{                                                             
                                                                          List<Dependent_Question__c> dependencies = new List<Dependent_Question__c>();
                                                                          for (String parentUniqueId : dependencyMap.keySet()) {
                                                                              String parentId = uniqueIdMap.get(parentUniqueId);
                                                                              for (String answerOptionId : dependencyMap.get(parentUniqueId).keySet()) {
                                                                                  for (String depUniqueId : dependencyMap.get(parentUniqueId).get(answerOptionId)) {
                                                                                      dependencies.add(new Dependent_Question__c(
                                                                                          Assessment__c = assessmentId,
                                                                                          Parent_Question__c = parentId,
                                                                                          Dependent_Question__c = uniqueIdMap.get(depUniqueId),
                                                                                          Question_Answer_Option__c = answerOptionId
                                                                                      ));
                                                                                  }
                                                                              }
                                                                          }
                                                                          return dependencies;
                                                                      }
                                                                      catch (Exception e) {
                                                                          System.debug('Error in createDependencies: ' + e.getMessage());
                                                                          throw new AuraHandledException('Error createDependencies.');
                                                                      }
                                                                  }
    
    // Helper method to upsert questions
    private static void upsertAssessmentQuestions(List<Assessment_Question__c> questions) {
        try{
            List<Assessment_Question__c> decision = (List<Assessment_Question__c>) Security.stripInaccessible(AccessType.UPSERTABLE,questions,true).getRecords();
            if (!decision.isEmpty() && 
                Schema.sObjectType.Assessment_Question__c.isCreateable() && 
                Schema.sObjectType.Assessment_Question__c.isUpdateable()) {
                    upsert as user decision; // Maintain user context
                }
        }
        catch (DmlException e) {
            System.debug('DML Exception in upsertAssessmentQuestions: ' + e.getMessage());
            throw new AuraHandledException('Error saving assessment questions.');
        }
        catch (Exception e) {
            System.debug('Error in upsertAssessmentQuestions: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while saving assessment questions.');
        }     
        
    }
    
    // Helper to build unique ID map
    private static Map<String, String> buildUniqueIdMap(String assessmentId) {
        try{
            Map<String, String> uniqueIdMap = new Map<String, String>();
            List<Assessment_Question__c> aqList = [SELECT Id, unique_id__c FROM Assessment_Question__c WHERE Assessment__c = :assessmentId WITH SECURITY_ENFORCED];
            for (Assessment_Question__c aq : aqList) {
                uniqueIdMap.put(aq.unique_id__c, aq.Id);
            }
            return uniqueIdMap;
        }catch (Exception e) {
            System.debug('Error in buildUniqueIdMap: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while buildUniqueIdMap.');
        }     
    }
    
    // Helper to delete existing dependencies
    private static void deleteExistingDependencies(String assessmentId) {
        try{
            List<Dependent_Question__c> deletableRec = [SELECT Id FROM Dependent_Question__c WHERE Assessment__c = :assessmentId WITH SECURITY_ENFORCED];
            if(!deletableRec.isEmpty()) {
                if(Dependent_Question__c.sObjectType.getDescribe().isDeletable()){
                    delete as user deletableRec;
                }
            }
        }catch (DmlException e) {
            System.debug('DML Exception in deleteExistingDependencies: ' + e.getMessage());
            throw new AuraHandledException('Error deleting existing dependencies.');
        } catch (Exception e) {
            System.debug('Error in deleteExistingDependencies: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while deleting dependencies.');
        }   
    }
    
    // Helper to insert dependencies
    private static void insertDependencies(List<Dependent_Question__c> dependencies) {
        try{
            List<Dependent_Question__c> decision = (List<Dependent_Question__c>)Security.stripInaccessible(
                AccessType.CREATABLE,
                dependencies,
                true // enforce CRUD/FLS
            ).getRecords();
            if (decision.size()>0 && 
                Schema.sObjectType.Dependent_Question__c.isCreateable()) {
                    insert as user decision; // Maintain user context
                }
        }catch (DmlException e) {
            System.debug('DML Exception in insertDependencies: ' + e.getMessage());
            throw new AuraHandledException('Error inserting dependencies.');
        } catch (Exception e) {
            System.debug('Error in insertDependencies: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while inserting dependencies.');
        }   
    }
    
    // Helper to delete questions
    private static void deleteQuestions(List<String> questionIds) {
        try{
            List<Assessment_Question__c> deletableRec = [SELECT Id FROM Assessment_Question__c 
                                                         WHERE Id IN :questionIds 
                                                         WITH SECURITY_ENFORCED];
            if (deletableRec != null && deletableRec.size()>0 && 
                Assessment_Question__c.sObjectType.getDescribe().isDeletable()) {
                    delete as user deletableRec;
                    
                }
        }catch (DmlException e) {
            System.debug('DML Exception in deleteQuestions: ' + e.getMessage());
            throw new AuraHandledException('Error deleting questions.');
        } catch (Exception e) {
            System.debug('Error in deleteQuestions: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while deleting questions.');
        }
    }
    
    
    @AuraEnabled
    public static void updateJsonData(List<caresp__Assessment__c> assessmentList){
        assessmentList = (List<caresp__Assessment__c>)Security.stripInaccessible(AccessType.UPDATABLE, assessmentList).getRecords();
        if (assessmentList.size()>0 && 
            Schema.sObjectType.caresp__Assessment__c.isUpdateable()) {//added by sg
                update as user assessmentList;
            }
    }
    
    @AuraEnabled
    public static void createScoringRecords(List<Scoring__c> scoringList, String editAssessmentId){
        List<Scoring__c> scrList = [select Id from Scoring__c where Assessment__c =: editAssessmentId WITH SECURITY_ENFORCED];
        if(scrList.size()>0 && 
           Scoring__c.sObjectType.getDescribe().isDeletable()){
               delete as user scrList ;
           }
        scoringList = (List<Scoring__c>)Security.stripInaccessible(AccessType.CREATABLE, scoringList).getRecords();
        if (scoringList.size()>0 && 
            Schema.sObjectType.caresp__Scoring__c.isCreateable()) {//added by sg
                insert as user scoringList;
            }
    }
    
    @AuraEnabled
    public static void updateCompletionFieldData(String assessmentId, String field, String fieldValue){
        System.debug('Assessment ID >> '+assessmentId);
        System.debug('field >> '+field);
        System.debug('fieldValue >> '+fieldValue);
        List<caresp__Assessment__c> assessmenListUpdatable = new List<caresp__Assessment__c>();
        assessmenListUpdatable = (List<caresp__Assessment__c>)Security.stripInaccessible(AccessType.UPDATABLE,  new List<Assessment__c>{new caresp__Assessment__c(Id=assessmentId, caresp__On_Completion_Field_Update__c=field, caresp__On_Completion_Field_Value__c=fieldValue)}).getRecords();
        if (assessmenListUpdatable.size()>0 && 
            Schema.sObjectType.caresp__Assessment__c.isCreateable() &&
            Schema.sObjectType.caresp__Assessment__c.isUpdateable()) {//added by sg
                update as user assessmenListUpdatable;
                
                // update (new Assessment__c(Id=assessmentId, On_Completion_Field_Update__c=field, On_Completion_Field_Value__c=fieldValue));
            }
    }
    
    public class FieldValueWrapper{
        @AuraEnabled public String fieldType;
        @AuraEnabled public List<ObjectsWrapper> fieldValueList;
    }
    
    public class ObjectsWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public objectsWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
    
    public class QuestionsWrapper{
        String quesId;
        String quesText;
        String dataType;
        String ansOps;
        List<caresp__Question_Answer_Option__c> quesAnsOpList;
        
        public QuestionsWrapper(String quesId, String quesText, String dataType, String ansOps, List<caresp__Question_Answer_Option__c> quesAnsOpList){
            this.quesId = quesId;
            this.quesText = quesText;
            this.dataType = dataType;
            this.ansOps = ansOps;
            this.quesAnsOpList = quesAnsOpList;
        }
    }
}