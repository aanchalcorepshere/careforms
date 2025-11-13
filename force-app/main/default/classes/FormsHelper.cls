public with sharing class FormsHelper {
    private static final String MASTER_RECORD_TYPE_ID = '012000000000000AAA';

    @AuraEnabled
    public static InsertResult saveObjectStructure(String params) {
        InsertResult result = new InsertResult();
        if (String.isBlank(params)) {
            result.errorMessage = 'Input parameters cannot be null or empty.';
            return result;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            RequestPayload payload = parsePayload(params);
            validatePayload(payload);

            SchemaCache schemaCache = new SchemaCache();
            schemaCache.prime(payload);

            InsertRegistry registry = new InsertRegistry();

            if (!payload.parents.isEmpty()) {
                processRecordBlock(payload.parents, schemaCache, registry);
            }

            if (payload.primary != null) {
                processRecordBlock(new List<RecordData>{ payload.primary }, schemaCache, registry);
            }

            if (!payload.children.isEmpty()) {
                processRecordBlock(payload.children, schemaCache, registry);
            }

            if (!payload.grandchildren.isEmpty()) {
                processRecordBlock(payload.grandchildren, schemaCache, registry);
            }

            result.isSuccess = true;
            if (payload.primary != null && !String.isBlank(payload.primary.objectName)) {
                String primaryObject = normalizeObjectName(payload.primary.objectName);
                result.primaryRecordId = registry.lookup(primaryObject, payload.primary.recordIdentifier);
            }
            result.recordIdsByObject = registry.snapshot();
            return result;
        } catch (RecordSaveException rse) {
            Database.rollback(sp);
            result.isSuccess = false;
            result.errorMessage = rse.getMessage();
            result.failedObjectName = rse.objectName;
            return result;
        } catch (Exception e) {
            Database.rollback(sp);
            result.isSuccess = false;
            result.errorMessage = sanitizeException(e);
            result.failedObjectName = extractFailedObjectName(e);
            return result;
        }
    }

    private static void processRecordBlock(
        List<RecordData> definitions,
        SchemaCache schemaCache,
        InsertRegistry registry
    ) {
        if (definitions == null || definitions.isEmpty()) {
            return;
        }

        List<PreparedRecord> preparedRecords = new List<PreparedRecord>();
        for (RecordData definition : definitions) {
            preparedRecords.addAll(prepareRecords(definition, schemaCache));
        }
        if (preparedRecords.isEmpty()) {
            return;
        }

        applyParentReferences(preparedRecords, registry, schemaCache);
        performDml(preparedRecords, registry, schemaCache);
    }

    private static void performDml(
        List<PreparedRecord> preparedRecords,
        InsertRegistry registry,
        SchemaCache schemaCache
    ) {
        Map<String, List<PreparedRecord>> createGroups = new Map<String, List<PreparedRecord>>();
        Map<String, List<PreparedRecord>> updateGroups = new Map<String, List<PreparedRecord>>();

        for (PreparedRecord record : preparedRecords) {
            String objectName = record.getObjectName();
            if (record.isUpdateOperation()) {
                if (!updateGroups.containsKey(objectName)) {
                    updateGroups.put(objectName, new List<PreparedRecord>());
                }
                updateGroups.get(objectName).add(record);
            } else {
                if (!createGroups.containsKey(objectName)) {
                    createGroups.put(objectName, new List<PreparedRecord>());
                }
                createGroups.get(objectName).add(record);
            }
        }

        for (String objectName : createGroups.keySet()) {
            enforceObjectAccess(schemaCache.getDescribe(objectName), true, false);
            List<PreparedRecord> recordGroup = createGroups.get(objectName);
            List<SObject> records = sanitizeRecordsForDml(recordGroup, AccessType.CREATABLE);
            if (records.isEmpty()) {
                continue;
            }
            Database.SaveResult[] saveResults = Database.insert(records, true);
            handleDmlResults(saveResults, recordGroup, registry);
        }

        for (String objectName : updateGroups.keySet()) {
            enforceObjectAccess(schemaCache.getDescribe(objectName), false, true);
            List<PreparedRecord> recordGroup = updateGroups.get(objectName);
            List<SObject> records = sanitizeRecordsForDml(recordGroup, AccessType.UPDATABLE);
            if (records.isEmpty()) {
                continue;
            }
            Database.SaveResult[] saveResults = Database.update(records, true);
            handleDmlResults(saveResults, recordGroup, registry);
        }
    }

    private static void handleDmlResults(
        Database.SaveResult[] saveResults,
        List<PreparedRecord> recordGroup,
        InsertRegistry registry
    ) {
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult sr = saveResults[i];
            PreparedRecord prepared = recordGroup[i];
            if (!sr.isSuccess()) {
                Database.Error firstError = sr.getErrors()[0];
                throw new RecordSaveException(
                    prepared.getObjectName(),
                    firstError != null ? firstError.getMessage() : 'Unexpected error while saving records.'
                );
            }
            Id savedId = sr.getId();
            prepared.record.put('Id', savedId);
            registry.register(prepared.getObjectName(), prepared.identifier, savedId);
        }
    }

    private static List<SObject> collectForDml(List<PreparedRecord> recordGroup) {
        List<SObject> records = new List<SObject>();
        for (PreparedRecord prepared : recordGroup) {
            records.add(prepared.record);
        }
        return records;
    }

    private static List<SObject> sanitizeRecordsForDml(
        List<PreparedRecord> recordGroup,
        AccessType accessType
    ) {
        if (recordGroup == null || recordGroup.isEmpty()) {
            return new List<SObject>();
        }

        List<SObject> records = collectForDml(recordGroup);
        SObjectAccessDecision accessDecision = Security.stripInaccessible(accessType, records);
        List<SObject> sanitizedRecords = accessDecision.getRecords();

        if (!accessDecision.getRemovedFields().isEmpty()) {
            throw new SecurityException('Insufficient field-level access to save records.');
        }

        for (Integer index = 0; index < sanitizedRecords.size(); index++) {
            recordGroup[index].record = sanitizedRecords[index];
        }

        return sanitizedRecords;
    }

    private static void applyParentReferences(
        List<PreparedRecord> preparedRecords,
        InsertRegistry registry,
        SchemaCache schemaCache
    ) {
        for (PreparedRecord prepared : preparedRecords) {
            if (prepared.source.parents == null) {
                continue;
            }

            Map<String, Schema.SObjectField> fieldMap = schemaCache.getFieldMap(prepared.getObjectName());
            for (ParentData parentData : prepared.source.parents) {
                if (parentData == null || String.isBlank(parentData.parentApi)) {
                    continue;
                }

                String fieldApi = extractFieldApi(parentData.parentFieldApi);
                if (String.isBlank(fieldApi)) {
                    continue;
                }

                Schema.SObjectField fieldRef = fieldMap.get(fieldApi);
                if (fieldRef == null) {
                    throw new AuraHandledException(
                        'Invalid relationship field ' + fieldApi + ' on ' + prepared.getObjectName()
                    );
                }

                Id parentId = resolveParentId(parentData, registry, prepared.identifier);
                if (parentId == null) {
                    throw new AuraHandledException(
                        'Unable to resolve parent Id for ' + parentData.parentApi + ' while creating ' + prepared.getObjectName()
                    );
                }
                prepared.record.put(fieldApi, parentId);
            }
        }
    }

    private static Id resolveParentId(
        ParentData parentData,
        InsertRegistry registry,
        Integer fallbackIdentifier
    ) {
        if (parentData == null) {
            return null;
        }
        if (!String.isBlank(parentData.parentId)) {
            return parseId(parentData.parentId);
        }

        String parentObject = normalizeObjectName(parentData.parentApi);
        Integer identifier = parentData.parentRecordIdentifier != null
            ? parentData.parentRecordIdentifier
            : fallbackIdentifier;

        Id resolved = registry.lookup(parentObject, identifier);
        if (resolved == null && identifier != null) {
            resolved = registry.lookup(parentObject, null);
        }
        return resolved;
    }

    private static List<PreparedRecord> prepareRecords(RecordData data, SchemaCache schemaCache) {
        List<PreparedRecord> results = new List<PreparedRecord>();
        if (data == null || String.isBlank(data.objectName)) {
            return results;
        }

        String objectName = normalizeObjectName(data.objectName);
        Schema.SObjectType sobjectType = schemaCache.getType(objectName);
        Map<String, Schema.SObjectField> fieldMap = schemaCache.getFieldMap(objectName);

        Map<Integer, PreparedRecord> grouped = new Map<Integer, PreparedRecord>();

        if (data.fieldValue != null && !data.fieldValue.isEmpty()) {
            for (FieldValue fieldValue : data.fieldValue) {
                Integer identifier = resolveIdentifier(fieldValue != null ? fieldValue.recordIdentifier : null, data.recordIdentifier);
                PreparedRecord prepared = grouped.get(identifier);
                if (prepared == null) {
                    prepared = new PreparedRecord();
                    prepared.record = sobjectType.newSObject();
                    prepared.type = sobjectType;
                    prepared.source = data;
                    prepared.identifier = identifier;
                    applyRecordType(prepared, data);
                    grouped.put(identifier, prepared);
                }
                applyFieldValue(prepared, fieldValue, fieldMap);
            }
        }

        if (grouped.isEmpty()) {
            Integer identifier = resolveIdentifier(null, data.recordIdentifier);
            PreparedRecord prepared = new PreparedRecord();
            prepared.record = sobjectType.newSObject();
            prepared.type = sobjectType;
            prepared.source = data;
            prepared.identifier = identifier;
            applyRecordType(prepared, data);
            grouped.put(identifier, prepared);
        }

        results.addAll(grouped.values());
        return results;
    }

    private static void applyRecordType(PreparedRecord prepared, RecordData data) {
        if (prepared == null || data == null) {
            return;
        }
        if (!String.isBlank(data.recordType) && data.recordType != MASTER_RECORD_TYPE_ID) {
            prepared.record.put('RecordTypeId', data.recordType);
        }
    }

    private static void applyFieldValue(
        PreparedRecord prepared,
        FieldValue fieldValue,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (prepared == null || fieldValue == null || String.isBlank(fieldValue.fieldApi)) {
            return;
        }

        if ('Id'.equalsIgnoreCase(fieldValue.fieldApi)) {
            if (!String.isBlank(fieldValue.inputValue)) {
                prepared.record.put('Id', parseId(fieldValue.inputValue));
            }
            return;
        }

        Schema.SObjectField fieldToken = fieldMap.get(fieldValue.fieldApi);
        if (fieldToken == null) {
            throw new AuraHandledException(
                'Invalid field ' + fieldValue.fieldApi + ' on ' + prepared.getObjectName()
            );
        }

        Schema.DescribeFieldResult describeField = fieldToken.getDescribe();
        Object typedValue = convertValue(fieldValue.inputValue, describeField.getType());
        prepared.record.put(fieldValue.fieldApi, typedValue);
    }

    private static void enforceObjectAccess(
        Schema.DescribeSObjectResult describe,
        Boolean requiresCreate,
        Boolean requiresUpdate
    ) {
        if (describe == null) {
            throw new AuraHandledException('Unable to resolve described object.');
        }
        if (requiresCreate && !describe.isCreateable()) {
            throw new SecurityException('Insufficient privileges to create ' + describe.getName() + ' records.');
        }
        if (requiresUpdate && !describe.isUpdateable()) {
            throw new SecurityException('Insufficient privileges to update ' + describe.getName() + ' records.');
        }
    }

    private static Object convertValue(String inputValue, Schema.DisplayType fieldType) {
        if (fieldType == null || String.isBlank(inputValue)) {
            return String.isBlank(inputValue) ? null : inputValue;
        }

        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(inputValue);
            }
            when CURRENCY, DOUBLE, PERCENT {
                return Decimal.valueOf(inputValue);
            }
            when INTEGER {
                return Integer.valueOf(inputValue);
            }
            when LONG {
                return Long.valueOf(inputValue);
            }
            when DATE {
                return Date.valueOf(inputValue);
            }
            when DATETIME {
                return DateTime.valueOfGmt(inputValue);
            }
            when TIME {
                return parseTime(inputValue);
            }
            when ID {
                return parseId(inputValue);
            }
            when BASE64 {
                return EncodingUtil.base64Decode(inputValue);
            }
            when REFERENCE {
                return inputValue;
            }
            when else {
                return inputValue;
            }
        }
    }

    private static Time parseTime(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        List<String> parts = input.split(':');
        if (parts.size() < 3) {
            throw new AuraHandledException('Time value must be provided in HH:mm:ss format.');
        }
        try {
            Integer hours = Integer.valueOf(parts[0]);
            Integer minutes = Integer.valueOf(parts[1]);
            Integer seconds = Integer.valueOf(parts[2]);
            return Time.newInstance(hours, minutes, seconds, 0);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid time value provided.');
        }
    }

    private static Id parseId(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        try {
            return Id.valueOf(input);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid Id value supplied.');
        }
    }

    private static RecordData parseRecord(Object raw) {
        if (raw == null) {
            return null;
        }
        try {
            if (raw instanceof String) {
                String payload = ((String) raw).trim();
                if (String.isBlank(payload) || 'null'.equalsIgnoreCase(payload)) {
                    return null;
                }
                return (RecordData) JSON.deserialize(payload, RecordData.class);
            }
            return (RecordData) JSON.deserialize(JSON.serialize(raw), RecordData.class);
        } catch (Exception e) {
            throw new AuraHandledException('Unable to parse record payload.');
        }
    }

    private static List<RecordData> parseRecordList(Object raw) {
        List<RecordData> records = new List<RecordData>();
        if (raw == null) {
            return records;
        }
        try {
            if (raw instanceof String) {
                String payload = ((String) raw).trim();
                if (String.isBlank(payload) || 'null'.equalsIgnoreCase(payload)) {
                    return records;
                }
                records = (List<RecordData>) JSON.deserialize(payload, List<RecordData>.class);
            } else if (raw instanceof List<Object>) {
                records = (List<RecordData>) JSON.deserialize(JSON.serialize(raw), List<RecordData>.class);
            }
            return records;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to parse record list payload.');
        }
    }

    private static RequestPayload parsePayload(String params) {
        try {
            Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(params);
            RequestPayload payload = new RequestPayload();
            payload.primary = parseRecord(raw.get('primaryObjectList'));
            payload.parents = parseRecordList(raw.get('parentObjectList'));
            payload.children = parseRecordList(raw.get('childObjectsList'));
            payload.grandchildren = parseRecordList(raw.get('grandChildObjectList'));
            return payload;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Invalid payload format.');
        }
    }

    private static void validatePayload(RequestPayload payload) {
        if (payload == null) {
            throw new AuraHandledException('Request payload is required.');
        }

        if (
            payload.primary == null &&
            payload.parents.isEmpty() &&
            payload.children.isEmpty() &&
            payload.grandchildren.isEmpty()
        ) {
            throw new AuraHandledException('No records provided for save.');
        }

        validateRecord(payload.primary);
        for (RecordData parent : payload.parents) {
            validateRecord(parent);
        }
        for (RecordData child : payload.children) {
            validateRecord(child);
        }
        for (RecordData grandchild : payload.grandchildren) {
            validateRecord(grandchild);
        }
    }

    private static void validateRecord(RecordData data) {
        if (data == null) {
            return;
        }
        if (String.isBlank(data.objectName)) {
            throw new AuraHandledException('objectName is required for each record.');
        }
        if (data.fieldValue != null) {
            for (FieldValue value : data.fieldValue) {
                if (value == null || String.isBlank(value.fieldApi)) {
                    throw new AuraHandledException('fieldApi is required for every field value.');
                }
            }
        }
    }

    private static String sanitizeException(Exception e) {
        if (e == null) {
            return 'An unexpected error occurred.';
        }
        if (e instanceof AuraHandledException) {
            return e.getMessage();
        }
        if (e.getMessage() != null) {
            return e.getMessage();
        }
        return 'An unexpected error occurred.';
    }

    private static String extractFailedObjectName(Exception e) {
        if (e instanceof RecordSaveException) {
            return ((RecordSaveException) e).objectName;
        }
        return null;
    }

    private static Integer resolveIdentifier(Integer fieldIdentifier, Integer recordIdentifier) {
        if (fieldIdentifier != null) {
            return fieldIdentifier;
        }
        if (recordIdentifier != null) {
            return recordIdentifier;
        }
        return 0;
    }

    private static String extractFieldApi(String descriptor) {
        if (String.isBlank(descriptor)) {
            return null;
        }
        List<String> parts = descriptor.split('\\|');
        return parts.isEmpty() ? descriptor : parts[parts.size() - 1];
    }

    private static String normalizeObjectName(String objectName) {
        if (String.isBlank(objectName)) {
            return null;
        }
        if (objectName.contains('|')) {
            return objectName.split('\\|')[0];
        }
        return objectName;
    }

    private class PreparedRecord {
        public RecordData source;
        public Integer identifier;
        public SObject record;
        public Schema.SObjectType type;

        public String getObjectName() {
            return type != null ? type.getDescribe().getName() : null;
        }

        public Boolean isUpdateOperation() {
            return record != null && record.get('Id') != null;
        }
    }

    private class SchemaCache {
        private final Map<String, Schema.SObjectType> typeCache = new Map<String, Schema.SObjectType>();
        private final Map<String, Map<String, Schema.SObjectField>> fieldCache = new Map<String, Map<String, Schema.SObjectField>>();

        public void prime(RequestPayload payload) {
            if (payload == null) {
                return;
            }
            List<RecordData> all = new List<RecordData>();
            if (payload.primary != null) {
                all.add(payload.primary);
            }
            all.addAll(payload.parents);
            all.addAll(payload.children);
            all.addAll(payload.grandchildren);
            for (RecordData data : all) {
                if (data == null) {
                    continue;
                }
                getType(data.objectName);
            }
        }

        public Schema.SObjectType getType(String objectName) {
            String normalized = normalizeObjectName(objectName);
            if (String.isBlank(normalized)) {
                throw new AuraHandledException('Object name is required.');
            }
            if (!typeCache.containsKey(normalized)) {
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                if (!globalDescribe.containsKey(normalized)) {
                    throw new AuraHandledException('Unknown sObject ' + normalized + '.');
                }
                typeCache.put(normalized, globalDescribe.get(normalized));
            }
            return typeCache.get(normalized);
        }

        public Schema.DescribeSObjectResult getDescribe(String objectName) {
            return getType(objectName).getDescribe();
        }

        public Map<String, Schema.SObjectField> getFieldMap(String objectName) {
            String normalized = normalizeObjectName(objectName);
            if (!fieldCache.containsKey(normalized)) {
                fieldCache.put(normalized, getDescribe(normalized).fields.getMap());
            }
            return fieldCache.get(normalized);
        }
    }

    private class InsertRegistry {
        private final Map<String, Map<Integer, Id>> idsByObjectAndKey = new Map<String, Map<Integer, Id>>();
        private final Map<String, Id> lastInsertedByObject = new Map<String, Id>();

        public void register(String objectName, Integer identifier, Id recordId) {
            if (String.isBlank(objectName) || recordId == null) {
                return;
            }
            if (!idsByObjectAndKey.containsKey(objectName)) {
                idsByObjectAndKey.put(objectName, new Map<Integer, Id>());
            }
            Integer key = identifier == null ? 0 : identifier;
            idsByObjectAndKey.get(objectName).put(key, recordId);
            lastInsertedByObject.put(objectName, recordId);
        }

        public Id lookup(String objectName, Integer identifier) {
            if (String.isBlank(objectName)) {
                return null;
            }
            Map<Integer, Id> keyed = idsByObjectAndKey.get(objectName);
            if (keyed != null) {
                if (identifier != null && keyed.containsKey(identifier)) {
                    return keyed.get(identifier);
                }
                if (keyed.containsKey(0)) {
                    return keyed.get(0);
                }
            }
            return lastInsertedByObject.get(objectName);
        }

        public Map<String, Id> snapshot() {
            return new Map<String, Id>(lastInsertedByObject);
        }
    }

    private class RecordSaveException extends Exception {
        public String objectName;

        public RecordSaveException(String objectName, String message) {
            this.objectName = objectName;
            this.setMessage(message);
        }
    }

    private class RequestPayload {
        public RecordData primary;
        public List<RecordData> parents = new List<RecordData>();
        public List<RecordData> children = new List<RecordData>();
        public List<RecordData> grandchildren = new List<RecordData>();
    }
    

// Attaches a JSON string as a file to Salesforce for later PDF generation
@AuraEnabled
public static void attachJSONForPDF(String jsonString, String formId) {
    if (String.isNotBlank(jsonString)) {
        ContentVersion cvOBJ = new ContentVersion();
        cvOBJ.VersionData = Blob.valueOf(jsonString);
        cvOBJ.Title = UserInfo.getUserId() + '_' + formId;
        cvOBJ.PathOnClient = UserInfo.getUserId() + '_' + formId + '.txt';
        cvOBJ.Origin = 'H';
        cvOBJ.ContentLocation = 'S';
        cvOBJ = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{cvOBJ}).getRecords())[0];
        insert as user cvOBJ;
    }
}

// Generates a PDF from a Visualforce page and attaches it to a specified record
@AuraEnabled
public static void attachPdfToRecord(String formId, String parentId) {
    PageReference pdfPage = Page.generateFormDataPDF;
    String theTitle = UserInfo.getUserId() + '_' + formId;
    pdfPage.getParameters().put('theTitle', theTitle);

    Blob pdfBlob;

    if (!Test.isRunningTest()) { 
        pdfBlob = pdfPage.getContent(); 
    } else { 
        pdfBlob = Blob.valueOf('Some Text for a boring PDF file...');
    }

    ContentVersion fileToUpload = new ContentVersion();
    fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
    fileToUpload.pathOnClient = 'form_responses.pdf';
    fileToUpload.title = 'Form Responses';
    fileToUpload.versionData = pdfBlob;
    Database.SaveResult saveResult;
    try {
        fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];
        saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

        // Create a ContentDocument Link Record
        // First get the content document Id from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id WITH USER_MODE].ContentDocumentId ;
    
        //Create ContentDocumentLink
        ContentDocumentLink linkToRecord = new ContentDocumentLink();
        linkToRecord.ContentDocumentId = contentDocumentId;
        linkToRecord.LinkedEntityId = parentId;
        linkToRecord.Visibility = 'AllUsers'; 
        linkToRecord.ShareType = 'V'; // Inferred permission
        
        linkToRecord = (ContentDocumentLink)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{linkToRecord}).getRecords())[0];
    
        insert as user linkToRecord;

        if (Schema.SObjectType.ContentDocument.isDeletable()) {
            delete as user [SELECT Id FROM ContentDocument WHERE title =: theTitle WITH USER_MODE];
        }
    } 
    catch (DmlException DMLE) {
        system.debug(LoggingLevel.Error, 'Failed to insert fileToUpload, error is: ' + dmle.getMessage());
    }
}

   // Generates a PDF from a Visualforce page and attaches it to a specified parent record
@AuraEnabled
public static void attachPDF(String jsonString, String parentId) {
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
    fileToUpload.pathOnClient = 'form_responses.pdf';
    fileToUpload.title = 'Form Responses';
    fileToUpload.versionData = pdfBlob;
    Database.SaveResult saveResult;
    try {
        fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];
        saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

        // Create a ContentDocument Link Record
        // First get the content document Id from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id WITH USER_MODE].ContentDocumentId;
    
        //Create ContentDocumentLink
        ContentDocumentLink linkToRecord = new ContentDocumentLink();
        linkToRecord.ContentDocumentId = contentDocumentId;
        linkToRecord.LinkedEntityId = parentId; // RecordID of the patent
        linkToRecord.ShareType = 'I'; // Inferred permission
        linkToRecord = (ContentDocumentLink)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentDocumentLink>{linkToRecord}).getRecords())[0];    
        insert as user linkToRecord;
    } 
    catch (DmlException DMLE) {
        system.debug(LoggingLevel.Error, 'Failed to insert fileToUpload, error is: ' + dmle.getMessage());
    }
}
    
// Copies document links from a staging record to the specified application record
@AuraEnabled
public static void attachDocsToApplication(String applicationId, String stagingId) {
    List<ContentDocumentLink> cdlList = [
        SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, shareType
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :stagingId
        WITH USER_MODE
    ];

    List<ContentDocumentLink> cdListToBeInserted = new List<ContentDocumentLink>();

    if (cdlList != null && cdlList.size() > 0) {
        for (ContentDocumentLink cdl : cdlList) {
            ContentDocumentLink conDocLink = new ContentDocumentLink();
            conDocLink.LinkedEntityId = applicationId;
            conDocLink.ContentDocumentId = cdl.ContentDocumentId;
            conDocLink.Visibility = cdl.Visibility;
            conDocLink.shareType = cdl.shareType; // V = Viewer, C = Collaborator, I = Inferred
            cdListToBeInserted.add(conDocLink);
        }

        if (cdListToBeInserted != null && cdListToBeInserted.size() > 0) {
            cdListToBeInserted = (List<ContentDocumentLink>)(Security.stripInaccessible(AccessType.CREATABLE, cdListToBeInserted).getRecords());    
            insert as user cdListToBeInserted;
        }
    }
}

// Attaches a JSON file for print purposes to the specified record and returns a unique identifier
//UST-00422
@AuraEnabled
public static String attachPrintJsonToRecord(String jsonData, String recordId, String formId) {
    String formName = [SELECT Id, Form_Name__c FROM form__c WHERE Id = :formId WITH USER_MODE].Form_Name__c;
    String resp;
    DateTime dt = Datetime.now();
    String strTimeInAMorPM = dt.format('MM/dd/yyyy hh:mm a');
    ContentVersion fileToUpload = new ContentVersion();
    fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
    fileToUpload.pathOnClient = 'jsonForPrint.txt';
    fileToUpload.title = formId + '_' + strTimeInAMorPM + '_' + '_Print_JSON';
    fileToUpload.Description = formName + ' ' + strTimeInAMorPM;
    fileToUpload.FirstPublishLocationId = recordId;
    fileToUpload.versionData = Blob.valueOf(jsonData);
    Database.SaveResult saveResult;
    fileToUpload = (ContentVersion)(Security.stripInaccessible(AccessType.CREATABLE, new List<ContentVersion>{fileToUpload}).getRecords())[0];

    saveResult = Database.insert(fileToUpload, false, AccessLevel.USER_MODE);

    resp = formId + '_' + strTimeInAMorPM;

    return resp;
}

// Retrieves a list of forms for the given primary object and wraps them in PicklistWrapper objects
@AuraEnabled
public static List<PicklistWrapper> getFormsForPrimaryObject(String objectApiName, Boolean isListView) {
    List<PicklistWrapper> respList = new List<PicklistWrapper>();
    List<caresp__Form__c> formsList = new List<caresp__Form__c>();

    formsList = [SELECT Id, Name, Form_Name__c, Prefill_Fields__c, Create_PDF_Only__c 
                 FROM Form__c 
                 WHERE Object_Name_for_Prefill_Fields__c = :objectApiName 
                 WITH USER_MODE];

    if (formsList != null && formsList.size() > 0) {
        for (caresp__Form__c formRec : formsList) {
            PicklistWrapper wrpObj = new PicklistWrapper();
            wrpObj.label = formRec.caresp__Prefill_Fields__c == true ? formRec.caresp__Form_Name__c + ' (Prefill Fields)' : formRec.caresp__Form_Name__c;
            wrpObj.label = formRec.caresp__Create_PDF_Only__c == true ? wrpObj.label + ' (PDF Only)' : wrpObj.label;
            wrpObj.value = formRec.Id;
            respList.add(wrpObj);
        }
    }

    return respList;
}

// Creates a tracker record for dependent forms if one does not already exist and returns its ID
@AuraEnabled
public static String createDependentFormsTrackerRecord(String parentFormJSId, String parentFormId, String dependentFormId, Boolean required) {
    String theId;
    List<caresp__Dependent_Forms_Tracker__c> dependentFormList = [
        SELECT Id 
        FROM Dependent_Forms_Tracker__c 
        WHERE Parent_Form_JS_Id__c = :parentFormJSId 
        AND Parent_Form_Id__c = :parentFormId 
        AND Dependent_Form_Id__c = :dependentFormId 
        WITH USER_MODE
    ];
    caresp__Dependent_Forms_Tracker__c newRec = new caresp__Dependent_Forms_Tracker__c(
        caresp__Parent_Form_JS_Id__c = parentFormJSId, 
        caresp__Parent_Form_Id__c = parentFormId, 
        caresp__Dependent_Form_Id__c = dependentFormId, 
        caresp__Required__c = required
    );
    if (dependentFormList.size() == 0 && Schema.sObjectType.Dependent_Forms_Tracker__c.isCreateable()) {
        newRec = (caresp__Dependent_Forms_Tracker__c)(Security.stripInaccessible(AccessType.CREATABLE, new List<caresp__Dependent_Forms_Tracker__c>{newRec}).getRecords())[0];
        insert as user newRec;
        theId = newRec.Id;
    } else {
        theId = dependentFormList[0].Id;
    }

    return theId;
}

// Deletes an existing dependent forms tracker record if it exists and is deletable
@AuraEnabled
public static void deleteDependentFormsTrackerRecord(String parentFormJSId, String parentFormId, String dependentFormId, Boolean required) {
    List<caresp__Dependent_Forms_Tracker__c> dependentFormList = [
        SELECT Id 
        FROM Dependent_Forms_Tracker__c 
        WHERE Parent_Form_JS_Id__c = :parentFormJSId 
        AND Parent_Form_Id__c = :parentFormId 
        AND Dependent_Form_Id__c = :dependentFormId 
        WITH USER_MODE
    ];
        
    if (dependentFormList.size() != 0 && caresp__Dependent_Forms_Tracker__c.sObjectType.getDescribe().isDeletable()) {
        delete as user dependentFormList[0];
    }
}

// Retrieves all completed tracker records for a given parent JS ID
@AuraEnabled
public static List<caresp__Dependent_Forms_Tracker__c> getTrackerRecordStatus(String parentJSId) {
    List<caresp__Dependent_Forms_Tracker__c> trackerList = [
        SELECT Id, Completed__c 
        FROM Dependent_Forms_Tracker__c 
        WHERE Parent_Form_JS_Id__c = :parentJSId 
        AND Completed__c = true 
        WITH USER_MODE
    ];
    return trackerList;
}

// Moves JSON files from tracker records to the primary record and deletes the tracker records
@AuraEnabled
public static String moveJsonsAndDeleteTrackerRecords(String primaryRecordId, List<String> trackerRecordIds) {
    List<ContentDocumentLink> cdRecords = new List<ContentDocumentLink>();
    List<ContentDocumentLink> recordsToBeInserted = new List<ContentDocumentLink>();
    if (trackerRecordIds != null && trackerRecordIds.size() > 0) {
        cdRecords = [
            SELECT Id, ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :trackerRecordIds 
            WITH USER_MODE
        ];
        if (cdRecords != null && cdRecords.size() > 0) {
            for (ContentDocumentLink cdRec : cdRecords) {
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
    if (caresp__Dependent_Forms_Tracker__c.sObjectType.getDescribe().isDeletable()) {
        delete as user [
            SELECT Id 
            FROM Dependent_Forms_Tracker__c 
            WHERE Id IN :trackerRecordIds 
            WITH USER_MODE
        ];
    }
    
    return 'Done';
}

   // Marks a dependent forms tracker record as completed
@AuraEnabled
public static void markAdditionalFormComplete(String trackerRecordId) {
    update as user (Security.stripInaccessible(
        AccessType.UPDATABLE, 
        new List<caresp__Dependent_Forms_Tracker__c>{
            new caresp__Dependent_Forms_Tracker__c(Id = trackerRecordId, caresp__Completed__c = true)
        }
    ).getRecords());
}

// Wrapper for generic LWC responses
public class LwcResponse {
    @AuraEnabled public Boolean isSuccess {get;set;}
    @AuraEnabled public String error {get;set;}
    @AuraEnabled public String url {get;set;}
}

// Wrapper for client email picklist values
public class ClientEmailWrapper {
    @AuraEnabled
    public String label {get;set;}
    @AuraEnabled
    public String value {get;set;}
}

// Data parser for form parent objects
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

// Data parser for primary form objects
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

// Represents a parent record relationship for a form
public class Parents {
    @AuraEnabled
    public String parentApi {get;set;}
    @AuraEnabled
    public String parentFieldApi {get;set;}
    @AuraEnabled
    public String parentId {get;set;}
}

   
// Data parser for forms with multiple child records
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

// Represents a field-value pair for a specific record
public class RecordFieldValue {
    @AuraEnabled
    public String fieldApi {get;set;}
    @AuraEnabled
    public String inputValue {get;set;}
    @AuraEnabled
    public Integer recordIdentifier {get;set;}
}

// Wrapper for picklist options
public class PicklistWrapper {
    @AuraEnabled
    public String label {get;set;}
    @AuraEnabled
    public String value {get;set;}
}

// Container for record data, including parents and field values
public class RecordData {
        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String recordType;
        @AuraEnabled
        public List<ParentData> parents;
        @AuraEnabled
        public List<FieldValue> fieldValue;
        @AuraEnabled
        public Integer recordIdentifier;
    }

// Represents parent record reference data
public class ParentData {
        @AuraEnabled
        public String parentApi;
        @AuraEnabled
        public String parentFieldApi;
        @AuraEnabled
        public String parentId;
        @AuraEnabled
        public Integer parentRecordIdentifier;
}

// Represents a single field value with its API name and optional record identifier
public class FieldValue {
        @AuraEnabled
        public String fieldApi;
        @AuraEnabled
        public String inputValue;
        @AuraEnabled
        public Integer recordIdentifier;
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
    @AuraEnabled
    public Map<String, Id> recordIdsByObject;
}
}