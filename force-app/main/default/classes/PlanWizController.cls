public with sharing class PlanWizController
{
    Public Static Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfigGlobal;
    
    
    @AuraEnabled(cacheable=true)
    public static sObject getUserDetails(Id userId) {
        
        
        try {
            
            
            // Fetch the user details with safe SOQL
            User loggedUser = [SELECT Id, FirstName, LastName, Name, Profile.Name, Profile.UserType, Profile.UserLicense.Name 
                               FROM User 
                               WHERE Id = :userId WITH SECURITY_ENFORCED
                               LIMIT 1];
            
            
            return loggedUser;
        } catch (Exception ex) {
            // Log the exception
            System.debug('Exception occurred in getUserDetails: ' + ex.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static SObject getParentObjRec(String parentObjName, String recordId) {
        try {
            System.debug('parentObjName>>> ' + parentObjName + ' recordId>>> ' + recordId);
            
            // Retrieve field names for the given object
            List<String> fieldNames = getFieldNames(parentObjName);
            System.debug('fieldNames>>> ' + fieldNames);
            
            // Construct and execute the SOQL query safely
            String soqlQuery = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + String.escapeSingleQuotes(parentObjName) + ' WHERE Id = :escapedRecordId WITH SECURITY_ENFORCED LIMIT 1';
            String escapedRecordId = String.escapeSingleQuotes(recordId);
            System.debug('soqlQueryParentObj>>> ' + soqlQuery);
            List<SObject> results = Database.query(soqlQuery.replace(':escapedRecordId', '\'' + escapedRecordId + '\''));
            
            // Handle no results
            if (results.isEmpty()) {
                throw new AuraHandledException('No record found for the provided ID.');
            }
            
            // Return the first record
            SObject parentRecord = results[0];
            System.debug('parentRecord>>>' + parentRecord);
            return parentRecord;
        } catch (QueryException qe) {
            // Handle specific query exceptions
            System.debug('QueryException occurred in getParentObjRec: ' + qe.getMessage());
            throw new AuraHandledException('An error occurred while querying the database: ' + qe.getMessage());
        } catch (Exception ex) {
            // Handle general exceptions
            System.debug('Exception occurred in getParentObjRec: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + ex.getMessage());
        }
    }
    
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static caresp__Plan__c getPlan(String asID, Boolean fromPlan, String planId) {
        
        
        // Check if the current user has permission to access Plan__c records
        if (!Schema.sObjectType.caresp__Plan__c.isAccessible()) {
            return null;
        }
        
        caresp__Plan__c plan = new caresp__Plan__c();
        System.debug('recId: ' + asID + ', fromPlan: ' + fromPlan + ', planId: ' + planId);
        
        try {
            // Query the Plan__c record
            plan = [SELECT Id, Name, Plan_Type_F__c, Field_Blueprint_JSON__c, Case__c, Plan_Signed_Date__c, Plan_Version__c, Plan_Status__c, Parent_Plan__c, Plan_Start_Date__c, Progress_Status__c 
                    FROM Plan__c 
                    WHERE Id = :planId WITH SECURITY_ENFORCED
                    LIMIT 1];
            
            // Check if the current user has permission to view this specific record
            if (!hasReadAccess(plan)) {
                return null;
            }
            
            System.debug(plan);
            return plan;
        } catch (QueryException qe) {
            // Handle known query exceptions separately
            System.debug('QueryException occurred in getPlan: ' + qe.getMessage());
            return null;
        } catch (Exception ex) {
            // Log and handle unexpected exceptions
            System.debug('Exception occurred in getPlan: ' + ex.getMessage());
            return null;
        }
    }
    
    
    // Method to check if the current user has read access to a specific record
    private static Boolean hasReadAccess(SObject record) {
        // Check if the record is not null
        if (record == null) {
            return false;
        }
        
        // Retrieve the object type and the record Id
        String objectType = record.getSObjectType().getDescribe().getName();
        // Use a dynamic SOQL query to check CRUD permissions
        String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(objectType) + ' WHERE Id = :recordId LIMIT 1';
        Id recordId = String.escapeSingleQuotes(record.Id);
        List<SObject> result = Database.query(query.replace(':recordId', '\'' + recordId + '\''));
        // Return true if the user has access to the record, false otherwise
        return !result.isEmpty();
    }    
    
    
    
    @AuraEnabled
    public static String getImperativePlan(Id planId) {
        
        
        // Check if the current user has permission to access Plan__c records
        if (!Schema.sObjectType.caresp__Plan__c.isAccessible()) {
            return null;
        }
        
        try {
            // Query the Plan__c record
            caresp__Plan__c plan = [SELECT Id, Progress_Status__c 
                                    FROM Plan__c 
                                    WHERE Id = :planId WITH SECURITY_ENFORCED
                                    LIMIT 1];
            
            // Check if the current user has permission to view this specific record
            if (!hasReadAccess(plan)) {
                return null;
            }
            
            // Return the Progress_Status__c field
            return plan.caresp__Progress_Status__c;
        } catch (QueryException qe) {
            // Handle known query exceptions separately
            System.debug('QueryException occurred in getImperativePlan: ' + qe.getMessage());
            return null;
        } catch (Exception ex) {
            // Log and handle unexpected exceptions
            System.debug('Exception occurred in getImperativePlan: ' + ex.getMessage());
            return null;
        }
    }
    
    
    
    public static List<String> getFieldNames(String objectName) {
        List<String> fieldNames = new List<String>();
        try {
            // Check if the object exists in the global describe map
            if (!Schema.getGlobalDescribe().containsKey(objectName)) {
                return null;
            }
            
            // Get object describe information
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            
            // Retrieve fields and filter by access
            Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                if (fieldDescribe.isAccessible()) {
                    fieldNames.add(fieldName);
                }
            }
        } catch (Exception e) {
            // Log detailed error information
            System.debug('Error in getQueryableFieldNames: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
        }
        return fieldNames;
        
    }
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<ServicePlanWizClientsWrapper> getClientsDynamically(String asID, Id planId, String objectApiName, Boolean isGoalNStepTempCreated) {   
        System.debug('asID>>' + asID);
        List<sObject> planRecList = new List<sObject>();
        String parentObjName;
        if(objectApiName == 'caresp__Plan__c') {
            List<String> fieldNames = getFieldNames('caresp__Plan__c');
            String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM caresp__Plan__c WHERE Id =: escapedAsId WITH SECURITY_ENFORCED';
            String escapedAsId = String.escapeSingleQuotes(asID);
            planRecList = Database.query(query.replace(':escapedAsId', '\'' + escapedAsId + '\''));
            parentObjName = (String.valueOf(planRecList[0].get('caresp__Parent_Child_Name__c'))).split('-')[0];
        } else {
            parentObjName = objectApiName;
        }
        
        Set<Id> setIdsChildsParentRec = new Set<Id>();
        List<ServicePlanWizClientsWrapper> listCW = new List<ServicePlanWizClientsWrapper>();
        List<sObject> finalFetchedDataChild = new List<sObject>();
        caresp__Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig = Test.isRunningTest()?testFactory.getParentObjConfigMdtPlans(parentObjName):
            [SELECT Label, caresp__Child_s_parent_Filter_Field_API_Name__c, caresp__Child_s_Parent_Obj_API_Name__c, caresp__Child_Filter_Field_API_Name__c, caresp__Child_Obj_API_Name__c, caresp__Goal_s_Filter_Field_API_Name__c, caresp__Is_Junction_Exist__c, caresp__Parent_Obj_API_Name__c, caresp__Object_Fields_To_Display_List__c, caresp__Wrapper_Field_List__c, caresp__Obj_fields_for_wrapper_fields__c, caresp__Filter_Filed_Name_Plan_Obj__c FROM caresp__Dynamic_Plan_Parent_Obj_Configuration__mdt WHERE caresp__Parent_Obj_API_Name__c =: parentObjName AND caresp__Is_Active__c = true WITH SECURITY_ENFORCED LIMIT 1];
        
        asID = objectApiName == 'caresp__Plan__c' ? String.valueOf(planRecList[0].get(planObjConfig.caresp__Filter_Filed_Name_Plan_Obj__c)): asID;
        planObjConfigGlobal = planObjConfig != null ? planObjConfig : null;
        String finalChildOfParent = (planObjConfig.caresp__Is_Junction_Exist__c != null && planObjConfig.caresp__Is_Junction_Exist__c) ? planObjConfig.caresp__Child_s_Parent_Obj_API_Name__c : planObjConfig.caresp__Child_Obj_API_Name__c;
        Map<String, Schema.SObjectField> fieldMapChild = new Map<String, Schema.SObjectField>();
        Map<String, ServicePlanWizClientsWrapper> mapChildIdToCWRec = new Map<String, ServicePlanWizClientsWrapper>();
        Map<String, List<ServicePlanWizClientsWrapper.Goals>> mapChildIdToGoals = new Map<String, List<ServicePlanWizClientsWrapper.Goals>>();
        Map<Id, List<ServicePlanWizClientsWrapper.Steps>> mapGoalIdSteps = new Map<Id, List<ServicePlanWizClientsWrapper.Steps>>();
        Set<Id> setGoalId = new Set<Id>();
        
        Map<String, Schema.SObjectField> allFieldsMap = Schema.getGlobalDescribe().get(planObjConfig.caresp__Child_Obj_API_Name__c).getDescribe().fields.getMap();
        System.debug('allFieldsMap>>> ' + allFieldsMap);
        
        for (String fieldName : allFieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = allFieldsMap.get(fieldName).getDescribe();
            if (fieldDescribe.isAccessible()) {
                fieldMapChild.put(fieldName, allFieldsMap.get(fieldName));
            }
        }
        
        String query = 'SELECT ' + String.Join(fieldMapChild.keySet(), ', ') + ' FROM ' + planObjConfig.caresp__Child_Obj_API_Name__c + ' WHERE ' + planObjConfig.caresp__Child_Filter_Field_API_Name__c + ' = :escapedAsId WITH SECURITY_ENFORCED ORDER BY Name';
        String escapedAsId = String.escapeSingleQuotes(asID);
        finalFetchedDataChild = Database.query(query.replace(':escapedAsId', '\'' + escapedAsId + '\''));
        
        ProcessJunctionObjReturnWrapper processJunctionObjReturnWrapper = processForJunctionObj(finalFetchedDataChild, planObjConfig);
        finalFetchedDataChild = processJunctionObjReturnWrapper.finalFetchedDataChild;
        setIdsChildsParentRec = processJunctionObjReturnWrapper.setIdsChildsParentRec;
        
        List<String> lstObjFieldForWrapperField = new list<String>();
        if(planObjConfig.caresp__Obj_fields_for_wrapper_fields__c != null) {
            lstObjFieldForWrapperField = planObjConfig.caresp__Obj_fields_for_wrapper_fields__c.split(',');
        }
        
        List<String> lstWrapperFieldName = new List<String>();
        if(planObjConfig.caresp__Wrapper_Field_List__c != null) {
            lstWrapperFieldName = planObjConfig.caresp__Wrapper_Field_List__c.split(',');
        }
        
        List<String> lstFieldToDisplay = new List<String>();
        if(planObjConfig.caresp__Object_Fields_To_Display_List__c != null) {
            lstFieldToDisplay = planObjConfig.caresp__Object_Fields_To_Display_List__c.split('-');
        }
        
        setIdsChildsParentRec.clear();
        
        ProcessJunctionObjReturnWrapper processJunctionObjReturnWrapper1 = prepareMapChildIdToCWRec(finalFetchedDataChild, lstWrapperFieldName, lstFieldToDisplay, planObjConfig, lstObjFieldForWrapperField);
        mapChildIdToCWRec = processJunctionObjReturnWrapper1.mapChildIdToCWRec;
        setIdsChildsParentRec = processJunctionObjReturnWrapper1.setIdsChildsParentRec;
        system.debug('mapChildIdToCWRec = >'+mapChildIdToCWRec);
        
        List<caresp__Goal__c> listGoals = new List<caresp__Goal__c>();
        Map<String, caresp__Goal__c> mapGoalIdToGoalRec = new Map<String, caresp__Goal__c>();
        String mdtQuery = 'select Id, caresp__Plan__c, Name, caresp__Description__c, caresp__Start_Date__c, caresp__Target_Date__c, caresp__Status__c, caresp__Goal_Type__c, caresp__Domain__c , ' + planObjConfig.caresp__Goal_s_Filter_Field_API_Name__c + ' from caresp__Goal__c where caresp__Plan__c = :escapedPlanId AND ' + planObjConfig.caresp__Goal_s_Filter_Field_API_Name__c + ' IN :setIdsChildsParentRecTemp WITH SECURITY_ENFORCED ORDER By CreatedDate';
        String escapedPlanId = String.escapeSingleQuotes(planId);
        String formattedIds = '(';
        for (String id : setIdsChildsParentRec) {
            formattedIds += '\'' + id + '\', ';
        }
        
        if (formattedIds.endsWith(', ')) {
            formattedIds = formattedIds.substring(0, formattedIds.length() - 2);
        }
        formattedIds += ')';
        
        System.debug('setIdsChildsParentRec>>> ' + (mdtQuery.replace(':escapedPlanId','\'' + escapedPlanId + '\'')).replace(':setIdsChildsParentRecTemp', formattedIds));
        listGoals = Database.query((mdtQuery.replace(':escapedPlanId','\'' + escapedPlanId + '\'')).replace(':setIdsChildsParentRecTemp', formattedIds));
        
        ProcessGoalsReturnWrapper processGoalsReturnWrapper = processGoalsDynamic(mapChildIdToGoals, planObjConfig, listGoals, setGoalId);
        mapChildIdToGoals = processGoalsReturnWrapper.mapChildIdToGoals;
        mapGoalIdToGoalRec = processGoalsReturnWrapper.mapGoalIdToGoalRec;   
        setGoalId = processGoalsReturnWrapper.setGoalId;     
        
        for(String childId : mapChildIdToCWRec.keySet()) {
            ServicePlanWizClientsWrapper servicePlanWizClientsWrapper = mapChildIdToCWRec.get(childId);
            List<ServicePlanWizClientsWrapper.Goals> listGoal = mapChildIdToGoals.get(childId);
            servicePlanWizClientsWrapper.put('listGoals', listGoal);
            mapChildIdToCWRec.put(childId, servicePlanWizClientsWrapper);
        }
        
        //Get Steps
        List<caresp__Step__c> listSteps = new List<caresp__Step__c>();
        listSteps = Database.query('select Id, Name, caresp__Type_of_Action__c, caresp__Step_Type__c, caresp__Goal__c, caresp__Description__c, caresp__Start_Date__c, caresp__Target_Date__c, caresp__Assigned_To__c, caresp__Status__c, caresp__Step_Num__c from caresp__Step__c where caresp__Goal__c IN :setGoalId WITH SECURITY_ENFORCED ORDER By caresp__Step_Num__c');
        mapGoalIdSteps = processStepsDynamic(mapGoalIdSteps, listSteps, planObjConfig, mapGoalIdToGoalRec);
        
        mapChildIdToCWRec = updateMapChildIdToCWRecWithStepList(mapChildIdToCWRec, mapChildIdToGoals, mapGoalIdSteps, listSteps);
        System.debug('mapChildIdToCWRec>>>' + mapChildIdToCWRec);
        return mapChildIdToCWRec.values();
    }
    
    
    Private static ProcessJunctionObjReturnWrapper prepareMapChildIdToCWRec(List<sObject> finalFetchedDataChild,List<String> lstWrapperFieldName, List<String> lstFieldToDisplay, Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig,  List<String> lstObjFieldForWrapperField)
    {
        Set<Id> setIdsChildsParentRec = new Set<Id>();
        Map<String, ServicePlanWizClientsWrapper> mapChildIdToCWRec = new Map<String, ServicePlanWizClientsWrapper>();
        for(sObject childRec : finalFetchedDataChild)
        {
            if( !setIdsChildsParentRec.contains(String.valueOf(childRec.get('Id'))))
            {
                List<String> listDisplayVal = new List<String>();    
                ServicePlanWizClientsWrapper servicePlanWizClientsWrapper = new ServicePlanWizClientsWrapper();
                setIdsChildsParentRec.add(String.valueOf(childRec.get('Id')));
                
                for(Integer i =0; i< lstWrapperFieldName.size(); i++)
                {
                    
                    servicePlanWizClientsWrapper.put(lstWrapperFieldName[i], String.valueOf(childRec.get(lstObjFieldForWrapperField[i])));
                    
                }
                
                for(String fldItem : lstFieldToDisplay)
                {
                    String displayVal = String.valueOf(childRec.get(fldItem));
                    if(displayVal != null && displayVal != '')
                    {
                        listDisplayVal.add(displayVal);
                        
                    }
                    
                    
                }
                servicePlanWizClientsWrapper.put('cDisplayName', String.Join(listDisplayVal, '-'));
                servicePlanWizClientsWrapper.put('isDischarged', true);
                servicePlanWizClientsWrapper.put('Id', String.valueOf(childRec.get('Id')));
                servicePlanWizClientsWrapper.put('goalFilterField', planObjConfig.Goal_s_Filter_Field_API_Name__c);
                servicePlanWizClientsWrapper.put('style', 'slds-box slds-m-top_x-small blueBackground');
                mapChildIdToCWRec.put(String.valueOf(childRec.get('Id')), servicePlanWizClientsWrapper);
                
            }
            
        }
        ProcessJunctionObjReturnWrapper processJunctionObjReturnWrapper = new ProcessJunctionObjReturnWrapper();
        processJunctionObjReturnWrapper.mapChildIdToCWRec = mapChildIdToCWRec;
        processJunctionObjReturnWrapper.setIdsChildsParentRec = setIdsChildsParentRec;
        return processJunctionObjReturnWrapper;
        
    }
    
    
    Private static Map<String, ServicePlanWizClientsWrapper> updateMapChildIdToCWRecWithStepList(Map<String, ServicePlanWizClientsWrapper> mapChildIdToCWRec,  Map<String, List<ServicePlanWizClientsWrapper.Goals>> mapChildIdToGoals, Map<Id, List<ServicePlanWizClientsWrapper.Steps>> mapGoalIdSteps, List<caresp__Step__c> listSteps)
    {
        if(listSteps.size()>0)
        {
            for(String childId : mapChildIdToCWRec.keySet())
            {
                ServicePlanWizClientsWrapper servicePlanWizClientsWrapper = mapChildIdToCWRec.get(childId);
                List<ServicePlanWizClientsWrapper.Goals> listGoal = mapChildIdToGoals.containsKey(childId) ? mapChildIdToGoals.get(childId) : new  List<ServicePlanWizClientsWrapper.Goals>();
                List<ServicePlanWizClientsWrapper.Goals> listGoalsUpdated = new List<ServicePlanWizClientsWrapper.Goals>();
                
                for(ServicePlanWizClientsWrapper.Goals goals : listGoal)
                {
                    
                    if(mapGoalIdSteps.get(String.valueOf(goals.goalId)) != null)
                    {
                        goals.listSteps = mapGoalIdSteps.get(goals.goalId);
                    }
                    listGoalsUpdated.add(goals);
                }
                servicePlanWizClientsWrapper.put('listGoals', listGoalsUpdated);
                mapChildIdToCWRec.put(childId, servicePlanWizClientsWrapper);
            }
        }
        return mapChildIdToCWRec;
        
    }
    
    Private static ProcessJunctionObjReturnWrapper processForJunctionObj(List<sObject> finalFetchedDataChild,Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig)
    {
        Set<Id> setIdsChildsParentRec = new Set<Id>();
        if(planObjConfig.Is_Junction_Exist__c)
        {
            if(finalFetchedDataChild != null && finalFetchedDataChild.size()>0)
            {
                for(sObject childRec :  finalFetchedDataChild)
                {
                    setIdsChildsParentRec.add(String.valueOf(childRec.get(planObjConfig.Child_s_parent_Filter_Field_API_Name__c)));
                }
            }     
            
            Map<String, Schema.SObjectField> fieldMapParentOfChild = new Map<String, Schema.SObjectField>();
            fieldMapParentOfChild = Schema.getGlobalDescribe().get(planObjConfig.Child_s_Parent_Obj_API_Name__c).getDescribe().fields.getMap();
            String query2 = 'SELECT ' + String.Join(fieldMapParentOfChild.keySet(), ',') + 'FROM planObjConfig.Child_s_Parent_Obj_API_Name__c WHERE Id IN: setIdsChildsParentRecTemp WITH SECURITY_ENFORCED ORDER BY Name';
            finalFetchedDataChild.clear();
            String formattedIds1 = '(';
            for (String id : setIdsChildsParentRec) {
                formattedIds1 += '\'' + id + '\', ';
            }
            // Remove the trailing comma and space, and add the closing parenthesis
            if (formattedIds1.endsWith(', ')) {
                formattedIds1 = formattedIds1.substring(0, formattedIds1.length() - 2);
            }
            formattedIds1 += ')';
            finalFetchedDataChild = Database.query(query2.replace(':setIdsChildsParentRecTemp', formattedIds1));      
        }
        ProcessJunctionObjReturnWrapper processJunctionObjReturnWrapper = new ProcessJunctionObjReturnWrapper();
        processJunctionObjReturnWrapper.finalFetchedDataChild = finalFetchedDataChild;
        processJunctionObjReturnWrapper.setIdsChildsParentRec = setIdsChildsParentRec;
        return processJunctionObjReturnWrapper;
        
    }
    
    
    
    
    Private class ProcessGoalsReturnWrapper
    {
        Private Map<String, List<ServicePlanWizClientsWrapper.Goals>> mapChildIdToGoals;
        private  Map<String, Goal__c> mapGoalIdToGoalRec;
        Private Set<Id> setGoalId;
    }
    
    Private class ProcessJunctionObjReturnWrapper
    {
        Private List<sObject> finalFetchedDataChild;
        private   Set<Id> setIdsChildsParentRec;
        Private Map<String, ServicePlanWizClientsWrapper> mapChildIdToCWRec;
    }
    
    Private static ProcessGoalsReturnWrapper processGoalsDynamic(Map<String, List<ServicePlanWizClientsWrapper.Goals>> mapChildIdToGoals, Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig, List<caresp__Goal__c> listGoals, Set<Id> setGoalId)
    {
        Map<String, Goal__c> mapGoalIdToGoalRec = new Map<String, Goal__c>();
        for (Goal__c goalItem : listGoals)
        {
            ServicePlanWizClientsWrapper.Goals goal = new ServicePlanWizClientsWrapper.Goals();
            List<ServicePlanWizClientsWrapper.Goals> listGoalForMap = mapChildIdToGoals.containsKey(String.valueOf(goalItem.get(planObjConfig.Goal_s_Filter_Field_API_Name__c))) ? mapChildIdToGoals.get(String.valueOf(goalItem.get(planObjConfig.Goal_s_Filter_Field_API_Name__c))) : new List<ServicePlanWizClientsWrapper.Goals>();
            setGoalId.add(String.valueOf(goalItem.Id));
            goal.goalId = goalItem.Id;
            // goal.clientId = goalItem.Client__c;
            goal.planId = goalItem.caresp__Plan__c;
            goal.goalName = goalItem.Name;
            goal.description = goalItem.caresp__Description__c;
            goal.startDate = (goalItem.caresp__Start_Date__c !=  null) ? goalItem.caresp__Start_Date__c.format() : null;
            goal.targetDate = (goalItem.caresp__Target_Date__c != null) ? goalItem.caresp__Target_Date__c.format() : null;
            goal.status = goalItem.caresp__Status__c;
            goal.goalType = goalItem.caresp__Goal_Type__c;
            goal.domain = goalItem.caresp__Domain__c;
            goal.isDeleteGoal = false;
            goal.clientGoalId = goalItem.get(planObjConfig.Goal_s_Filter_Field_API_Name__c) + '#' + goalItem.Id;
            listGoalForMap.add(goal);
            mapGoalIdToGoalRec.put(goalItem.Id, goalItem);
            mapChildIdToGoals.put(String.valueOf(goalItem.get(planObjConfig.Goal_s_Filter_Field_API_Name__c)), listGoalForMap);
        }
        
        ProcessGoalsReturnWrapper processGoalsReturnWrapper = new ProcessGoalsReturnWrapper();
        processGoalsReturnWrapper.mapChildIdToGoals = mapChildIdToGoals;
        processGoalsReturnWrapper.mapGoalIdToGoalRec = mapGoalIdToGoalRec;
        processGoalsReturnWrapper.setGoalId = setGoalId;
        return processGoalsReturnWrapper;
        
    }
    
    
    
    Private static Map<Id, List<ServicePlanWizClientsWrapper.Steps>> processStepsDynamic(Map<Id, List<ServicePlanWizClientsWrapper.Steps>> mapGoalIdSteps, List<caresp__Step__c> listSteps, Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig,  Map<String, Goal__c> mapGoalIdToGoalRec)
    {
        //Get Steps
        for (Step__c stepItem : listSteps)
        {
            ServicePlanWizClientsWrapper.Steps step = new ServicePlanWizClientsWrapper.Steps();
            List<ServicePlanWizClientsWrapper.Steps> listStepForMap = mapGoalIdSteps.containsKey(stepItem.caresp__Goal__c) ? mapGoalIdSteps.get(stepItem.caresp__Goal__c) : new List<ServicePlanWizClientsWrapper.Steps>();
            step.stepId = stepItem.Id;
            step.goalId = stepItem.caresp__Goal__c;
            step.stepName = stepItem.Name;
            step.description = stepItem.caresp__Description__c;
            step.startDate = (stepItem.caresp__Start_Date__c != null) ? stepItem.caresp__Start_Date__c.format() : null;
            step.targetDate = (stepItem.caresp__Target_Date__c != null) ? stepItem.caresp__Target_Date__c.format() : null;
            step.assignedTo = stepItem.caresp__Assigned_To__c;
            step.status = stepItem.caresp__Status__c;
            step.isDeleteStep = false;
            if(stepItem.caresp__Step_Type__c == 'Step'){
                step.typeOfAction='Step';
            }else {
                step.typeOfAction = stepItem.caresp__Type_of_Action__c; 
            }
            
            step.isActionableStep = step.typeOfAction !='Step' ? true : false;
            
            step.clientGoalStepId = ((String)(mapGoalIdToGoalRec.get(stepItem.caresp__Goal__c)).get(planObjConfig.caresp__Goal_s_Filter_Field_API_Name__c) )+ '#' + stepItem.caresp__Goal__c + '#' + stepItem.Id;
            listStepForMap.add(step);
            mapGoalIdSteps.put(stepItem.caresp__Goal__c, listStepForMap);
            
        }
        
        return mapGoalIdSteps;
    }
    
    
    @AuraEnabled(cacheable=false)
    Public Static Boolean createGoalStepTemp(String params) {
        System.debug('in createGoalStepTemp');
        
        try {
            Map<String, Object> paramMap = (Map<String, Object>) JSON.deserializeUntyped(params);
            String asID = (String) paramMap.get('asID');
            String planId = (String) paramMap.get('planId');
            String objectApiName = (String) paramMap.get('objectApiName');
            String planTempId = (String) paramMap.get('planTempId');
            Map<String, Object> defaultDateValues = (Map<String, Object>) paramMap.get('defaultDateValues');
            
            List<ServicePlanWizClientsWrapper> lstClient = getClientsDynamically(asID, planId, objectApiName, false);
            System.debug('lstClient>>> ' + lstClient);
            
            List<caresp__Goal__c> listGoalToCreate = createGoals(lstClient, planId, planTempId, defaultDateValues);
            System.debug('listGoalToCreate>>> ' + listGoalToCreate);
            
            if (!listGoalToCreate.isEmpty()) {
                listGoalToCreate = insertGoals(listGoalToCreate);
                List<caresp__Step__c> listStepToCreate = createSteps(listGoalToCreate, defaultDateValues);
                System.debug('listStepToCreate>>> ' + listStepToCreate);
                
                if (!listStepToCreate.isEmpty()) {
                    listStepToCreate = insertSteps(listStepToCreate);
                    createTaskForStep(listStepToCreate, asID);
                }
            }
            return true;
        } catch (Exception ex) {
            System.debug('error occured in createGoalStepTemp :: ' + ex);
            return false;
        }
    }
    
    private static List<caresp__Goal__c> createGoals(List<ServicePlanWizClientsWrapper> lstClient, String planId, String planTempId, Map<String, Object> defaultDateValues) {
        List<caresp__Goal__c> listGoalToCreate = new List<caresp__Goal__c>();
        caresp__Plan_Template__c planTemp = [SELECT Id, Name, Parent_Child_Relation__c, Plan_template_Name__c,
                                             (SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Client_DOB__c, Client_Name__c, Domain__c, Description__c, Goal_Type__c, Status__c, Stuck_Reason__c, Plan_Template__c,
                                              (SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Goal_Template__c, Assessment__c, Assigned_To__c, Document_Type__c, /*Service__c,*/ Status__c, Step__c, Description__c, Step_Type__c, Type_of_Action__c, isActive__c
                                               FROM Step_Templates__r WHERE isActive__c = true)
                                              FROM Goal_Template__r WHERE isActive__c = true)
                                             FROM Plan_Template__c WHERE Id = :planTempId AND isActive__c = true WITH SECURITY_ENFORCED];
        Map<Id, caresp__Goal_Template__c> mapPlanTempIdToGoalTempRec = new Map<Id, caresp__Goal_Template__c>(planTemp.caresp__Goal_Template__r);
        
        System.debug('planTemp>>>' + planTemp);
        
        for (ServicePlanWizClientsWrapper clientData : lstClient) {
            for (caresp__Goal_Template__c goalTemp : planTemp.caresp__Goal_Template__r) {
                SObject goal = Schema.getGlobalDescribe().get('caresp__Goal__c').newSObject();
                goal.put(String.valueOf(clientData.attributes.get('goalFilterField')), String.valueOf(clientData.attributes.get('Id')));
                goal.put('caresp__Plan__c', planId);
                goal.put('caresp__Goal_Template__c', goalTemp.Id);
                goal.put('caresp__Status__c', goalTemp.caresp__Status__c);
                goal.put('caresp__Start_Date__c', Date.valueOf((String)defaultDateValues.get('goalStepStartDate')));
                goal.put('caresp__Domain__c', goalTemp.caresp__Domain__c);
                goal.put('caresp__Stuck_Reason__c', goalTemp.caresp__Stuck_Reason__c);
                goal.put('caresp__Target_Date__c', Date.valueOf((String)defaultDateValues.get('goalStepTargetDate')));
                goal.put('caresp__Description__c', goalTemp.caresp__Description__c);
                goal.put('caresp__Goal_Type__c', goalTemp.caresp__Goal_Type__c);
                listGoalToCreate.add((caresp__Goal__c)goal);
            }
        }
        return listGoalToCreate;
    }
    
    private static List<caresp__Goal__c> insertGoals(List<caresp__Goal__c> listGoalToCreate) {
        List<SObject> inseratableGoals = Security.stripInaccessible(AccessType.CREATABLE, listGoalToCreate).getRecords();
        if (Schema.sObjectType.caresp__Goal__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Plan__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Goal_Template__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Status__c.isCreateable()
            && Schema.sObjectType.caresp__Goal__c.fields.caresp__Start_Date__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Domain__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Stuck_Reason__c.isCreateable()
            && Schema.sObjectType.caresp__Goal__c.fields.caresp__Target_Date__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Description__c.isCreateable() && Schema.sObjectType.caresp__Goal__c.fields.caresp__Goal_Type__c.isCreateable()) {
                insert as user inseratableGoals;
            }
        return inseratableGoals;
    }
    
    private static List<caresp__Step__c> createSteps(List<caresp__Goal__c> inseratableGoals, Map<String, Object> defaultDateValues) {
        List<caresp__Step__c> listStepToCreate = new List<caresp__Step__c>();
        Map<Id, caresp__Goal_Template__c> mapPlanTempIdToGoalTempRec = new Map<Id, caresp__Goal_Template__c>([SELECT Id, caresp__Description__c, (SELECT Id,caresp__Assessment__c,caresp__Description__c, caresp__Document_Type__c,  caresp__Step_Type__c, caresp__Type_of_Action__c, caresp__Status__c, caresp__Assigned_To__c FROM Step_Templates__r WHERE isActive__c = true) FROM Goal_Template__c WHERE isActive__c = true]);
        System.debug('inseratableGoals>>> ' + inseratableGoals);
        for (caresp__Goal__c goal : inseratableGoals) {
            caresp__Goal_Template__c goalTemp = mapPlanTempIdToGoalTempRec.get(goal.caresp__Goal_Template__c);
            for (caresp__Step_Template__c stepTemp : goalTemp.caresp__Step_Templates__r) {
                SObject step = Schema.getGlobalDescribe().get('caresp__Step__c').newSObject();
                step.put('caresp__Goal__c', goal.Id);
                step.put('caresp__Description__c', stepTemp.caresp__Description__c);
                step.put('caresp__Start_Date__c', Date.valueOf((String)defaultDateValues.get('goalStepStartDate')));
                step.put('caresp__Target_Date__c',Date.valueOf((String)defaultDateValues.get('goalStepTargetDate')));
                step.put('caresp__Assessment__c', stepTemp.caresp__Assessment__c);
                step.put('caresp__Document_Type__c', stepTemp.caresp__Document_Type__c);
                step.put('caresp__Step_Type__c', stepTemp.caresp__Step_Type__c);
                step.put('caresp__Type_of_Action__c', stepTemp.caresp__Type_of_Action__c);
                step.put('caresp__Status__c', stepTemp.caresp__Status__c);
                if (stepTemp.caresp__Assigned_To__c != null || stepTemp.caresp__Assigned_To__c == '') {
                    step.put('caresp__Assigned_To__c', stepTemp.caresp__Assigned_To__c);
                }
                listStepToCreate.add((caresp__Step__c)step);
            }
        }
        return listStepToCreate;
    }
    
    private static List<caresp__Step__c> insertSteps(List<caresp__Step__c> listStepToCreate) {
        List<caresp__Step__c> insertableSteps = Security.stripInaccessible(AccessType.CREATABLE, listStepToCreate).getRecords();
        if (Schema.sObjectType.caresp__Step__c.isCreateable()) {
            insert as user insertableSteps;
        }
        return insertableSteps;
    }
    
    
    
    
    
    
    
    
    //Check if Goal Exists
    @AuraEnabled
    public static Boolean checkGoals (Id planId)
    {
        Boolean goalExists = false;
        List<caresp__Goal__c> listGoal = [select Id, Plan__c from Goal__c where Plan__c = :planId WITH SECURITY_ENFORCED];
        if (listGoal != null && listGoal.size() > 0) 
        {
            goalExists = true;
        }
        return goalExists;
    }
    
    
    
    
    
    
    //Save Goal Details
    @AuraEnabled
    public static List<Id> saveGoal (Map<String, Object> saveGoalData, List<Id> listClientIds)
    {
        System.debug('saveGoalData>>>' + saveGoalData);
        //String returnStr;
        List<Id> listGoalIds = new List<Id>();
        List<caresp__Goal__c> listGoals = new List<caresp__Goal__c>();
        System.debug('saveGoalData>>>'+saveGoalData);
        
        SObject goal = Schema.getGlobalDescribe().get('caresp__Goal__c').newSObject();
        goal.put('Id', String.valueOf(saveGoalData.get('goalId')));
        goal.put(String.valueOf(saveGoalData.get('goalFilterFieldName')), String.valueOf(saveGoalData.get('childId')));
        if(String.valueOf(saveGoalData.get('goalId')) == null)
        {
            goal.put('Plan__c', String.valueOf(saveGoalData.get('planId')));
        }
        goal.put('caresp__Client_Name__c', String.valueOf(saveGoalData.get('cName')));
        goal.put('caresp__Status__c', String.valueOf(saveGoalData.get('status')));
        goal.put('caresp__Start_Date__c', saveGoalData.get('startDate') != null ? Date.valueOf(((String)saveGoalData.get('startDate')).trim()): null);
        goal.put('caresp__Domain__c', String.valueOf(saveGoalData.get('domain')));
        goal.put('caresp__Stuck_Reason__c', String.valueOf(saveGoalData.get('reason')));
        goal.put('caresp__Target_Date__c',saveGoalData.get('targetDate') != null ? Date.valueOf(((String)saveGoalData.get('targetDate')).trim()): null) ;
        goal.put('caresp__Description__c', String.valueOf(saveGoalData.get('description')));
        goal.put('caresp__Goal_Type__c', 'Household'); 
        
        
        System.debug('goal>>>'+goal);
        /*if (listGoals != null && listGoals.size() > 0)
{*/
        try {
            List<SObject> existingRecords = new List<SObject>();
            List<SObject> newRecords = new List<SObject>();
            List<SObject> accessibleGoals = new List<SObject>();
            
            // Separate records based on whether they have an Id
            if(goal.Id != null) {
                existingRecords.add(goal);
            } else {
                newRecords.add(goal);
            }
            
            // Handle existing records - UPDATABLE
            if(!existingRecords.isEmpty()) {
                List<SObject> updatableRecords = Security.stripInaccessible(AccessType.UPDATABLE,  existingRecords).getRecords();
                
                System.debug('updatableRecords>>> ' + updatableRecords);
                if(!updatableRecords.isEmpty()) {
                    update as user updatableRecords;
                    accessibleGoals.addAll(updatableRecords);
                }
            }
            
            // Handle new records - CREATABLE
            if(!newRecords.isEmpty()) {
                List<SObject> creatableRecords = Security.stripInaccessible(
                    AccessType.CREATABLE, 
                    newRecords
                ).getRecords();
                
                System.debug('creatableRecords>>> ' + creatableRecords);
                if(!creatableRecords.isEmpty()) {
                    insert as user creatableRecords;
                    accessibleGoals.addAll(creatableRecords);
                }
            }
            
            System.debug('accessibleGoals>>> ' + accessibleGoals);
            
            // Collect IDs from processed records
            for(SObject g : accessibleGoals) {
                listGoalIds.add(String.valueOf(g.get('Id')));
            }
            
            System.debug('goal>>>' + goal);
            System.debug('listGoalIds>>>' + listGoalIds);
            
        } catch (Exception ex) {
            System.debug('## ex: ' + ex.getMessage());
        }
        //}
        
        return listGoalIds;
    }
    
    
    
    
    
    //Delete Goal
    @AuraEnabled
    public static String deleteGoal (Id goalId)
    {
        String returnStr;
        try {
            List<caresp__Goal__c> listGoalsToDel = [select Id from Goal__c where Id = :goalId WITH SECURITY_ENFORCED];
            delete as user Security.stripInaccessible(AccessType.READABLE, listGoalsToDel).getRecords();
            
            returnStr = 'Success';
        } catch (Exception ex) {system.debug('## ex: ' + ex.getMessage()); returnStr = 'Error: ' + ex.getMessage(); return returnStr;}
        
        return returnStr;
    }
    
    
    
    
    
    
    
    //Get Assigned Worker in Step  
    @AuraEnabled(cacheable=true)
    public static String getAssignedWorker(Id asId, String objectApiName) {
        try {
            // Input validation
            if (asId == null || String.isBlank(objectApiName)) {
                throw new AuraHandledException('Invalid input parameters');
            }
            
            // Verify object exists and is accessible
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName)?.getDescribe();
            if (describeResult == null) {
                throw new AuraHandledException('Object ' + objectApiName + ' not found or not accessible');
            }
            
            // Get field map and verify accessibility
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            List<String> accessibleFields = new List<String>();
            
            // Filter only accessible fields
            for(String field : fieldMap.keySet()) {
                if(fieldMap.get(field).getDescribe().isAccessible()) {
                    accessibleFields.add(field);
                }
            }
            
            // Build SOQL query with accessible fields only
            String additionalFields = '';
            if (objectApiName != 'caresp__Client_Service__c') {
                // Verify Owner.Name is accessible
                if (describeResult.fields.getMap().get('OwnerId')?.getDescribe().isAccessible()) {
                    additionalFields = ', Owner.Name';
                } else {
                    throw new AuraHandledException('Owner field is not accessible');
                }
            }
            
            // Build and sanitize SOQL query
            String soql = 'SELECT ' + String.join(accessibleFields, ',') + 
                additionalFields + 
                ' FROM ' + String.escapeSingleQuotes(objectApiName) + 
                ' WHERE Id = :escapedAsId WITH SECURITY_ENFORCED';
            
            System.debug('Generated SOQL: ' + soql);
            
            // Execute query with error handling
            SObject record;
            try {
                String escapedAsId = String.escapeSingleQuotes(asID);
                record = Database.query(soql.replace(':escapedAsId', '\'' + escapedAsId + '\''));
            } catch (QueryException qe) {
                throw new AuraHandledException('Query failed: ' + qe.getMessage());
            }
            
            if (record == null) {
                throw new AuraHandledException('Record not found');
            }
            
            // Get assigned worker based on object type
            String assignedWorker;
            if (objectApiName.equals('caresp__Client_Service__c')) {
                Object workerValue = record.get('caresp__Assigned_Worker_Formula__c');
                assignedWorker = workerValue != null ? String.valueOf(workerValue) : '';
            } else {
                SObject owner = record.getSObject('Owner');
                assignedWorker = owner != null ? String.valueOf(owner.get('Name')) : '';
            }
            
            return assignedWorker;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getAssignedWorker: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    
    
    
    
    //Save Step  
    @AuraEnabled
    public static String saveStep (List<caresp__Step__c> listSteps, List<Id> listGoalIds, String objectApiName ,String recordId)
    {
        try
        {
            system.debug('#### listSteps: ' + listSteps);
            system.debug('#### listGoalIds: ' + listGoalIds);
            system.debug('#### objectApiName: ' + objectApiName);
            system.debug('#### recordId: ' + recordId);
            String returnStr;
            List<caresp__Step__c> listStepsToSave = new List<caresp__Step__c>();
            Map<String, Id> mapStepNumGoalStepId = new Map<String, Id>();
            String OwnerName = getAssignedWorker(recordId, objectApiName);
            
            
            for (caresp__Step__c s : [select Id, Name, Step_Num__c, Goal__c from Step__c where Goal__c IN :listGoalIds WITH SECURITY_ENFORCED])
            {
                mapStepNumGoalStepId.put(String.valueOf(s.caresp__Step_Num__c) + '##' + s.caresp__Goal__c, s.Id);
            }
            system.debug('#### mapStepNumGoalStepId: ' + mapStepNumGoalStepId);
            
            for (Id gId : listGoalIds)
            {
                for (caresp__Step__c step : listSteps)
                {
                    if( Schema.sObjectType.caresp__Step__c.isCreateable () && Schema.sObjectType.caresp__Step__c.fields.caresp__Goal__c.isCreateable () && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Description__c.isCreateable () && Schema.sObjectType.caresp__Step__c.fields.caresp__Start_Date__c.isCreateable () && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Target_Date__c.isCreateable  () && Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Num__c.isCreateable  () && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Assessment__c.isCreateable  () && Schema.sObjectType.caresp__Step__c.fields.caresp__Document_Type__c.isCreateable  () && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Type__c.isCreateable  () && Schema.sObjectType.caresp__Step__c.fields.caresp__Type_of_Action__c.isCreateable  () &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Status__c.isCreateable  () && Schema.sObjectType.caresp__Step__c.fields.caresp__Assigned_To__c.isCreateable  () ){
                           caresp__Step__c s = new caresp__Step__c();
                           if (step.Id != null)    //Old Step
                           {
                               s.Id = step.Id;
                           }
                           else    //New Step
                           {
                               s.caresp__Goal__c = gId;
                           }
                           // Apply FLS checks before assigning values
                           s.caresp__Description__c = step.caresp__Description__c;
                           s.caresp__Start_Date__c = step.caresp__Start_Date__c;
                           s.caresp__Target_Date__c = step.caresp__Target_Date__c;
                           s.caresp__Step_Num__c = step.caresp__Step_Num__c;
                           s.caresp__Assessment__c = step.caresp__Assessment__c;
                           s.caresp__Document_Type__c = step.caresp__Document_Type__c;
                           s.caresp__Step_Type__c = step.caresp__Step_Type__c;
                           s.caresp__Type_of_Action__c = step.caresp__Type_of_Action__c;
                           s.caresp__Status__c = step.caresp__Status__c;
                           s.caresp__Assigned_To__c = String.isNotBlank(step.caresp__Assigned_To__c) 
                               ? step.caresp__Assigned_To__c 
                               : OwnerName;
                           listStepsToSave.add(s);
                       }                    
                }
            }
            
            system.debug('#### listStepsToSave: ' + listStepsToSave);
            try {
                List<SObject> existingRecords = new List<SObject>();
                List<SObject> newRecords = new List<SObject>();
                List<SObject> accessibleGoals = new List<SObject>();
                
                // Separate existing and new records
                for(SObject record : listStepsToSave) {
                    if(record.Id != null) {
                        existingRecords.add(record);
                    } else {
                        newRecords.add(record);
                    }
                }
                
                // Handle existing records - UPDATABLE
                if(!existingRecords.isEmpty()) {
                    List<SObject> updatableRecords = Security.stripInaccessible(AccessType.UPDATABLE, existingRecords).getRecords();
                    if( Schema.sObjectType.caresp__Step__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Goal__c.isUpdateable() && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Description__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Start_Date__c.isUpdateable() && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Target_Date__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Num__c.isUpdateable() && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Assessment__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Document_Type__c.isUpdateable() && 
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Type__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Type_of_Action__c.isUpdateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Status__c.isUpdateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Assigned_To__c.isUpdateable() && !updatableRecords.isEmpty()) {                   
                           update as user updatableRecords;
                           accessibleGoals.addAll(updatableRecords);
                       }
                    
                }
                
                // Handle new records - CREATABLE
                if(!newRecords.isEmpty()) {
                    List<SObject> creatableRecords = Security.stripInaccessible( AccessType.CREATABLE,  newRecords).getRecords();
                    if(Schema.sObjectType.caresp__Step__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Goal__c.isCreateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Description__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Start_Date__c.isCreateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Target_Date__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Num__c.isCreateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Assessment__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Document_Type__c.isCreateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Step_Type__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Type_of_Action__c.isCreateable() &&
                       Schema.sObjectType.caresp__Step__c.fields.caresp__Status__c.isCreateable() && Schema.sObjectType.caresp__Step__c.fields.caresp__Assigned_To__c.isCreateable() && !creatableRecords.isEmpty()) {
                           insert as user creatableRecords;
                           accessibleGoals.addAll(creatableRecords);
                       }
                    
                }
                System.debug('accessibleSteps>>>' +  accessibleGoals);
                // Create tasks and return result
                if(!accessibleGoals.isEmpty()) {
                    createTaskForStep(accessibleGoals, recordId);
                    returnStr = String.valueOf(accessibleGoals.size());
                } else {
                    returnStr = '0';
                }
                
            } catch (Exception ex) {
                System.debug('## ex in saveStep: ' + ex.getMessage());
                returnStr = 'Error: ' + ex.getMessage();
                return returnStr;
            }
            return returnStr;
        }catch(Exception ex)
        {
            System.debug('ex in method saveSteps>>>' + ex.getStackTraceString());
            return null;
            
        }
    } 
    
    
    
    
    
    
    //Get Steps in Goal
    //@AuraEnabled(cacheable=true)
    @AuraEnabled
    public static List<caresp__Step__c> getSteps (Id goalId)
    {
        List<caresp__Step__c> listSteps = new List<caresp__Step__c>();
        List<caresp__Step__c> listOriginalSteps = [select Id, Name, Goal__c, Description__c, Start_Date__c, Target_Date__c, Assigned_To__c,Type_of_Action__c,Step_Type__c/*,Service__c*/,Document_Type__c,Assessment__c, Status__c, Step_Num__c from Step__c where Goal__c = :goalId WITH SECURITY_ENFORCED ORDER By Step_Num__c];
        if (listOriginalSteps != null && listOriginalSteps.size() > 0)
        {
            for (Integer i = 0; i < listOriginalSteps.size(); i++)
            {
                listOriginalSteps[i].caresp__Step_Num__c = i + 1;
                listSteps.add(listOriginalSteps[i]);
            }
        }
        
        return listSteps;
    }
    
    
    
    
    
    
    //Delete Step
    @AuraEnabled
    public static String deleteStep (Id stepId)
    {
        String returnStr;
        try {
            List<caresp__Step__c> stepsToDel = [select Id from Step__c where Id = :stepId WITH SECURITY_ENFORCED];
            
            delete as user Security.stripInaccessible(AccessType.READABLE, stepsToDel).getRecords();
            
            returnStr = 'Success';
        } catch (Exception ex) {system.debug('## ex: ' + ex.getMessage()); returnStr = 'Error: ' + ex.getMessage(); return returnStr;}
        
        return returnStr;
    }
    
    
    
    
    
    
    
    
    
    
    
    @AuraEnabled
    public static void submitPlan(Id asId, Id planId, String objApiName) {
        System.debug('in submit>>> ');
        
        // Ensure we are fetching data efficiently
        List<ServicePlanWizClientsWrapper> lstClientGoalAndStep = 
            getClientsDynamically(asId, planId, objApiName, false);
        
        System.debug('lstClientGoalAndStep in submit>>> ' + lstClientGoalAndStep);
        
        // Fetch Plan__c safely
        List<caresp__Plan__c> planList = [
            SELECT Id, Name, Plan_Start_Date__c, Plan_Type_Txt__c, Plan_End_Date__c, 
            Plan_Name__c, Plan_Status__c, Plan_Date_Accepted__c, 
            Plan_Description__c, Plan_Version__c, Parent_Plan__r.Plan_Name__c, 
            Progress_Status__c
            FROM caresp__Plan__c 
            WHERE Id = :planId WITH SECURITY_ENFORCED
        ];
        
        if (planList.isEmpty()) {
            System.debug('No plan found for the given ID.');
            return;
        }
        
        caresp__Plan__c plan = planList[0]; // Assign first record safely
        ServicePlanWizClientsWrapper.PlanWrapper planWrapperRec = preparePlanWrapperForsubmitPlan(plan);
        
        // Optimize clientWrapperList processing
        List<ServicePlanWizClientsWrapper.ClientWrapper> clientWrapperList = 
            new List<ServicePlanWizClientsWrapper.ClientWrapper>();
        
        for (ServicePlanWizClientsWrapper clientData : lstClientGoalAndStep) {
            ServicePlanWizClientsWrapper.ClientWrapper clWrap = new ServicePlanWizClientsWrapper.ClientWrapper();
            clWrap.attributes = clientData.attributes; // Assign attributes explicitly
            clientWrapperList.add(clWrap);
        }
        
        
        planWrapperRec.clients = clientWrapperList;
        
        // Prepare for bulk update
        List<caresp__Plan__c> plansToUpdate = new List<caresp__Plan__c>();
        
        plan.caresp__Plan_Status__c = 'Accepted - New';
        plan.caresp__Data_Json_for_Signature_Request__c = JSON.serialize(planWrapperRec);
        plansToUpdate.add(plan);
        
        // Perform a single bulk update
        if (!plansToUpdate.isEmpty()) {
            update as user Security.stripInaccessible(AccessType.UPDATABLE, plansToUpdate).getRecords();
        }
    }
    
    
    
    private static ServicePlanWizClientsWrapper.PlanWrapper preparePlanWrapperForsubmitPlan(caresp__Plan__c plan)
    {
        ServicePlanWizClientsWrapper.PlanWrapper planWrapperRec = new ServicePlanWizClientsWrapper.PlanWrapper();          
        // Using safe navigation operator (?.) for relationship fields
        planWrapperRec.planType = plan.caresp__Plan_Type_Txt__c != null ? plan.caresp__Plan_Type_Txt__c : planWrapperRec.planType;
        
        planWrapperRec.planStartDate = plan.caresp__Plan_Start_Date__c != null ? String.valueOf(plan.caresp__Plan_Start_Date__c.format()) : planWrapperRec.planStartDate;
        planWrapperRec.planEndDate = plan.caresp__Plan_End_Date__c != null ? String.valueOf(plan.caresp__Plan_End_Date__c.format()) : planWrapperRec.planEndDate;
        
        planWrapperRec.planName = plan.caresp__Plan_Name__c != null ? plan.caresp__Plan_Name__c : planWrapperRec.planName;
        planWrapperRec.planStatus = 'Accepted - New';  // Since this is a hardcoded value, no null check needed
        planWrapperRec.planAcceptedDate = plan.Plan_Date_Accepted__c != null ? String.valueOf(plan.Plan_Date_Accepted__c.format()) : planWrapperRec.planAcceptedDate;
        planWrapperRec.planDescription = plan.caresp__Plan_Description__c != null ? plan.caresp__Plan_Description__c : planWrapperRec.planDescription;
        
        planWrapperRec.planVersion = plan.caresp__Plan_Version__c != null ? plan.caresp__Plan_Version__c : planWrapperRec.planVersion;
        planWrapperRec.parentPlanName = plan.caresp__Parent_Plan__r?.caresp__Plan_Name__c != null ? plan.caresp__Parent_Plan__r.caresp__Plan_Name__c : planWrapperRec.parentPlanName;
        planWrapperRec.progressStatus = plan.caresp__Progress_Status__c != null ? plan.caresp__Progress_Status__c : planWrapperRec.progressStatus;
        
        return planWrapperRec;
    }
    
    
    
    
    
    
    //Create New Version of Plan
    @AuraEnabled
    public static Id createNewVersion (Id planId, String planObjFilterField, String goalFieldFilterName, String recordId)
    {
        try{
            
            system.debug('planId$$'+ planId);
            system.debug('planObjFilterField$$'+ planObjFilterField);
            List<caresp__Goal__c> listNewGoals = new List<caresp__Goal__c>();
            Map<caresp__Goal__c, List<caresp__Step__c>> mapGoalSteps = new Map<caresp__Goal__c, List<caresp__Step__c>>(); 
            List<Step__c> listNewSteps = new List<Step__c>();
            List<Step__c> insertableSteps = new List<Step__c>();
            List<caresp__Goal__c> insertableGoals = new List<caresp__Goal__c>();
            List<sObject> listPlan = Database.query('SELECT ' + String.join(getFieldNames('caresp__Plan__c'), ',') + ' FROM caresp__Plan__c WHERE Id =: planId WITH SECURITY_ENFORCED');
            caresp__Plan__c plan = (caresp__Plan__c) listPlan[0];
            
            Integer version = Integer.valueOf(String.valueOf(plan.get('caresp__Plan_Version__c')).split(' ')[1]);
            Integer newVersion = version + 1;
            plan.caresp__Plan_Status__c = 'Not Current';
            List<caresp__Plan__c> updatableRecords = new List<caresp__Plan__c>();
            //
            if (Schema.sObjectType.caresp__Plan__c.isUpdateable()) {
                updatableRecords = Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Plan__c>{plan}).getRecords();
                if(!updatableRecords.isEmpty()){
                    update as user updatableRecords;
                }
            }                   //
            
            // update plan; //Update Old Plan
            List<caresp__Plan__c> insertableRecords = new List<caresp__Plan__c>();
            caresp__Plan__c newPlan = updatableRecords[0].clone(false, true, false, false);
            newPlan.caresp__Plan_Version__c = 'Version ' + String.valueOf(newVersion);
            newPlan.caresp__Parent_Plan__c = String.valueOf(updatableRecords[0].get('Id'));
            newPlan.caresp__Plan_Status__c = 'Draft';
            newPlan.Plan_Signed_Date__c = null;
            newPlan.Request_Signature_URL__c = null;
            newPlan.Request_Signature_Counter__c = null;
            newPlan.Request_Signature_Date__c = null;
            newPlan.Request_Signature_Link_Status__c = null;
            newPlan.caresp__Field_Blueprint_JSON__c = String.valueOf(updatableRecords[0].get('caresp__Field_Blueprint_JSON__c'));
            newPlan.put(planObjFilterField, String.valueOf(updatableRecords[0].get(planObjFilterField)));
            newPlan.caresp__Parent_Child_Name__c = String.valueOf(updatableRecords[0].get('caresp__Parent_Child_Name__c'));
            if (Schema.sObjectType.caresp__Plan__c.isCreateable() ) {//added by sg
                insertableRecords =(List<caresp__Plan__c>) Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Plan__c>{newPlan}).getRecords();
                insert as user insertableRecords;
            }
            
            List<caresp__Goal__c> listGoal = Database.query('SELECT ' + String.join(getFieldNames('caresp__Goal__c'), ',') + ', (select Id, Name, caresp__Assigned_To__c, caresp__Description__c, caresp__Goal__c, caresp__Type_of_Action__c, caresp__Start_Date__c,caresp__Step_Type__c, caresp__Status__c, caresp__Target_Date__c, caresp__Step_Num__c from caresp__Steps__r) FROM caresp__Goal__c WHERE caresp__Plan__c =: planId WITH SECURITY_ENFORCED');
            //List<Goal__c> goalList = (List<Goal__c>) listGoal[0];
            System.debug('listGoal$$$$' + listGoal);
            for (sObject g : listGoal)
            {
                caresp__Goal__c goal = ((caresp__Goal__c)g).clone(false, true, false, false);
                goal.Id = null;
                goal.put(goalFieldFilterName, String.valueOf(g.get(goalFieldFilterName)));
                goal.caresp__Plan__c = String.valueOf(insertableRecords[0].Id);
                listNewGoals.add(goal);
                if(((caresp__Goal__c)g).getSObjects('caresp__Steps__r') != null)
                {
                    mapGoalSteps.put(goal, ((List<caresp__Step__c>)g.getSObjects('caresp__Steps__r')).deepClone(false, false, false));
                }
            }
            system.debug('## mapGoalSteps: ' + mapGoalSteps);
            
            if (listNewGoals != null && listNewGoals.size() > 0) {
                if (Schema.sObjectType.caresp__Goal__c.isCreateable()) {
                    // Filter accessible goals and insert them
                    insertableGoals = Security.stripInaccessible(AccessType.CREATABLE, listNewGoals).getRecords();
                    System.debug('insertableGoals>>> ' + insertableGoals);
                    insert  insertableGoals;
                }
                
                // Map to store old goal references to new goal IDs
                Map<caresp__Goal__c, Id> goalIdMap = new Map<caresp__Goal__c, Id>();
                for (Integer i = 0; i < insertableGoals.size(); i++) {
                    goalIdMap.put(listNewGoals[i], insertableGoals[i].Id);
                }
                
                // Process steps for the new goals
                for (caresp__Goal__c oldGoal : mapGoalSteps.keySet()) {
                    Id newGoalId = goalIdMap.get(oldGoal); // Retrieve the new ID
                    for (caresp__Step__c step : mapGoalSteps.get(oldGoal)) {
                        step.caresp__Goal__c = newGoalId; // Assign the new goal ID
                        listNewSteps.add(step);
                    }
                }
                
                if (listNewSteps != null && listNewSteps.size() > 0) {
                    if (Schema.sObjectType.caresp__Step__c.isCreateable()) {
                        // Filter accessible steps and insert them
                        insertableSteps = (List<Step__c>)Security.stripInaccessible(AccessType.CREATABLE, listNewSteps).getRecords();
                        insert as user insertableSteps;
                    }
                    
                    
                    // Create tasks for the new steps
                    createTaskForStep(insertableSteps, recordId);
                }
            }
            
            
            return String.valueOf(insertableRecords[0].Id);
            
        }catch(Exception ex)
        {
            System.debug('Exception in createNewVersion: ' + ex.getMessage());    
            return null;
        }
    }
    
    
    
    
    
    
    
    //Get Goal Values
    @AuraEnabled
    public static caresp__Goal__c getGoal (Id goalId)
    {
        return [select Id, Name, Client_Name__c, Status__c, Start_Date__c, Domain__c, Stuck_Reason__c, Target_Date__c, Description__c from Goal__c where Id = :goalId WITH SECURITY_ENFORCED];
    }
    
    
    
    
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<PlanInfoWrapper> getPlanDraft(String recordId, String objectApiName, String planObjFilterField, String parentChildRelName, String currentDateTime) {
        List<PlanInfoWrapper> listPlanInfo = new List<PlanInfoWrapper>();
        
        try {
            planObjFilterField = String.escapeSingleQuotes(planObjFilterField);
            // Executing the query
            // Building the query dynamically
            String query = 'SELECT ' + String.join(getFieldNames('caresp__Plan__c'), ',') + 
                ' FROM caresp__Plan__c WHERE ' + planObjFilterField + ' = :recordId' + 
                ' AND (caresp__Plan_Status__c = \'Draft\' OR caresp__Plan_Status__c = \'Accepted - New\')' +
                ' AND caresp__Parent_Child_Name__c = :parentChildRelName WITH SECURITY_ENFORCED ORDER BY Name';
            recordId = String.escapeSingleQuotes(recordId);
            parentChildRelName = String.escapeSingleQuotes(parentChildRelName);
            
            List<sObject> listPlan = Database.query(query.replace(':recordId', '\''+ recordId + '\'').replace(':parentChildRelName' , '\''+ parentChildRelName + '\''));
            System.debug('listPlan>>> ' + listPlan);
            
            // Processing the query results
            for (sObject pl : listPlan) {
                PlanInfoWrapper planInfo = new PlanInfoWrapper();
                planInfo.planId = String.valueOf(pl.get('Id'));
                
                
                planInfo.planDetails =  String.valueOf(pl.get('caresp__Plan_Type_Txt__c')) + ' : ' + String.valueOf(Date.valueOf(pl.get('caresp__Plan_Start_Date__c')).format()) + ' : ' +  String.valueOf(pl.get('caresp__Plan_Status__c'));
                planInfo.planType = String.valueOf(pl.get('caresp__Plan_Type_Txt__c'));
                listPlanInfo.add(planInfo);
            }
        } catch (Exception e) {
            // Logging the exception
            System.debug('Exception in getPlanDraft: ' + e.getMessage());
            // Optionally, add custom error handling logic here
        }
        
        return listPlanInfo;
    }
    
    
    
    
    
    
    public static void  createTaskForStep(List<sObject> listStepsToTask ,String recordId) {
        System.debug('listStepsToTask #' + listStepsToTask);
        User assignedUser = [SELECT Id,username FROM User WHERE Id =: UserInfo.getUserId() WITH SECURITY_ENFORCED  LIMIT 1];
        List<Task> listTask = new List<Task>();
        System.debug('assignedUser>>>' + assignedUser);
        for (sObject step : listStepsToTask) {
            if (string.valueOf(step.get('caresp__Step_Type__c')) == 'Actionable Task') {
                Task newTask = new Task();
                newTask.WhatId = recordId;
                newTask.caresp__Step_ID__c= string.valueOf(step.get('Id'));
                newTask.Subject = string.valueOf(step.get('caresp__Description__c'));
                if(string.valueOf(step.get('caresp__Type_of_Action__c'))=='Upload Document'){
                    newTask.Type='Document Collection';
                    newTask.caresp__Task_Sub_Type__c=string.valueOf(step.get('caresp__Document_Type__c'));
                }else if(string.valueOf(step.get('caresp__Type_of_Action__c'))=='Conduct Assessment'){
                    newTask.Type='Assessment';
                    newTask.caresp__Task_Sub_Type__c=string.valueOf(step.get('caresp__Assessment__c'));
                }else if(string.valueOf(step.get('caresp__Type_of_Action__c'))=='Enroll in Service'){
                    newTask.Type='Enroll in Service';
                    //  newTask.Task_Sub_Type__c=step.Service__c;
                }else if(string.valueOf(step.get('caresp__Type_of_Action__c'))=='Create Referral'){
                    newTask.Type='Create Referral';
                    // newTask.Task_Sub_Type__c=step.Service__c;
                }
                //newTask.Description = step.Description__c;
                newTask.ActivityDate =  Date.valueOf(step.get('caresp__Target_Date__c'));
                newTask.Status = 'In Progress';
                newTask.OwnerId = assignedUser.Id;
                listTask.add(newTask);
            }
        }
        if (!listTask.isEmpty()) {
            
            if (Schema.sObjectType.Task.isCreateable()) {//added by sg
                insert as user Security.stripInaccessible(AccessType.CREATABLE, listTask).getRecords();
                // insert listTask;
            }
            
            
            system.debug('listTask'+listTask);
        }                
    }
    
    
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static string  getTaskRecord(String stepId) {       
        string taskId='';
        list<task> listTask =[Select Id,Step_ID__c from task where Step_ID__c=:stepId WITH SECURITY_ENFORCED];
        if(!listTask.isEmpty()){
            taskId=listTask[0].Id;
        } else if(listTask.isEmpty()){
            taskId='';
        }     
        system.debug('taskId =>'+taskId);
        return taskId;
    }
    
    
    @AuraEnabled(cacheable = true)
    public static MetadataInfoWrapper getMetadataInfo(String parentObjAPIName, String planId) {
        MetadataInfoWrapper result;
        try {
            caresp__Plan__c planRec = new caresp__Plan__c();
            if (parentObjAPIName == 'caresp__Plan__c' && planId != null && planId != '') {
                planRec = [SELECT Id, Parent_Child_Name__c FROM Plan__c WHERE Id = :planId WITH SECURITY_ENFORCED];
            }
            System.debug('parentObjAPIName>>>' + parentObjAPIName + ' PlanId>>> ' + planId);
            System.debug('planRec>>>' + planRec);
            
            String parentObjName = parentObjAPIName != 'caresp__Plan__c' ? parentObjAPIName : (planRec.Parent_Child_Name__c).split('-')[0];
            Dynamic_Plan_Parent_Obj_Configuration__mdt planObjConfig = [
                SELECT Label, Filter_Filed_Name_Plan_Obj__c, Child_s_parent_Filter_Field_API_Name__c, Child_s_Parent_Obj_API_Name__c, Child_Filter_Field_API_Name__c, Child_Obj_API_Name__c, Goal_s_Filter_Field_API_Name__c, Is_Junction_Exist__c, Parent_Obj_API_Name__c, Object_Fields_To_Display_List__c, Wrapper_Field_List__c, Obj_fields_for_wrapper_fields__c 
                FROM Dynamic_Plan_Parent_Obj_Configuration__mdt 
                WHERE Parent_Obj_API_Name__c = :parentObjName 
                AND Is_Active__c = true 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            result = new MetadataInfoWrapper(
                planObjConfig.Is_Junction_Exist__c ? planObjConfig.Child_s_Parent_Obj_API_Name__c : planObjConfig.Child_Obj_API_Name__c,
                planObjConfig.Goal_s_Filter_Field_API_Name__c,
                planObjConfig.Filter_Filed_Name_Plan_Obj__c, 
                planObjConfig.Label
            );
        } catch (Exception e) {
            System.debug('Error in getMetadataInfo: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
            
        }
        return result;
    }
    
    
    
    
    Public class MetadataInfoWrapper {
        @AuraEnabled
        Public String childObjName { get; set; }
        
        @AuraEnabled
        Public String goalFilterFieldName { get; set; }
        
        @AuraEnabled
        Public String planFilterFieldName { get; set; }
        
        @AuraEnabled
        Public String label { get; set; }
        
        Public MetadataInfoWrapper(String childObjName, String goalFilterFieldName, String planFilterFieldName, String label)
        {
            this.childObjName = childObjName;
            this.goalFilterFieldName = goalFilterFieldName;
            this.planFilterFieldName = planFilterFieldName;
            this.label = label;
            
        }
        
    }
    
    public class PlanInfoWrapper {
        @AuraEnabled
        public Id planId { get; set; }
        
        @AuraEnabled
        public String planDetails { get; set; }
        
        @AuraEnabled
        public String planType { get; set; }
    }
    
    
    
    
    
    
}