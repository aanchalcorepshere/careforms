public with sharing class AssessmentWizardController { // NOPMD
    public AssessmentWizardController() {
        
    }
    
    
    // Checks if an assessment name already exists, excluding the given ID if provided
    @AuraEnabled
    public static String checkAssessmentNameDuplicate(String assessmentName, String assessmentId) {
        String resp = '';
        List<caresp__Assessment__c> assessmentList = new List<caresp__Assessment__c>();
        System.debug(LoggingLevel.Error, 'assessmentId >> ' + assessmentId);
        if (String.isNotBlank(assessmentId)) {
            assessmentList = [SELECT Id FROM caresp__Assessment__c WHERE Name = :assessmentName AND Id != :assessmentId WITH USER_MODE];
        } else {
            assessmentList = [SELECT Id FROM caresp__Assessment__c WHERE Name = :assessmentName WITH USER_MODE];
        }
        
        if (assessmentList != null && assessmentList.size() > 0) {
            resp = 'Duplicate';
        }
        
        return resp;
    }
    // Checks if an assessment is linked to any outcome records, making it non-editable
    @AuraEnabled
    public static String checkAssessmentInUse(String assessmentId) {
        String resp = '';
        System.debug(LoggingLevel.Error, 'assessmentId >> ' + assessmentId);
        if (String.isNotBlank(assessmentId)) {
            List<caresp__Outcome__c> outcomeList = [
                SELECT Id 
                FROM caresp__Outcome__c 
                WHERE caresp__Assessment__c = :assessmentId 
                WITH USER_MODE
            ];
            
            if (outcomeList != null && outcomeList.size() > 0) {
                resp = 'non-editable';
            }
        }
        
        return resp;
    }

    // Retrieves creatable Salesforce object names excluding system and metadata objects
    @AuraEnabled(cacheable = true)
    public static String getObjectNames() {
        List<ObjectsWrapper> objectsWrapperList = new List<ObjectsWrapper>();   
        for (Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()) {
            Schema.DescribeSObjectResult describeSObjectResultObj = objTyp.getDescribe();
            if (describeSObjectResultObj.isCreateable() && describeSObjectResultObj.isAccessible()) {
                String name = objTyp.getDescribe().getName();
                String label = objTyp.getDescribe().getLabel();
                // Exclude all the unwanted SObjects e.g., History, Share, Tag, Feed, ChangeEvent
                if (!name.containsignorecase('history') && 
                    !name.containsignorecase('tag') &&
                    !name.containsignorecase('share') && 
                    !name.containsignorecase('feed') && 
                    !name.containsignorecase('changeevent')) {
                        objectsWrapperList.add(new ObjectsWrapper(label + ' (' + name + ')', name));
                }   
            }
        }
        
        return JSON.serialize(objectsWrapperList);
    }
    
    // Returns all creatable custom text or textarea fields for a given object as JSON
    @AuraEnabled
    public static String getCompatibleFields(String objName) {
        Set<ObjectsWrapper> objectsWrapperList = new Set<ObjectsWrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (
                fieldDescribe.isCustom() == true &&
                fieldDescribe.isCreateable() == true &&
                fieldDescribe.isAccessible() == true &&
                (String.valueOf(fieldDescribe.getType()) == 'STRING' ||
                 String.valueOf(fieldDescribe.getType()) == 'TEXTAREA')
            ) {
                objectsWrapperList.add(
                    new ObjectsWrapper(fieldDescribe.getLabel() + '(' + objName + ')', fieldName)
                );
            }
        }
        
        return JSON.serialize(objectsWrapperList);
    }

    // Returns all creatable boolean or picklist fields for multiple given objects
    @AuraEnabled
    public static List<ObjectsWrapper> getCompatibleFieldsBoolPick(List<String> objNames) {
        List<ObjectsWrapper> objectsWrapperList = new List<ObjectsWrapper>();
        for (String type : objNames) {
            
            System.debug(LoggingLevel.Error, 'Type >> ' + type);
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if (!schemaMap.containsKey(type)) { 
                System.debug(LoggingLevel.Error, 'Invalid SObject type: ' + type);
                throw new AuraHandledException('Invalid SObject type: ' + type);
            }
            Schema.SObjectType leadSchema = schemaMap.get(type);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                if (
                    fieldDescribe.isCreateable() == true &&
                    (String.valueOf(fieldDescribe.getType()) == 'BOOLEAN' ||
                     String.valueOf(fieldDescribe.getType()) == 'PICKLIST')
                ) 
                {
                    objectsWrapperList.add(
                        new ObjectsWrapper(fieldDescribe.getLabel() + '(' + type + ')', type + '|' + fieldName)
                    );
                }
            }
        }
        
        return objectsWrapperList;
    }

    // Retrieves the field type and (if picklist) possible values for a given object field
    @AuraEnabled
    public static FieldValueWrapper getFieldTypeAndValues(String fieldValue) {
        
        FieldValueWrapper wrp = new FieldValueWrapper();
        String objName = fieldValue.substringBefore('|');
        String fieldApi = fieldValue.substringAfter('|');
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Schema.SObjectType otype = gd.get(objName);
        Schema.DescribeSObjectResult describeSObjectResultObj = otype.getDescribe();
        if (describeSObjectResultObj.isAccessible()) 
        {
            Map<String, Schema.SObjectField> M = describeSObjectResultObj.fields.getMap();
            Schema.SObjectField field = M.get(fieldApi);
            if(field.getDescribe().isAccessible()){
                Schema.DisplayType FldType = field.getDescribe().getType();
        
                if (String.valueOf(FldType) == 'PICKLIST' || String.valueOf(FldType) == 'BOOLEAN') {
                    wrp.fieldType = String.valueOf(FldType);
                    
                    if (String.valueOf(FldType) == 'PICKLIST') {
                        List<ObjectsWrapper> fieldValues = new List<ObjectsWrapper>();
                        List<String> pickListValuesList = new List<String>();
                        Schema.DescribeFieldResult fieldResult = field.getDescribe();
                        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                        for (Schema.PicklistEntry pickListVal : ple) {
                            pickListValuesList.add(pickListVal.getLabel());
                            fieldValues.add(new ObjectsWrapper(pickListVal.getLabel(), pickListVal.getLabel()));
                        }
                        wrp.fieldValueList = fieldValues;
                    }
                }
            }
        }         
        return wrp;
    }
 
    // Retrieves all questions (with optional answer options) for selection and returns them as JSON
    @AuraEnabled(cacheable = true)
    public static String getQuestionsForSelection(Boolean isDependent) 
    {
        
        List<String> quesWithAnsOps = new List<String>();
        List<QuestionsWrapper> quesWrapperList = new List<QuestionsWrapper>();
        
        List<caresp__Question_Answer_Option__c> quesAnsOpList = new List<caresp__Question_Answer_Option__c>();
        
        Map<String, List<caresp__Question_Answer_Option__c>> quesAnsOpMap = new Map<String, List<caresp__Question_Answer_Option__c>>();
        
        List<caresp__Question__c> quesList = [SELECT Id, caresp__Active__c, caresp__Answer_Options__c, caresp__Question_Data_type__c, caresp__Question_Text__c, caresp__Question_Category__c FROM caresp__Question__c WITH USER_MODE LIMIT 40000];
        
        for(caresp__Question__c ques: quesList){
            if(ques.caresp__Question_Data_type__c == 'Radio Box' || ques.caresp__Question_Data_type__c == 'Picklist'){
                quesWithAnsOps.add(ques.Id);
            }
        }
        
        if(quesWithAnsOps!=null && quesWithAnsOps.size()>0){
            quesAnsOpList = [SELECT Id, caresp__Answer__c, caresp__Answer_Text__c, caresp__Question__c, caresp__Question_Text__c, caresp__Sequence__c 
                             FROM caresp__Question_Answer_Option__c 
                             WHERE caresp__Question__c IN :quesWithAnsOps 
                             WITH USER_MODE ORDER BY caresp__Sequence__c];
            
            for(caresp__Question_Answer_Option__c ansOp:quesAnsOpList){
                if(!quesAnsOpMap.containsKey(ansOp.caresp__Question__c)){
                    quesAnsOpMap.put(ansOp.caresp__Question__c, new List<caresp__Question_Answer_Option__c>());
                    quesAnsOpMap.get(ansOp.caresp__Question__c).add(ansOp);
                } else {
                    quesAnsOpMap.get(ansOp.caresp__Question__c).add(ansOp);
                }
            }
        }
        
        for(caresp__Question__c ques: quesList){
            quesWrapperList.add(
                new QuestionsWrapper(
                    ques.Id, 
                    ques.caresp__Question_Text__c, 
                    ques.caresp__Question_Data_type__c, 
                    ques.caresp__Answer_Options__c, 
                    quesAnsOpMap.get(ques.Id)!=null ? quesAnsOpMap.get(ques.Id) : null
                )
            );
        }
        
        return JSON.serialize(quesWrapperList);
    }

    // Retrieves assessment record for editing, including related JSON fields
    @AuraEnabled
    public static caresp__Assessment__c getEditJson(String assessmentId) {
        String sanitizedId = (assessmentId != null) ? 
        assessmentId.trim().replaceAll('[^a-zA-Z0-9]', '') : null;
        return [
            SELECT Id, caresp__Assessment_Detail_JSON__c, caresp__Field_Update_JSON__c, caresp__Questions_JSON__c, caresp__Scoring_JSON__c, caresp__Section_JSON__c 
            FROM caresp__Assessment__c 
            WHERE Id = :sanitizedId 
            WITH USER_MODE
        ];
    }
       
    
    
     // Creates or updates an Assessment record based on provided data and user permissions
    @AuraEnabled
    public static String createAssessmentRecord(String assessmentName, String description, Boolean active, String editAssessmentId, String objName) {
        caresp__Assessment__c newAssessment = new caresp__Assessment__c();
        System.debug(LoggingLevel.Error ,'editAssessmentId >> ' + editAssessmentId);
    
        if (String.isNotBlank(editAssessmentId)) {
            newAssessment.Id = editAssessmentId; // Updating an existing record
        }
    
        // Populate fields
        newAssessment.Name = assessmentName;
        newAssessment.caresp__active__c = active;
        newAssessment.caresp__Assessment_Description__c = description;
        newAssessment.caresp__Object__c = String.isNotBlank(objName) ? objName : '';
    
        if (Schema.sObjectType.caresp__Assessment__c.isCreateable() || Schema.sObjectType.caresp__Assessment__c.isUpdateable()) {
            System.debug('Permission Check: true');
    
            // Insert (creatable case)
            if (Schema.sObjectType.caresp__Assessment__c.isCreateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.Name.isCreateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__active__c.isCreateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__Assessment_Description__c.isCreateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__Object__c.isCreateable() &&
                newAssessment.Id == null) {
    
                List<caresp__Assessment__c> creatableRecords = Security.stripInaccessible(
                    AccessType.CREATABLE,
                    new List<caresp__Assessment__c>{ newAssessment }
                ).getRecords();
    
                insert as user creatableRecords;
                System.debug(LoggingLevel.Error ,'Insert successful. ID: ' + creatableRecords[0].Id);
                return creatableRecords[0].Id;
            } 
            // Update (updatable case)
            else if (newAssessment.Id != null &&
                Schema.sObjectType.caresp__Assessment__c.isUpdateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.Name.isUpdateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__active__c.isUpdateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__Assessment_Description__c.isUpdateable() &&
                Schema.sObjectType.caresp__Assessment__c.fields.caresp__Object__c.isUpdateable()) {
    
                List<caresp__Assessment__c> updatableRecords = Security.stripInaccessible(
                    AccessType.UPDATABLE,
                    new List<caresp__Assessment__c>{ newAssessment }
                ).getRecords();
    
                update as user updatableRecords;
                System.debug(LoggingLevel.Error ,'Update successful. ID: ' + updatableRecords[0].Id);
                return updatableRecords[0].Id;
            }
        } 
        else {
            return null; // No permissions
        }
    
        return null; // Default return if no operation occurred
    }
     
     
    // Saves main and dependent assessment questions, updates dependencies, and deletes removed questions
    @AuraEnabled
    public static List<caresp__Assessment_Question__c> saveQuestions(String assessmentId, String quesData, String editAssessmentId, List<String> aqToBeDeleted) {
        List<Object> fullMap = (List<Object>) JSON.deserializeUntyped(quesData);
        System.debug(LoggingLevel.Error ,'fullMap >> ' + fullMap);
        List<caresp__Assessment_Question__c> assessQuesList = new List<caresp__Assessment_Question__c>();
        Map<String, Map<String, List<String>>> parentQuesAnsOpDepQueslevel1Map = new Map<String, Map<String, List<String>>>();
        Map<String, Map<String, List<String>>> parentQuesAnsOpDepQueslevel2Map = new Map<String, Map<String, List<String>>>();
        Map<String, String> uniqueIdAssessQuesMap = new Map<String, String>();
    
        // Process main questions and dependencies
        for (Object obj : fullMap) {
            Map<String, Object> questionData = (Map<String, Object>) obj;
            caresp__Assessment_Question__c mainQuestion = processMainQuestion(assessmentId, questionData);
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
        List<caresp__Dependent_Question__c> allDependencies = new List<caresp__Dependent_Question__c>();
        allDependencies.addAll(createDependencies(parentQuesAnsOpDepQueslevel1Map, uniqueIdAssessQuesMap, assessmentId));
        allDependencies.addAll(createDependencies(parentQuesAnsOpDepQueslevel2Map, uniqueIdAssessQuesMap, assessmentId));
    
        // Cleanup existing dependencies if editing
        if (String.isNotBlank(editAssessmentId)) {
            deleteExistingDependencies(editAssessmentId);
        }
    
        // Insert new dependencies
        if(!allDependencies.isEmpty()){
            insertDependencies(allDependencies);
        }
    
        // Cleanup deleted questions
        if(!aqToBeDeleted.isEmpty()){
            deleteQuestions(aqToBeDeleted);
        }
        
        return assessQuesList;
    }

   
    // Helper method to process main question
    private static Assessment_Question__c processMainQuestion(String assessmentId, Map<String, Object> questionData) {
        try{
            caresp__Assessment_Question__c q = new caresp__Assessment_Question__c(
                caresp__Assessment__c = assessmentId,
                caresp__Question__c = (Id) questionData.get('quesId'),
                caresp__Type__c = 'General',
                caresp__Section__c = (String) questionData.get('section'),
                caresp__Section_Sequence__c = questionData.get('sectionSequence') != null ? Decimal.valueOf((String) questionData.get('sectionSequence')) : null,
                caresp__Field_Update__c = (String) questionData.get('fieldname') ?? '',
                caresp__Score__c = (String) questionData.get('scorelist') ?? '',
                caresp__Max_Score__c = questionData.get('maxScore') != null ? Decimal.valueOf((Integer) questionData.get('maxScore')) : 0,
                caresp__Required__c =  questionData.get('required') != null ? (Boolean) questionData.get('required'): false ,
                caresp__Sequence__c = Decimal.valueOf((Integer) questionData.get('sfSeq')),
                caresp__unique_id__c = (String) questionData.get('unique')
            );
            if (String.isNotBlank((String) questionData.get('aqId'))) 
            {	
                q.Id = (Id) questionData.get('aqId');
            }
            return q;
        } 
        catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in processMainQuestion: ' + e.getMessage());
            throw new AuraHandledException('Error processing main question. Please check the input data.');
        }
    }
    
    // Helper method to process dependencies
    private static void processDependencies(String assessmentId, Map<String, Object> parentData, Assessment_Question__c parentQuestion, 
                                            Map<String, Map<String, List<String>>> level1Map, 
                                            Map<String, Map<String, List<String>>> level2Map, 
                                            List<Assessment_Question__c> assessQuesList) 
    {
                                                
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
            System.debug(LoggingLevel.Error ,'Error in processDependencies: ' + e.getMessage());
            throw new AuraHandledException('Error processing dependencies.');
        }
                                                
    }
    
    // Helper method to process dependency levels
    private static void processDependencyLevel(String assessmentId, List<Object> depQuestions, 
                                               Assessment_Question__c parentQuestion, String answerOptionId,
                                               Map<String, Map<String, List<String>>> parentMap,
                                               Map<String, Map<String, List<String>>> childMap,
                                               List<Assessment_Question__c> assessQuesList) 
    {
                                                   
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
            System.debug(LoggingLevel.Error ,'Error in processDependencyLevel: ' + e.getMessage());
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
            System.debug(LoggingLevel.Error ,'Error in createDependentQuestion: ' + e.getMessage());
            throw new AuraHandledException('Error createDependentQuestion.');
        }
    }
    
    // Helper to handle dependency creation
    private static List<Dependent_Question__c> createDependencies(Map<String, Map<String, List<String>>> dependencyMap, 
                                                                  Map<String, String> uniqueIdMap, String assessmentId) 
    {
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
            System.debug(LoggingLevel.Error ,'Error in createDependencies: ' + e.getMessage());
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
            System.debug(LoggingLevel.Error ,'DML Exception in upsertAssessmentQuestions: ' + e.getMessage());
            throw new AuraHandledException('Error saving assessment questions.');
        }
        catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in upsertAssessmentQuestions: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while saving assessment questions.');
        }     
        
    }
    
    // Helper to build unique ID map
    private static Map<String, String> buildUniqueIdMap(String assessmentId) {
        try{
            Map<String, String> uniqueIdMap = new Map<String, String>();
            List<Assessment_Question__c> aqList = [SELECT Id, unique_id__c FROM Assessment_Question__c WHERE Assessment__c = :assessmentId WITH USER_MODE];
            for (Assessment_Question__c aq : aqList) {
                uniqueIdMap.put(aq.unique_id__c, aq.Id);
            }
            return uniqueIdMap;
        }catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in buildUniqueIdMap: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while buildUniqueIdMap.');
        }     
    }
    
    // Helper to delete existing dependencies
    private static void deleteExistingDependencies(String assessmentId) {
        try{
            // SOQL injection prevention
       		 String cleanId = (assessmentId != null) ? assessmentId.trim().replaceAll('[^a-zA-Z0-9]', '') : null;
        
            List<Dependent_Question__c> deletableRec = [SELECT Id FROM Dependent_Question__c WHERE Assessment__c = :cleanId WITH USER_MODE];
            if(!deletableRec.isEmpty()) {
                Schema.DescribeSObjectResult descObj = Dependent_Question__c.sObjectType.getDescribe();
                if(descObj.isAccessible() && descObj.isDeletable() && 
                   descObj.fields.getMap().get('Id').getDescribe().isAccessible()) {
                    delete as user deletableRec;
                }
            }
        }catch (DmlException e) {
            System.debug(LoggingLevel.Error ,'DML Exception in deleteExistingDependencies: ' + e.getMessage());
            throw new AuraHandledException('Error deleting existing dependencies.');
        } catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in deleteExistingDependencies: ' + e.getMessage());
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
            System.debug(LoggingLevel.Error ,'DML Exception in insertDependencies: ' + e.getMessage());
            throw new AuraHandledException('Error inserting dependencies.');
        } catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in insertDependencies: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while inserting dependencies.');
        }   
    }
    
    // Helper to delete questions
    private static void deleteQuestions(List<String> questionIds) {
        try{
            List<String> cleanIds = new List<String>();
            for (String id : questionIds) {
                if (String.isNotBlank(id)) {
                    cleanIds.add(id.trim().replaceAll('[^a-zA-Z0-9]', ''));
                }
            }
            List<Assessment_Question__c> deletableRec = [SELECT Id FROM Assessment_Question__c 
                                                         WHERE Id IN :cleanIds 
                                                         WITH USER_MODE];
            
            Schema.DescribeSObjectResult descAssessQuesObj = Assessment_Question__c.sObjectType.getDescribe();
            if (deletableRec != null && deletableRec.size()>0 && 
                descAssessQuesObj.isDeletable() &&
                descAssessQuesObj.isAccessible()) {
                    delete as user deletableRec;
                    
                }
        }catch (DmlException e) {
            System.debug(LoggingLevel.Error ,'DML Exception in deleteQuestions: ' + e.getMessage());
            throw new AuraHandledException('Error deleting questions.');
        } catch (Exception e) {
            System.debug(LoggingLevel.Error ,'Error in deleteQuestions: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error while deleting questions.');
        }
    }
    
    
    // Updates assessment records with stripped inaccessible fields
    @AuraEnabled
    public static void updateJsonData(List<caresp__Assessment__c> assessmentList) {
        assessmentList = (List<caresp__Assessment__c>)Security.stripInaccessible(AccessType.UPDATABLE, assessmentList).getRecords();
        if (assessmentList.size() > 0 && 
            Schema.sObjectType.caresp__Assessment__c.isUpdateable()) { //added by sg
                update as user assessmentList;
            }
    }

    // Creates scoring records after deleting any existing ones for the given assessment
    @AuraEnabled
    public static void createScoringRecords(List<Scoring__c> scoringList, String editAssessmentId) {
        Id cleanId = Id.valueOf(editAssessmentId);
        List<Scoring__c> scrList = [SELECT Id FROM Scoring__c WHERE Assessment__c = :cleanId WITH User_Mode];
        if (scrList.size() > 0 && 
            Scoring__c.sObjectType.getDescribe().isAccessible() &&
           Scoring__c.sObjectType.getDescribe().isDeletable() ) {
               delete as user scrList;
           }
        scoringList = (List<Scoring__c>)Security.stripInaccessible(AccessType.CREATABLE, scoringList).getRecords();
        if (scoringList.size() > 0 && 
            Schema.sObjectType.caresp__Scoring__c.isCreateable()) { //added by sg
                insert as user scoringList;
            }
    }

    // Updates completion field data for a given assessment
    @AuraEnabled
    public static void updateCompletionFieldData(String assessmentId, String field, String fieldValue) {
        System.debug(LoggingLevel.Error ,'Assessment ID >> ' + assessmentId);
        System.debug(LoggingLevel.Error ,'field >> ' + field);
        System.debug(LoggingLevel.Error ,'fieldValue >> ' + fieldValue);
        
        String cleanId = assessmentId.trim().replaceAll('[^a-zA-Z0-9]', '');
        String cleanField = field.trim().replaceAll('[^a-zA-Z0-9_]', '');
        String cleanValue = (fieldValue != null) ? 
            fieldValue.replaceAll('(?i)<script[^>]*>.*?</script>', '') : null;
        
        List<caresp__Assessment__c> assessmenListUpdatable = new List<caresp__Assessment__c>();
        assessmenListUpdatable = (List<caresp__Assessment__c>)Security.stripInaccessible(AccessType.UPDATABLE,  
            new List<Assessment__c>{new caresp__Assessment__c(Id = cleanId, caresp__On_Completion_Field_Update__c = cleanField, caresp__On_Completion_Field_Value__c = cleanValue)}).getRecords();
        if (assessmenListUpdatable.size() > 0 && 
            Schema.sObjectType.caresp__Assessment__c.isCreateable() &&
            Schema.sObjectType.caresp__Assessment__c.isUpdateable()) { //added by sg
                update as user assessmenListUpdatable;
        }
    }

    // Wrapper class to hold field type and associated list of object values
    public class FieldValueWrapper {
        @AuraEnabled public String fieldType;
        @AuraEnabled public List<ObjectsWrapper> fieldValueList;
    }

    
  // Wrapper class to store label-value pairs for objects
    public class ObjectsWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    
        // Constructor to initialize the ObjectsWrapper with label and value
        public ObjectsWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    // Wrapper class to store question details along with its answer options
    public class QuestionsWrapper {
        String quesId;
        String quesText;
        String dataType;
        String ansOps;
        List<caresp__Question_Answer_Option__c> quesAnsOpList;
    
        // Constructor to initialize all fields of the QuestionsWrapper
        public QuestionsWrapper(String quesId, String quesText, String dataType, String ansOps, List<caresp__Question_Answer_Option__c> quesAnsOpList) {
            this.quesId = quesId;
            this.quesText = quesText;
            this.dataType = dataType;
            this.ansOps = ansOps;
            this.quesAnsOpList = quesAnsOpList;
        }
}
 
}