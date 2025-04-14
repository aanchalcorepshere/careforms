public with sharing class FormsHelper {
    @AuraEnabled
    public static InsertResult saveObjectStructure(String params) {
        // Validate input
        if (String.isBlank(params)) {
            throw new AuraHandledException('Input parameters cannot be null or empty.');
        }

        Map<String, String> paramData = parseParams(params);
        RecordData primary = (RecordData) JSON.deserialize(paramData.get('primaryObjectList'), RecordData.class);
        List<RecordData> children = (List<RecordData>) JSON.deserialize(paramData.get('childObjectsList'), List<RecordData>.class);
        List<RecordData> parents = (List<RecordData>) JSON.deserialize(paramData.get('parentObjectList'), List<RecordData>.class);
        List<RecordData> grandchildren = (List<RecordData>) JSON.deserialize(paramData.get('grandChildObjectList'), List<RecordData>.class);

        // Check CRUD and FLS for all objects involved
        checkCRUDAndFLS(primary, children, parents, grandchildren);

        return insertRecordsWithUoW(primary, children, parents, grandchildren);
    }

    private static void checkCRUDAndFLS(RecordData primary, List<RecordData> children, List<RecordData> parents, List<RecordData> grandchildren) {
        // Check CRUD and FLS for primary object
        checkObjectAccess(primary.objectName.split('\\|')[0], true, true, true);

        // Check CRUD and FLS for parent objects
        for (RecordData parent : parents) {
            checkObjectAccess(parent.objectName.split('\\|')[0], true, true, true);
        }

        // Check CRUD and FLS for child objects
        for (RecordData child : children) {
            checkObjectAccess(child.objectName.split('\\|')[0], true, true, true);
        }

        // Check CRUD and FLS for grandchild objects
        for (RecordData grandchild : grandchildren) {
            checkObjectAccess(grandchild.objectName.split('\\|')[0], true, true, true);
        }
    }

    private static void checkObjectAccess(String objectName, Boolean checkCreate, Boolean checkUpdate, Boolean checkDelete) {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        if (checkCreate && !describe.isCreateable()) {
            throw new SecurityException('Create access denied on object: ' + objectName);
        }
        if (checkUpdate && !describe.isUpdateable()) {
            throw new SecurityException('Update access denied on object: ' + objectName);
        }
        if (checkDelete && !describe.isDeletable()) {
            throw new SecurityException('Delete access denied on object: ' + objectName);
        }
    }

    public static Map<String, String> parseParams(String params) {
        Map<String, Object> paramMap = (Map<String, Object>) JSON.deserializeUntyped(params);
        Map<String, String> result = new Map<String, String>();
        result.put('parentObjectList', (String)paramMap.get('parentObjectList'));
        result.put('primaryObjectList', (String)paramMap.get('primaryObjectList'));
        result.put('childObjectsList', (String)paramMap.get('childObjectsList'));
        result.put('grandChildObjectList', (String)paramMap.get('grandChildObjectList'));
        result.put('questionObjectsList', (String)paramMap.get('questionObjectsList'));
        result.put('formId', (String)paramMap.get('formId'));
        result.put('isVerifyApplication', String.valueOf(paramMap.get('isVerifyApplication')));
        return result;
    }

    public static InsertResult insertRecordsWithUoW(RecordData primary, List<RecordData> children, List<RecordData> parents, List<RecordData> grandchildren) {
        InsertResult result = new InsertResult();
        result.isSuccess = false;
        Map<String, String> parentIdMap = new Map<String, String>();
        List<SObject> recordsToInsert;

        /* try { */
            // Step 1: Upsert Parents (Account)
            recordsToInsert = new List<SObject>();
            for (RecordData parent : parents) {
                SObject parentRecord = createRecord(parent);
                recordsToInsert.add(parentRecord);
            }
            Database.UpsertResult[] saveResults = Database.upsert(recordsToInsert, true, AccessLevel.USER_MODE);
            checkErrors(saveResults, recordsToInsert, result);
            updateParentIdMap(recordsToInsert, parentIdMap); // Map now has Account ID

            // Step 2: Upsert Primary (Contact)
            recordsToInsert = new List<SObject>();
            SObject primaryRecord = createRecord(primary);
            // Link Contact to Account
            if (primary.parents != null) {
                for (ParentData parentData : primary.parents) {
                    String parentKey = parentData.parentApi.split('\\|')[0]; // "Account"
                    if (parentIdMap.containsKey(parentKey)) {
                        String parentField = parentData.parentFieldApi.split('\\|')[1]; // "AccountId"
                        primaryRecord.put(parentField, parentIdMap.get(parentKey));
                    }
                }
            }
            recordsToInsert.add(primaryRecord);
            saveResults = Database.upsert(recordsToInsert, true, AccessLevel.USER_MODE);
            checkErrors(saveResults, recordsToInsert, result);
            updateParentIdMap(recordsToInsert, parentIdMap); // Map now has Contact ID

            // Step 3: Upsert Children (Cases)
            recordsToInsert = new List<SObject>();
            Map<Integer, RecordData> groupedChildren = groupChildrenByRecordIdentifier(children);
            for (Integer recordId : groupedChildren.keySet()) {
                RecordData child = groupedChildren.get(recordId);
                SObject childRecord = createRecord(child);
                // Link Case to Contact
                if (child.parents != null) {
                    for (ParentData parentData : child.parents) {
                        String parentKey = parentData.parentApi; // "Contact"
                        if (parentIdMap.containsKey(parentKey)) {
                            String parentField = parentData.parentFieldApi.split('\\|')[1]; // "ContactId"
                            childRecord.put(parentField, parentIdMap.get(parentKey));
                        }
                    }
                }
                recordsToInsert.add(childRecord);
            }
        
            saveResults = Database.upsert(recordsToInsert, true, AccessLevel.USER_MODE);
            
            
            checkErrors(saveResults, recordsToInsert, result);

            // Success
            result.isSuccess = true;
            result.primaryRecordId = parentIdMap.get(primary.objectName); // Contact ID
            return result;

       
    }

    // Helper method to group child records by recordIdentifier
    private static Map<Integer, RecordData> groupChildrenByRecordIdentifier(List<RecordData> children) {
        Map<Integer, RecordData> groupedChildren = new Map<Integer, RecordData>();
        for (RecordData child : children) {
            for (FieldValue field : child.fieldValue) {

                // Ensure only accessible fields are processed
            if (!Schema.getGlobalDescribe().containsKey(child.objectName)) {
                continue; // Skip if object doesn't exist
            }

            SObjectType objType = Schema.getGlobalDescribe().get(child.objectName);
            if (!objType.getDescribe().isCreateable()) {
                continue; // Skip if object is not creatable
            }

                if (!groupedChildren.containsKey(field.recordIdentifier)) {
                    RecordData newChild = new RecordData();
                    newChild.objectName = child.objectName;
                    newChild.recordType = child.recordType;
                    newChild.parents = child.parents;
                    newChild.fieldValue = new List<FieldValue>();
                    groupedChildren.put(field.recordIdentifier, newChild);
                }
                if(field != null){
                    groupedChildren.get(field.recordIdentifier).fieldValue.add(field);
                }
                
            }
        }
        return groupedChildren;
    }

    // Helper method to update parentIdMap
    private static void updateParentIdMap(List<SObject> records, Map<String, String> parentIdMap) {
        for (SObject record : records) {
            String objectName = record.getSObjectType().getDescribe().getName();
            parentIdMap.put(objectName, record.Id);
        }
    }

    // Helper method to check for errors
    private static void checkErrors(Database.UpsertResult[] saveResults, List<SObject> records, InsertResult result) {
        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    result.errorMessage = err.getMessage();
                    result.failedObjectName = records[saveResults.indexOf(sr)].getSObjectType().getDescribe().getName();
                    throw new DmlException(result.errorMessage);
                }
            }
        }
    }

    // Helper method to create SObject
    public static SObject createRecord(RecordData recordData) {
        String objectName = recordData.objectName.split('\\|')[0];
        System.debug('recordData >> '+recordData);
        System.debug('objectName >> '+objectName);
        SObject record = Schema.getGlobalDescribe().get(objectName).newSObject();
        if(recordData.recordType != '012000000000000AAA'){
            record.put('RecordTypeId', recordData.recordType);
        }

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        for (FieldValue fieldValue : recordData.fieldValue) {
            if (fieldValue.fieldApi.equalsIgnoreCase('Id')) {
                record.Id = fieldValue.inputValue;
                continue;
            }
            // Check if the field is accessible and updateable
            System.debug('fieldValue >> '+fieldValue.fieldApi);
            Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldValue.fieldApi).getDescribe();
            System.debug('fieldDescribe >> '+fieldDescribe.isAccessible());
            System.debug('fieldDescribe >> '+fieldDescribe.isUpdateable());
            if (fieldDescribe.isAccessible() && fieldDescribe.isUpdateable() && fieldDescribe.isCreateable()) {
                Schema.SObjectField field = fieldMap.get(fieldValue.fieldApi);
                if (field != null) {
                    Schema.DisplayType fieldType = field.getDescribe().getType();
                    Object typedValue = convertToDataType(fieldValue.inputValue, fieldType);
                    record.put(fieldValue.fieldApi, typedValue);
                } else {
                    throw new IllegalArgumentException('Invalid field: ' + fieldValue.fieldApi);
                }
            } else {
                throw new SecurityException('Field access denied: ' + fieldValue.fieldApi);
            }
        }
        return record;
    }

    // Helper method to convert inputValue to the correct data type
    private static Object convertToDataType(String inputValue, Schema.DisplayType fieldType) {
        if (inputValue == null || inputValue == '') {
            return null;
        }

        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(inputValue);
            }
            when DATE {
                return Date.valueOf(inputValue);
            }
            when DATETIME {
                return DateTime.valueOfGmt(inputValue);
            }
            when DOUBLE, CURRENCY, PERCENT {
                return Decimal.valueOf(inputValue);
            }
            when INTEGER {
                return Integer.valueOf(inputValue);
            }
            when LONG {
                return Long.valueOf(inputValue);
            }
            when TIME {
                return Time.newInstance(
                    Integer.valueOf(inputValue.substring(0, 2)), // Hours
                    Integer.valueOf(inputValue.substring(3, 5)), // Minutes
                    Integer.valueOf(inputValue.substring(6, 8)), // Seconds
                    0 // Milliseconds
                );
            }
            when else {
                // Default to String (TEXTAREA, PICKLIST, EMAIL, PHONE, URL, etc.)
                return inputValue;
            }
        }
    }
    

    @AuraEnabled
    public static void attachJSONForPDF(String jsonString, String formId){
        if (String.isNotBlank(jsonString)) {
            ContentVersion cvOBJ = new ContentVersion();
            cvOBJ.VersionData = Blob.valueOf(jsonString);
            cvOBJ.Title = UserInfo.getUserId()+'_'+formId;
            cvOBJ.PathOnClient = UserInfo.getUserId()+'_'+formId+'.txt';
            cvOBJ.Origin = 'H';
            cvOBJ.ContentLocation = 'S';
            cvOBJ = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{cvOBJ}).getRecords())[0];
            insert as user cvOBJ;
        }
    }

    @AuraEnabled
    public static void attachPdfToRecord(String formId, String parentId){
        PageReference pdfPage = Page.generateFormDataPDF;
        String theTitle = UserInfo.getUserId()+'_'+formId;
        pdfPage.getParameters().put('theTitle', theTitle);

        Blob pdfBlob;

        if (!Test.isRunningTest()) { 
            pdfBlob = pdfPage.getContent(); 
        } else { 
            pdfBlob = Blob.valueOf('Some Text for a boring PDF file...');
        }

        ContentVersion fileToUpload = new ContentVersion();
        fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
        fileToUpload.pathOnClient ='form_responses.pdf';
        fileToUpload.title = 'Form Responses';
        fileToUpload.versionData = pdfBlob;
        Database.SaveResult saveResult;
        try {
            fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];
            saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

            // Create a ContentDocument Link Record
            // First get the content document Id from ContentVersion
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id].ContentDocumentId;
    
            //Create ContentDocumentLink
            ContentDocumentLink linkToRecord = new ContentDocumentLink();
            linkToRecord.ContentDocumentId = contentDocumentId;
            linkToRecord.LinkedEntityId = parentId;
            linkToRecord.Visibility = 'AllUsers'; 
            linkToRecord.ShareType = 'V'; // Inferred permission
            
            linkToRecord = (ContentDocumentLink) (Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{linkToRecord}).getRecords())[0];
    
            insert as user linkToRecord;

             if (Schema.SObjectType.ContentDocument.isDeletable()) {

            delete as user [select Id from ContentDocument where title =: theTitle WITH SECURITY_ENFORCED];
             }
        } 
        catch (DmlException DMLE) {
            system.debug('Failed to insert fileToUpload, error is: ' + dmle.getMessage());
        }
    }

    @AuraEnabled
    public static void attachPDF(String jsonString, String parentId){
        PageReference pdfPage = Page.generateFormDataPDF;
        pdfPage.getParameters().put('pdfDetails', jsonString);

        Blob pdfBlob;

        if (!Test.isRunningTest()) { 
            pdfBlob = pdfPage.getContent(); 
        } else { 
            pdfBlob = Blob.valueOf('Some Text for a boring PDF file...');
        }

        ContentVersion fileToUpload = new ContentVersion();
        fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
        fileToUpload.pathOnClient ='form_responses.pdf';
        fileToUpload.title = 'Form Responses';
        fileToUpload.versionData = pdfBlob;
        Database.SaveResult saveResult;
        try {
            fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];
            saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

            // Create a ContentDocument Link Record
            // First get the content document Id from ContentVersion
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id].ContentDocumentId;
    
            //Create ContentDocumentLink
            ContentDocumentLink linkToRecord = new ContentDocumentLink();
            linkToRecord.ContentDocumentId = contentDocumentId;
            linkToRecord.LinkedEntityId = parentId; // RecordID of the patent
            linkToRecord.ShareType = 'I'; // Inferred permission
            linkToRecord = (ContentDocumentLink)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{linkToRecord}).getRecords())[0];    
            insert as user linkToRecord;
        } 
        catch (DmlException DMLE) {
            system.debug('Failed to insert fileToUpload, error is: ' + dmle.getMessage());
        }
    }

    /* @AuraEnabled
    public static void updateStagingApplicationStatus(String recordId, String applicationId){
        update (new Application_Staging__c(Id = recordId, Conversion_Status__c='Converted', Application__c = applicationId));

        //Update Application Date on Referral(Application) record

        Date pendingApplicationDate = [select Id, Application_Date__c from Application_Staging__c where id =: recordId limit 1].Application_Date__c;

        if(pendingApplicationDate != null){
            update (new Referral__c(Id = applicationId, Application_Date__c = pendingApplicationDate, Intake_Date__c = pendingApplicationDate));
        }
    } */

    /* @AuraEnabled
    public static Application_Staging__c getStagingApplicationConversionStatus(String recordId){
        return [select Id, Conversion_Status__c, Form_Id__c, isExternalReferral__c, primaryReason_ServId__c from Application_Staging__c where Id =: recordId limit 1];
    } */

    /* @AuraEnabled
    public static String getReferralName(String recordId){
        return [select Id, Name from Referral__c where Id =: recordId limit 1].Name;
    } */

    /* @AuraEnabled
    public static Id getServiceId (Id recId)
    {
        Id serviceId;
        Application_Staging__c astage = [select Id, primaryReason_ServId__c, Primary_Reason1__c from Application_Staging__c where Id = :recId];
        if (astage.primaryReason_ServId__c != null)
        {
            serviceId = astage.primaryReason_ServId__c;
        }
        else if (astage.Primary_Reason1__c != null)
        {
            SP_Service__c serv = [select Id, Name from SP_Service__c where Name = :astage.Primary_Reason1__c LIMIT 1];
            serviceId = serv.Id;
        }

        return serviceId;
    } */

    /* @AuraEnabled
    public static Boolean isUserWithService (Id servId)
    {
        Boolean returnValue = false;
        Id pId = UserInfo.getProfileId();
        Profile p = [SELECT Id, Name from Profile where Id = :pId];
        if (p.Name.contains('Admin'))
        {
            returnValue = true;
        }
        else
        {
            returnValue = CheckAccessUtil.isUserWithService(UserInfo.getUserId(), servId);
        }

        return returnValue;
    } */

    @AuraEnabled
    public static void attachDocsToApplication(String applicationId, String stagingId){
        List<ContentDocumentLink> cdlList = [select Id, LinkedEntityId, ContentDocumentId, Visibility, shareType from ContentDocumentLink where LinkedEntityId =: stagingId WITH SECURITY_ENFORCED];

        List<ContentDocumentLink> cdListToBeInserted = new List<ContentDocumentLink>();

        if(cdlList!=null && cdlList.size()>0){
            for(ContentDocumentLink cdl:cdlList){
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = applicationId;
                conDocLink.ContentDocumentId = cdl.ContentDocumentId;
                conDocLink.Visibility = cdl.Visibility;
                conDocLink.shareType = cdl.shareType; // V = Viewer, C = Collaborator, I = Inferred
                cdListToBeInserted.add(conDocLink);
            }

            if(cdListToBeInserted!=null && cdListToBeInserted.size()>0){
                cdListToBeInserted = (List<ContentDocumentLink>)(Security.stripInaccessible(AccessType.CREATABLE, cdListToBeInserted).getRecords());    
                insert as user cdListToBeInserted;
            }
        }
    }

     /*
        * @date        : 01/06/2023
        * @description : isEligibleServiceContact() for given service whether current logged in user is eligible for provdied service or not 
        * @param2      : spServId - Id of SP Service
        * @return      : Boolean
        * Change Log   : UST-00240/IS-00476
    */
    /* @AuraEnabled
    public static Boolean isEligibleServiceContact(String spServId){
      
        userDetails.userWrapper userData  = userDetails.getUserInfo ((String)UserInfo.getUserId());
        String userRole = userData.userRole;
        if(userRole == 'Superuser' || userRole == 'Admin'){
            return true;
        }
        if(userRole == 'Read Only')
            return false;

        List<Service_Contact__c> serContactList = [select Id, Name, SP_Service__c, Staff_ID__c from Service_Contact__c where Staff_ID__c = :userData.staffId and SP_Service__c =:spServId];
        system.debug('serContactList>>' + serContactList);
        if(serContactList !=null & serContactList.size() > 0 )
            return true;
        else
            return false;

    } */


    /*
        * @date        : 01/05/2023
        * @description : Get List of Primary Reasons
        * @param1      : providerId - Id of Provider/Facility Account
        * @param2      : spServId - Id of SP Service
        * @return      : List of PrimReasonWrapper class
        * Change Log   : UST-00240
    */
    /* @AuraEnabled
    public static String getPrimaryReason (Id spServId)
    {
        String queryFields = 'SELECT Id, Name,  Confidential__c, Service_Provider__c, Service_Provider__r.Name FROM SP_Service__c';
        
        //String whereClause = ' WHERE Modules_Used__c Includes (\'Referral\') and InActive__c = False';
        String finalCondition = '';
        String fullQuery = '';
        String serviceDetail = '';

        if (spServId != null)
        {
            finalCondition = ' WHERE Id = :spServId LIMIT 1';
        }
        else
        {
            return null;
        }

        fullQuery = queryFields +   finalCondition;
        system.debug('#### query: ' + fullQuery);

        List<SP_Service__c> listSPServ = Database.query(fullQuery);
        system.debug('#### listSPServ: ' + listSPServ);
        
        if (listSPServ != null && listSPServ.size() > 0)
        {   
            serviceDetail = listSPServ[0].Name + ' - ' + listSPServ[0].Service_Provider__r.Name ;
            if(listSPServ[0].Confidential__c)
                serviceDetail = serviceDetail + ' : Confidential';
        }
        
        system.debug('serviceDetail>>' + serviceDetail);
        return serviceDetail;
    } */


    //UST-00422
    @AuraEnabled
    public static string attachPrintJsonToRecord(String jsonData, String recordId, String formId){
        String formName = [Select Id, Form_Name__c from form__c where Id =: formId WITH SECURITY_ENFORCED].Form_Name__c;
        String resp;
        DateTime dt = Datetime.now();
        String strTimeInAMorPM = dt.format('MM/dd/yyyy hh:mm a');
        ContentVersion fileToUpload = new ContentVersion();
        fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
        fileToUpload.pathOnClient ='jsonForPrint.txt';
        fileToUpload.title = formId+'_'+strTimeInAMorPM+'_'+'_Print_JSON';
        fileToUpload.Description = formName+' '+strTimeInAMorPM;
        fileToUpload.FirstPublishLocationId = recordId;
        fileToUpload.versionData = Blob.valueOf(jsonData);
        Database.SaveResult saveResult;
        fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];

        saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

        /* Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id].ContentDocumentId;

        //Create ContentDocumentLink
        ContentDocumentLink linkToRecord = new ContentDocumentLink();
        linkToRecord.ContentDocumentId = contentDocumentId;
        linkToRecord.LinkedEntityId = recordId;
        linkToRecord.Visibility = 'AllUsers'; 
        linkToRecord.ShareType = 'V'; // Inferred permission

        insert linkToRecord; */

        resp = formId+'_'+strTimeInAMorPM;

        return resp;
    }

    @AuraEnabled
    public static List<PicklistWrapper> getFormsForPrimaryObject(String objectApiName, Boolean isListView){
        List<PicklistWrapper> respList = new List<PicklistWrapper>();
        List<caresp__Form__c> formsList = new List<caresp__Form__c>();

        formsList = [select Id, Name, Form_Name__c, Prefill_Fields__c, Create_PDF_Only__c from Form__c where Object_Name_for_Prefill_Fields__c =: objectApiName WITH SECURITY_ENFORCED];

        /* if(objectApiName == 'Form__c'){
            formsList = [select Id, Name, Form_Name__c, Prefill_Fields__c, Create_PDF_Only__c from Form__c where Prefill_Fields__c = false WITH SECURITY_ENFORCED];
        }else{
            if(isListView){
                formsList = [select Id, Name, Form_Name__c, Prefill_Fields__c, Create_PDF_Only__c from Form__c where Object_Name_for_Prefill_Fields__c =: objectApiName AND Prefill_Fields__c = false WITH SECURITY_ENFORCED];
            }else{
                formsList = [select Id, Name, Form_Name__c, Prefill_Fields__c, Create_PDF_Only__c from Form__c where Object_Name_for_Prefill_Fields__c =: objectApiName WITH SECURITY_ENFORCED];
            }
        } */

        if(formsList != null && formsList.size() > 0){
            for(caresp__Form__c formRec:formsList){
                PicklistWrapper wrpObj = new PicklistWrapper();
                wrpObj.label = formRec.caresp__Prefill_Fields__c == true?formRec.caresp__Form_Name__c+' (Prefill Fields)':formRec.caresp__Form_Name__c;
                wrpObj.label = formRec.caresp__Create_PDF_Only__c == true?wrpObj.label+' (PDF Only)':wrpObj.label;
                wrpObj.value = formRec.Id;
                respList.add(wrpObj);
            }
        }

        return respList;
    }

    @AuraEnabled
    public static String createDependentFormsTrackerRecord(String parentFormJSId, String parentFormId, String dependentFormId, Boolean required){
        String theId;
        List<caresp__Dependent_Forms_Tracker__c> dependentFormList = [select Id from Dependent_Forms_Tracker__c where Parent_Form_JS_Id__c =:parentFormJSId AND Parent_Form_Id__c =:parentFormId AND Dependent_Form_Id__c =:dependentFormId WITH SECURITY_ENFORCED];
        caresp__Dependent_Forms_Tracker__c newRec = new caresp__Dependent_Forms_Tracker__c(caresp__Parent_Form_JS_Id__c = parentFormJSId, caresp__Parent_Form_Id__c = parentFormId, caresp__Dependent_Form_Id__c = dependentFormId, caresp__Required__c = required);
        if(dependentFormList.size() == 0 && Schema.sObjectType.Dependent_Forms_Tracker__c.isCreateable()){
            newRec = (caresp__Dependent_Forms_Tracker__c)(Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Dependent_Forms_Tracker__c>{newRec}).getRecords())[0];
            insert as user newRec;
            theId = newRec.Id;
        }else{
            theId = dependentFormList[0].Id;
        }

        return theId;
    }

    @AuraEnabled
    public static void deleteDependentFormsTrackerRecord(String parentFormJSId, String parentFormId, String dependentFormId, Boolean required){
        List<caresp__Dependent_Forms_Tracker__c> dependentFormList = [select Id from Dependent_Forms_Tracker__c where Parent_Form_JS_Id__c =:parentFormJSId AND Parent_Form_Id__c =:parentFormId AND Dependent_Form_Id__c =:dependentFormId WITH SECURITY_ENFORCED];
            
        if(dependentFormList.size() != 0 &&  caresp__Dependent_Forms_Tracker__c.sObjectType.getDescribe().isDeletable()){
            delete as user dependentFormList[0];
        }
    }

    @AuraEnabled
    public static List<caresp__Dependent_Forms_Tracker__c> getTrackerRecordStatus(String parentJSId){
        List<caresp__Dependent_Forms_Tracker__c> trackerList = [select Id, Completed__c from Dependent_Forms_Tracker__c where Parent_Form_JS_Id__c =: parentJSId and Completed__c = true WITH SECURITY_ENFORCED];
        return trackerList;
    }


    @AuraEnabled
    public static string moveJsonsAndDeleteTrackerRecords(String primaryRecordId, List<String> trackerRecordIds){
        List<ContentDocumentLink> cdRecords = new List<ContentDocumentLink>();
        List<ContentDocumentLink> recordsToBeInserted = new List<ContentDocumentLink>();
        if(trackerRecordIds!=null && trackerRecordIds.size()>0){
            cdRecords = [select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId in: trackerRecordIds WITH SECURITY_ENFORCED];
            if(cdRecords!=null && cdRecords.size()>0){
                for(ContentDocumentLink cdRec : cdRecords){
                    ContentDocumentLink tempRec = new ContentDocumentLink();
                    tempRec.LinkedEntityId = primaryRecordId;
                    tempRec.ContentDocumentId = cdRec.ContentDocumentId;
                    tempRec.Visibility = 'AllUsers'; 
                    tempRec.ShareType = 'V'; // Inferred permission
                    recordsToBeInserted.add(tempRec);
                }
            }
        }
        recordsToBeInserted = (List<ContentDocumentLink>)(Security.stripInaccessible(AccessType.CREATABLE, recordsToBeInserted).getRecords());
        insert as user recordsToBeInserted;
        if(caresp__Dependent_Forms_Tracker__c.sObjectType.getDescribe().isDeletable())
        {
            delete as user [select Id from Dependent_Forms_Tracker__c where Id in: trackerRecordIds WITH SECURITY_ENFORCED];
            
        }
        
        return 'Done';
    }

    /* @AuraEnabled
    public static List<ClientEmailWrapper> getClientAndEmails(String recordId, String objectApi){
        List<ClientEmailWrapper> resp = new List<ClientEmailWrapper>();

        if(objectApi == 'Referral__c'){
            List<Client_Referral__c> clientReferralList = [Select Id, Client_Name_Referral__c, Client__r.Email__c from Client_Referral__c where Referral__c =: recordId];

            if(clientReferralList!=null && clientReferralList.size() > 0){
                for(Client_Referral__c cr: clientReferralList){
                    ClientEmailWrapper tempWrap = new ClientEmailWrapper();
                    tempWrap.label = cr.Client_Name_Referral__c;
                    tempWrap.value = cr.Client_Name_Referral__c+'#'+cr.Client__r.Email__c;
                    resp.add(tempWrap);
                }
            }
        }else if(objectApi == 'Client_Service__c'){
            String referralId = [select Id, Referral__c from Client_Service__c where Id =: recordId].Referral__c;

            List<Client_Referral__c> clientReferralList = [Select Id, Client_Name_Referral__c, Client__r.Email__c from Client_Referral__c where Referral__c =: referralId];

            if(clientReferralList!=null && clientReferralList.size() > 0){
                for(Client_Referral__c cr: clientReferralList){
                    ClientEmailWrapper tempWrap = new ClientEmailWrapper();
                    tempWrap.label = cr.Client_Name_Referral__c;
                    tempWrap.value = cr.Client_Name_Referral__c+'#'+cr.Client__r.Email__c;
                    resp.add(tempWrap);
                }
            }
        }else if(objectApi == 'Client__c'){
            
            List<Client__c> clientList = [Select Id, Full_Name__c, Email__c from Client__c where Id =: recordId];

            if(clientList!=null && clientList.size() > 0){
                for(Client__c cr: clientList){
                    ClientEmailWrapper tempWrap = new ClientEmailWrapper();
                    tempWrap.label = cr.Full_Name__c;
                    tempWrap.value = cr.Full_Name__c+'#'+cr.Email__c;
                    resp.add(tempWrap);
                }
            }
        }


        return resp;
        
    } */

    /* @AuraEnabled
    public static LwcResponse sendFormToClient(String emailId, String formId, String recordId, String objectApi){
        LwcResponse resp = new LwcResponse();
        Boolean isSuccess = false;
        String requestInfoSiteUrl = Label.Request_Info_Site_URL;
        String serviceName;
        String emailBody;
        String encodedFormId = processEncryption(formId);
        String encodedRecordId = processEncryption(recordId);
        System.debug('encodedFormId >> '+encodedFormId);
        System.debug('encodedRecordId >> '+encodedRecordId);
        String formLink;

        OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress limit 1];

        String emailSubject = 'Travis County Health and Human Service Form sent for completion';

        List<Form__c> formList = [Select Id, Form_Name__c, Prefill_Fields__c from form__c where id =: formId];

        if(objectApi == 'Referral__c'){
            serviceName = [Select Id, Primary_Reason_F__c from Referral__c where id =: recordId].Primary_Reason_F__c;
        }else if(objectApi == 'Client_Service__c'){
            serviceName = [Select Id, Service_Name_F__c from Client_Service__c where id =: recordId].Service_Name_F__c;
        }

        formLink = '<a href='+requestInfoSiteUrl+'/clientform?formId='+encodedFormId+'&recordId='+encodedRecordId+'&objectApiName='+objectApi+'&isPrefillFieldsForm='+formList[0].Prefill_Fields__c+'&clientEmail='+emailId+'>'+formList[0].Form_Name__c+'</a>';

        if(objectApi == 'Client__c'){
            emailBody = 'We have sent <b>'+formList[0].Form_Name__c+'</b> to complete electronically. Click the link below to open the Form in another browser tab. Upon completion of all mandatory fields, click the Submit button and your Assigned Worker will be notified that you have completed the Form.<br /> <br /> '+formLink;
        }else{
            emailBody = 'We have sent <b>'+formList[0].Form_Name__c+'</b> for <b>'+serviceName+'</b> to complete electronically. Click the link below to open the Form in another browser tab. Upon completion of all mandatory fields, click the Submit button and your Assigned Worker will be notified that you have completed the Form..<br /> <br /> '+formLink;
        }

        List<Messaging.SingleEmailMessage> prepMailList = new List<Messaging.SingleEmailMessage>();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        System.debug('emailBody >> '+emailBody);
        email.setOrgWideEmailAddressId(owa.id); 
        email.setSubject(emailSubject);
        email.setHtmlBody(emailBody);
        if(String.isNotBlank(emailId)){
            email.setToAddresses(new List<String>{emailId});
        }else{
            resp.isSuccess = false;
            resp.error = 'No email id available for the selected Client.';
            return resp;
        }

        prepMailList.add(email);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(prepMailList);

        for (Messaging.SendEmailResult mr : results) 
        {
            if (mr.isSuccess()) {
                resp.isSuccess = true;
                resp.url = '';
            }  else {
                resp.isSuccess = false;
                // Operation failed, so get all errors                
                for(Messaging.SendEmailError err : mr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('fields that affected this error: ' + err.getFields());
                    resp.error = err.getMessage();
                }
            }
        }

        System.debug('resp >> '+resp);
        return resp;
    }

    @AuraEnabled
    public static string getDecryptedFormAndRecordId(String encryptedFormId, String encryptedRecordId){
        System.debug('>> '+encryptedFormId);
        System.debug('>> '+encryptedRecordId);
        return processDecryption(encryptedFormId)+'#'+processDecryption(encryptedRecordId);
    }

    public static string processEncryption(String fields){ 

        Blob cryptoKey = getEncryptionDecryptionKey(); 
        Blob data = Blob.valueOf(fields); 
        Blob encryptedData = Crypto.encryptWithManagedIV('AES128', cryptoKey, data ); 
        string b64Data = EncodingUtil.base64Encode (encryptedData);  
        return b64Data; 

    } 

    public static String processDecryption(string encryptedData){ 

        String decryptedData; 
        Blob data = EncodingUtil.base64Decode (encryptedData); 
        Blob privateKey = getEncryptionDecryptionKey();
        String expMsg; 
        try{ 
            Blob dataToDecrypt = Crypto.decryptWithManagedIV ('AES128', privateKey, data); 
            decryptedData = dataToDecrypt.toString(); 
        } 

        catch(Exception e){ 
           expMsg = e.getMessage();
        } 
        return (string.isEmpty(expMsg) ?  decryptedData :  null);  

    }

    public static Blob getEncryptionDecryptionKey(){
        StaticResource static_resource = [SELECT Id, SystemModStamp, Name, Body
                                  FROM StaticResource 
                                  WHERE Name = 'Crypto_Key'
                                  LIMIT 1];

        return static_resource.Body;
    }

    @AuraEnabled
    public static string sendConfirmationToAssignedWorker(String formId, String recordId, String objectApi, String clientEmail){
        
        List<Form__c> formList = [select Id, Form_Name__c from Form__c where Id =: formId];
        String recordName;
        String awEmail;
        String recordLink;
        String org_Url = Label.Org_URL;
        String hhsAdminEmail = Label.HHS_Admin_Email;

        if(objectApi == 'Referral__c'){
            List<Referral__c> referralList = [select Id, Name, Assigned_Worker__r.Email__c from Referral__c where id =: recordId];
            recordName = referralList[0].Name;
            awEmail = referralList[0].Assigned_Worker__r.Email__c;
            System.debug(' >> '+recordName);
            System.debug(' >> '+awEmail);
        }else if(objectApi == 'Client_Service__c'){
            List<Client_Service__c> asList = [select Id, Name, AssignWorker_Email__c from Client_Service__c where id =:  recordId];
            recordName = asList[0].Name;
            awEmail = asList[0].AssignWorker_Email__c;
            System.debug(' >> '+recordName);
            System.debug(' >> '+awEmail);
        }

        List<Messaging.SingleEmailMessage> prepMailList = new List<Messaging.SingleEmailMessage>();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = :hhsAdminEmail limit 1];

        System.debug('>> '+owa);

        String emailSubject = 'Form sent electronically has been completed';

        recordLink = '<a href='+org_Url+recordId+'>'+recordName+'</a>';

        String emailBody = 'The '+formList[0].Form_Name__c+' you sent electronically to '+clientEmail+' has been completed on '+System.now()+'. Review the completed Form by clicking the "Print Form" button of the '+recordLink;

        email.setOrgWideEmailAddressId(owa.id); 
        email.setSubject(emailSubject);
        email.setHtmlBody(emailBody);
        email.setToAddresses(new String[] {awEmail});

        prepMailList.add(email);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(prepMailList);

        for (Messaging.SendEmailResult mr : results) 
        {
            if (mr.isSuccess()) {
                System.debug('Sent Successfully');
            }  else {
                // Operation failed, so get all errors                
                for(Messaging.SendEmailError err : mr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        return 'Sent';
    } */

    @AuraEnabled
    public static void markAdditionalFormComplete(String trackerRecordId){
        update as user (Security.stripInaccessible(AccessType.UPDATABLE, new List<caresp__Dependent_Forms_Tracker__c>{new caresp__Dependent_Forms_Tracker__c(Id=trackerRecordId, caresp__Completed__c = true)}).getRecords());
    }

    public class LwcResponse{
        @AuraEnabled public Boolean isSuccess {get;set;}
        @AuraEnabled public String error {get;set;}
        @AuraEnabled public String url {get;set;}
    }

    public class ClientEmailWrapper{
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
    }

    public class FormsParentParser {
        @AuraEnabled
        public String objectName {get;set;}
        @AuraEnabled
        public String recordType {get;set;}
        @AuraEnabled
        public String childFieldApi {get;set;}
        @AuraEnabled
        public List<FieldValue> fieldValue {get;set;}
    }

    public class FormsPrimaryParser {
        @AuraEnabled
        public String objectName {get;set;}
        @AuraEnabled
        public String recordType {get;set;}
        @AuraEnabled
        public List<Parents> parents {get;set;}
        @AuraEnabled
        public List<FieldValue> fieldValue {get;set;}
    }

    public class Parents {
        @AuraEnabled
        public String parentApi {get;set;}
        @AuraEnabled
        public String parentFieldApi {get;set;}
        @AuraEnabled
        public String parentId {get;set;}
    }

    /* public class FieldValue {
        @AuraEnabled
        public String fieldApi {get;set;}
        @AuraEnabled
        public String inputValue {get;set;}
        @AuraEnabled
        public Integer recordIdentifier {get;set;}
    } */

    // public class ResponseParser {
    //     @AuraEnabled
    //     public String fieldApi {get;set;}
    //     @AuraEnabled
    //     public List<String> inputValue {get;set;}
    // }

    public class FormsMultiChildParser {
        @AuraEnabled
        public String objectName {get;set;}
        @AuraEnabled
        public String recordType {get;set;}
        @AuraEnabled
        public List<Parents> parents {get;set;}
        @AuraEnabled
        public List<RecordFieldValue> fieldValue {get;set;}
    }

    public class RecordFieldValue {
        @AuraEnabled
        public String fieldApi {get;set;}
        @AuraEnabled
        public String inputValue {get;set;}
        @AuraEnabled
        public Integer recordIdentifier {get;set;}
    }

    public class PicklistWrapper {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
    }

    public class RecordData {
        public String objectName;
        public String recordType;
        public List<ParentData> parents;
        public List<FieldValue> fieldValue;
        public Integer recordIdentifier;
    
        // Constructor for convenience
        public RecordData() {}
    
        public RecordData(String objectName, String recordType, List<ParentData> parents, List<FieldValue> fieldValue) {
            this.objectName = objectName;
            this.recordType = recordType;
            this.parents = parents;
            this.fieldValue = fieldValue;
        }
    }
    
    public class ParentData {
        public String parentApi;
        public String parentFieldApi;
        public String parentId;
    
        // Constructor for convenience
        public ParentData(String parentApi, String parentFieldApi) {
            this.parentApi = parentApi;
            this.parentFieldApi = parentFieldApi;
        }
    }
    
    public class FieldValue {
        @AuraEnabled
        public String fieldApi;
        @AuraEnabled
        public String inputValue;
        @AuraEnabled
        public Integer recordIdentifier;
    
        // Constructor for convenience
        public FieldValue(String fieldApi, String inputValue) {
            this.fieldApi = fieldApi;
            this.inputValue = inputValue;
        }
    }

    public class InsertResult {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public String failedObjectName;
        @AuraEnabled
        public Id primaryRecordId;
    }
}