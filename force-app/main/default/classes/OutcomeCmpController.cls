// Controller class to support Outcome Lightning components with data fetching methods
// including outcome details, responses, and related wrappers for UI display.
public with sharing class OutcomeCmpController {

    // Returns a list of completed Outcome__c records related to a specific recordId.
    @AuraEnabled(cacheable = true)
    public static List<caresp__Outcome__c> getOutcomes(String recordId) {
        // Input validation
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID cannot be null or empty');
        }
        
        // Validate ID format
        Id validatedRecordId;
        try {
            validatedRecordId = Id.valueOf(recordId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid record ID format');
        }
        
        try {
            return [
                select Id, Name, caresp__Assessment__c, caresp__Assessment__r.Name, 
                       format(caresp__Assessment_Date__c) AssessmentDate, caresp__Outcome__c, 
                       caresp__Color__c, caresp__Status__c, caresp__Total_Score__c, caresp__Total_Max_Score__c, 
                       createdby.Id, createdby.name, format(CreatedDate) createDate, 
                       lastmodifiedby.Id, lastmodifiedby.name, format(lastModifiedDate) editDate 
                from caresp__Outcome__c 
                where caresp__Record_Id__c = :validatedRecordId 
                  and caresp__Status__c = 'Complete' 
                  AND caresp__InActive__c = false 
                WITH USER_MODE 
                order by lastmodifieddate desc
                LIMIT 10000
            ];
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getOutcomes: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve outcomes: ' + ex.getMessage());
        }
    }

    // Returns the details of a specific Outcome__c record, including metadata and wrapper for UI display.
    @AuraEnabled(cacheable = true)
    public static OutcomeDetailsWrapper getOutcomeDetails(String outcomeId, String objName) {
        // Input validation
        if (String.isBlank(outcomeId) || String.isBlank(objName)) {
            throw new AuraHandledException('Outcome ID and object name cannot be null or empty');
        }
        
        // Validate ID format
        Id validatedOutcomeId;
        try {
            validatedOutcomeId = Id.valueOf(outcomeId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid outcome ID format');
        }
        
        try {
            system.debug(LoggingLevel.Error ,'objectName>>>> ' + objName);
            
            OutcomeDetailsWrapper respWrp = new OutcomeDetailsWrapper();
            String sfObjectName = objName;
            
            // Safe string operations
            if (String.isNotBlank(objName)) {
                if (!objName.contains('__c')) {
                    objName = objName + '__c';
                }
            }
            
            // Validate object name to prevent injection
            String sanitizedObjName = String.escapeSingleQuotes(objName);
            
            // Get Client field name, display field, and label from Custom Metadata (safely handle if not deployed yet)
            String clientFieldApi = 'caresp__Client__c';
            String clientDisplayField = 'Name';
            String clientLabel = 'Client';
            try {
                String soql = 'SELECT caresp__Additional_Lookup_Field_API_Subscriber__c, ' +
                             'caresp__Lookup_Display_Field_API_Subscriber__c, ' +
                             'caresp__Additional_Lookup_Label_Subscriber__c ' +
                             'FROM caresp__Assessment_Additional_Lookup_Config__mdt ' +
                             'WHERE caresp__Is_Active_Subscriber__c = true ' +
                             'WITH USER_MODE ' +
                             'LIMIT 1';
                List<SObject> configs = Database.query(soql);
                if (!configs.isEmpty()) {
                    // Get Additional Lookup field API
                    if (configs[0].get('caresp__Additional_Lookup_Field_API_Subscriber__c') != null) {
                        String customFieldName = String.valueOf(configs[0].get('caresp__Additional_Lookup_Field_API_Subscriber__c'));
                        if (String.isNotBlank(customFieldName)) {
                            clientFieldApi = customFieldName;
                        }
                    }
                    // Get Additional Lookup display field API
                    if (configs[0].get('caresp__Lookup_Display_Field_API_Subscriber__c') != null) {
                        String customDisplayField = String.valueOf(configs[0].get('caresp__Lookup_Display_Field_API_Subscriber__c'));
                        if (String.isNotBlank(customDisplayField)) {
                            clientDisplayField = customDisplayField;
                        }
                    }
                    // Get Additional Lookup label
                    if (configs[0].get('caresp__Additional_Lookup_Label_Subscriber__c') != null) {
                        String customLabel = String.valueOf(configs[0].get('caresp__Additional_Lookup_Label_Subscriber__c'));
                        if (String.isNotBlank(customLabel)) {
                            clientLabel = customLabel;
                        }
                    }
                }
            } catch (Exception e) {
                // Custom Metadata Type may not exist yet, use defaults
                System.debug(LoggingLevel.INFO, 'Custom Metadata Type not found, using default fields: ' + e.getMessage());
            }
            
            // Check if the client field exists on Outcome object before querying
            Boolean includeClientField = false;
            String clientRelationshipField = '';
            Boolean isClientFieldLookup = false;
            try {
                Schema.SObjectType outcomeType = Schema.getGlobalDescribe().get('caresp__Outcome__c');
                if (outcomeType != null) {
                    Map<String, Schema.SObjectField> fieldMap = outcomeType.getDescribe().fields.getMap();
                    if (fieldMap.containsKey(clientFieldApi) && fieldMap.get(clientFieldApi).getDescribe().isAccessible()) {
                        includeClientField = true;
                        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(clientFieldApi).getDescribe();
                        isClientFieldLookup = (fieldDescribe.getType() == Schema.DisplayType.REFERENCE);
                        // Only build relationship field if it's a lookup field
                        if (isClientFieldLookup) {
                            // Build Client relationship field name (e.g., caresp__Client__r.Name or caresp__Client__r.CustomField__c)
                            clientRelationshipField = clientFieldApi.replace('__c', '__r.' + String.escapeSingleQuotes(clientDisplayField));
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.INFO, 'Error checking client field existence, excluding client fields from query: ' + e.getMessage());
            }
            
            // Check if caresp__Associated_Record__c field exists and is accessible
            Boolean includeAssociatedRecord = false;
            String associatedRecordRelationshipName = null;
            String associatedRecordTargetObject = null;
            try {
                Schema.SObjectType outcomeType = Schema.getGlobalDescribe().get('caresp__Outcome__c');
                if (outcomeType != null) {
                    Map<String, Schema.SObjectField> fieldMap = outcomeType.getDescribe().fields.getMap();
                    if (fieldMap.containsKey('caresp__Associated_Record__c')) {
                        Schema.DescribeFieldResult fieldDescribe = fieldMap.get('caresp__Associated_Record__c').getDescribe();
                        if (fieldDescribe.isAccessible()) {
                            includeAssociatedRecord = true;
                            // Get the relationship name and target object
                            List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                            if (!referenceTo.isEmpty()) {
                                associatedRecordTargetObject = referenceTo[0].getDescribe().getName();
                                // Get relationship name - use getRelationshipName() which returns null if no relationship
                                associatedRecordRelationshipName = fieldDescribe.getRelationshipName();
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.INFO, 'Error checking Associated_Record field existence: ' + e.getMessage());
            }
            
            // Build query with proper field names and security
            String query = 'select Id, Name, caresp__Outcome__c, caresp__Assessment__r.Name, caresp__Color__c, ' +
                          'caresp__Status__c, caresp__Assessment_Date__c, caresp__Object__c, caresp__Total_Score__c, ' +
                          'caresp__Total_Max_Score__c, caresp__Record_Id__c, createdby.name, CreatedDate, lastmodifiedby.Id, ' +
                          'lastmodifiedby.name, lastmodifieddate, ' + sanitizedObjName;
            if (includeClientField) {
                query += ', ' + String.escapeSingleQuotes(clientFieldApi);
                // Only include relationship field if it's a lookup field
                if (isClientFieldLookup && String.isNotBlank(clientRelationshipField)) {
                    query += ', ' + String.escapeSingleQuotes(clientRelationshipField);
                }
            }
            // Only include relationship query if relationship name exists
            if (includeAssociatedRecord) {
                query += ', caresp__Associated_Record__c';
                if (String.isNotBlank(associatedRecordRelationshipName)) {
                    query += ', ' + String.escapeSingleQuotes(associatedRecordRelationshipName) + '.Name';
                }
            }
            query += ' from caresp__Outcome__c where Id = :validatedOutcomeId ' +
                    'AND caresp__inActive__c = false WITH USER_MODE LIMIT 1';

            List<caresp__Outcome__c> outcomeList = Database.query(query);
            
            if (!outcomeList.isEmpty()) {
                caresp__Outcome__c outcome = outcomeList[0];
                
                // Null safety checks
                if (outcome.caresp__Assessment_Date__c != null) {
                    String strAssessmentDate = String.valueOf(outcome.caresp__Assessment_Date__c.format());
                    respWrp.assessmentDate = strAssessmentDate;
                }
                
                respWrp.assessmentName = outcome.caresp__Assessment__r?.Name;
                respWrp.assessmentStatus = outcome.caresp__Status__c;
                respWrp.recordId = (String)outcome.get(sanitizedObjName);
                respWrp.objectName = sfObjectName;
                respWrp.outcome = outcome.caresp__Outcome__c;
                respWrp.color = outcome.caresp__Color__c;
                respWrp.createdBy = outcome.createdby?.name;
                respWrp.lastModifiedBy = outcome.lastmodifiedby?.name;
                respWrp.createdDate = outcome.CreatedDate != null ? String.valueOf(outcome.CreatedDate) : null;
                respWrp.lastModifiedDate = outcome.lastmodifieddate != null ? String.valueOf(outcome.lastmodifieddate) : null;
                respWrp.totalScore = outcome.caresp__Total_Score__c != null ? Integer.valueOf(outcome.caresp__Total_Score__c) : 0;
                respWrp.totalMaxScore = outcome.caresp__Total_Max_Score__c != null ? Integer.valueOf(outcome.caresp__Total_Max_Score__c) : 0;
                
                // Set the additional lookup label from metadata
                respWrp.additionalLookupLabel = clientLabel;
                
                // Get record ID from caresp__Record_Id__c field and query the related record name
                String recordIdFromField = outcome.caresp__Record_Id__c;
                if (String.isNotBlank(recordIdFromField)) {
                    try {
                        Id validatedRecordId = Id.valueOf(recordIdFromField);
                        // Determine the object type from the ID prefix
                        String sObjectType = validatedRecordId.getSObjectType().getDescribe().getName();
                        System.debug(LoggingLevel.INFO, 'Record ID from caresp__Record_Id__c: ' + recordIdFromField);
                        System.debug(LoggingLevel.INFO, 'Object Type: ' + sObjectType);
                        
                        // Query the related record to get its Name
                        String soql = 'SELECT Name FROM ' + String.escapeSingleQuotes(sObjectType) + 
                                     ' WHERE Id = :validatedRecordId WITH USER_MODE LIMIT 1';
                        List<SObject> relatedRecords = Database.query(soql);
                        if (!relatedRecords.isEmpty()) {
                            Object nameValue = relatedRecords[0].get('Name');
                            if (nameValue != null) {
                                respWrp.associatedRecordName = String.valueOf(nameValue);
                                respWrp.associatedRecordId = recordIdFromField;
                                System.debug(LoggingLevel.INFO, 'Related Record Name from caresp__Record_Id__c: ' + respWrp.associatedRecordName);
                            }
                        }
                    } catch (Exception recordEx) {
                        System.debug(LoggingLevel.WARN, 'Error querying record from caresp__Record_Id__c: ' + recordEx.getMessage());
                        System.debug(LoggingLevel.WARN, 'Stack trace: ' + recordEx.getStackTraceString());
                    }
                }
                
                // Populate Associated Record name if available (from caresp__Associated_Record__c field)
                if (includeAssociatedRecord) {
                    try {
                        Object associatedRecordId = outcome.get('caresp__Associated_Record__c');
                        System.debug(LoggingLevel.INFO, 'Associated Record ID from field: ' + associatedRecordId);
                        if (associatedRecordId != null) {
                            String associatedRecordIdStr = String.valueOf(associatedRecordId);
                            respWrp.associatedRecordId = associatedRecordIdStr; // Store the ID for the link
                            System.debug(LoggingLevel.INFO, 'Associated Record ID String: ' + associatedRecordIdStr);
                            System.debug(LoggingLevel.INFO, 'Relationship Name: ' + associatedRecordRelationshipName);
                            System.debug(LoggingLevel.INFO, 'Target Object: ' + associatedRecordTargetObject);
                            
                            // Try to get name from relationship if relationship exists
                            if (String.isNotBlank(associatedRecordRelationshipName)) {
                                try {
                                    SObject associatedRecord = outcome.getSObject(associatedRecordRelationshipName);
                                    System.debug(LoggingLevel.INFO, 'Associated Record from relationship: ' + associatedRecord);
                                    if (associatedRecord != null) {
                                        Object associatedRecordName = associatedRecord.get('Name');
                                        if (associatedRecordName != null) {
                                            respWrp.associatedRecordName = String.valueOf(associatedRecordName);
                                            System.debug(LoggingLevel.INFO, 'Associated Record Name from relationship: ' + respWrp.associatedRecordName);
                                        }
                                    }
                                } catch (Exception relEx) {
                                    System.debug(LoggingLevel.WARN, 'Error accessing Associated_Record relationship: ' + relEx.getMessage());
                                    System.debug(LoggingLevel.WARN, 'Stack trace: ' + relEx.getStackTraceString());
                                    // Fall through to query the record directly
                                }
                            }
                            
                            // If relationship name not available or relationship query failed, query the record directly
                            if (String.isBlank(respWrp.associatedRecordName) && String.isNotBlank(associatedRecordTargetObject)) {
                                try {
                                    Id validatedAssociatedRecordId = Id.valueOf(associatedRecordIdStr);
                                    String soql = 'SELECT Name FROM ' + String.escapeSingleQuotes(associatedRecordTargetObject) + 
                                                 ' WHERE Id = :validatedAssociatedRecordId WITH USER_MODE LIMIT 1';
                                    System.debug(LoggingLevel.INFO, 'Querying Associated Record: ' + soql);
                                    List<SObject> relatedRecords = Database.query(soql);
                                    System.debug(LoggingLevel.INFO, 'Query returned ' + relatedRecords.size() + ' records');
                                    if (!relatedRecords.isEmpty()) {
                                        Object nameValue = relatedRecords[0].get('Name');
                                        if (nameValue != null) {
                                            respWrp.associatedRecordName = String.valueOf(nameValue);
                                            System.debug(LoggingLevel.INFO, 'Associated Record Name from query: ' + respWrp.associatedRecordName);
                                        }
                                    }
                                } catch (Exception queryEx) {
                                    System.debug(LoggingLevel.ERROR, 'Error querying Associated_Record name: ' + queryEx.getMessage());
                                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + queryEx.getStackTraceString());
                                }
                            }
                        } else {
                            System.debug(LoggingLevel.INFO, 'Associated_Record__c field is null or empty');
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, 'Error accessing Associated_Record field: ' + e.getMessage());
                        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                    }
                } else {
                    System.debug(LoggingLevel.INFO, 'Associated_Record field not included in query (field may not exist or not accessible)');
                }
                
                // Populate Client data if available (only if field was included in query)
                if (includeClientField) {
                    try {
                        Object clientIdObj = outcome.get(clientFieldApi);
                        if (clientIdObj != null) {
                            String clientIdStr = String.valueOf(clientIdObj);
                            respWrp.clientId = clientIdStr;
                            
                            // Check if the field is a lookup field (has relationship) or a text field (contains ID)
                            Schema.DescribeFieldResult fieldDescribe = Schema.sObjectType.caresp__Outcome__c.fields.getMap().get(clientFieldApi).getDescribe();
                            Boolean isLookupField = (fieldDescribe.getType() == Schema.DisplayType.REFERENCE);
                            
                            if (isLookupField) {
                                // Field is a lookup - use relationship query
                                String relationshipName = clientFieldApi.replace('__c', '__r');
                                SObject clientRecord = outcome.getSObject(relationshipName);
                                if (clientRecord != null) {
                                    Object clientDisplayValue = clientRecord.get(clientDisplayField);
                                    if (clientDisplayValue != null) {
                                        respWrp.clientName = String.valueOf(clientDisplayValue);
                                    }
                                }
                            } else {
                                // Field is a text field containing an ID - query the record directly
                                try {
                                    Id validatedClientId = Id.valueOf(clientIdStr);
                                    String sObjectType = validatedClientId.getSObjectType().getDescribe().getName();
                                    String soql = 'SELECT ' + String.escapeSingleQuotes(clientDisplayField) + 
                                                 ' FROM ' + String.escapeSingleQuotes(sObjectType) + 
                                                 ' WHERE Id = :validatedClientId WITH USER_MODE LIMIT 1';
                                    List<SObject> clientRecords = Database.query(soql);
                                    if (!clientRecords.isEmpty()) {
                                        Object clientDisplayValue = clientRecords[0].get(clientDisplayField);
                                        if (clientDisplayValue != null) {
                                            respWrp.clientName = String.valueOf(clientDisplayValue);
                                        }
                                    }
                                } catch (Exception idEx) {
                                    System.debug(LoggingLevel.WARN, 'Error querying client record from text field: ' + idEx.getMessage());
                                    // Continue without client name
                                }
                            }
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.INFO, 'Error accessing client fields: ' + e.getMessage());
                        // Continue without client data
                    }
                }
            }
            return respWrp;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getOutcomeDetails: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve outcome details: ' + ex.getMessage());
        }
    }

    // Returns a list of responses (questions and answers) associated with a specific outcome record.
    @AuraEnabled(cacheable = true)
    public static List<QuestionsWrapper> getResponses(String outcomeId) {
        // Input validation
        if (String.isBlank(outcomeId)) {
            throw new AuraHandledException('Outcome ID cannot be null or empty');
        }
        
        // Validate ID format
        Id validatedOutcomeId;
        try {
            validatedOutcomeId = Id.valueOf(outcomeId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid outcome ID format');
        }
        
        try {
            List<String> numSeqList = new List<String>{'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26'};
            List<String> alphaSeqList = new List<String>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
            List<String> greekSeqList = new List<String>{'i','ii','iii','iv','v','vi','vii','viii','ix','x','xi','xii','xiii','xiv','xv','xvi','xvii','xviii','xix','xx','xxi','xxii','xxiii','xxiv','xxv','xxvi'};
            
            List<caresp__Response__c> responseList = new List<caresp__Response__c>();
            List<QuestionsWrapper> quesWrpList = new List<QuestionsWrapper>();

            responseList = [
                select Id, caresp__Question_Text__c, caresp__Backend_Sequence__c, 
                       caresp__Assessment_Question__r.caresp__Question__r.caresp__Question_Text__c, 
                       caresp__Assessment_Question__r.caresp__Question__r.caresp__Question_Data_type__c, 
                       caresp__Assessment_Question__r.caresp__Question__r.caresp__Answer_Options__c, 
                       caresp__Assessment_Question__r.caresp__Section__c, caresp__Sequence__c, 
                       caresp__Assessment_Question__r.caresp__Section_Sequence__c, caresp__Response__c 
                from caresp__Response__c 
                where caresp__Outcome__c = :validatedOutcomeId 
                  AND caresp__InActive__c = false 
                WITH USER_MODE 
                order by caresp__Backend_Sequence__c
                LIMIT 10000
            ];

            Integer prevSectionSeq;
            String prevSection = '';

            if (responseList != null && responseList.size() > 0) {
                for (caresp__Response__c resp : responseList) {
                    String level = '';
                    String seqForWrap = '';
                    
                    if (String.isNotBlank(resp.caresp__Sequence__c)) {
                        String seq = resp.caresp__Sequence__c;
                        Integer count = seq.countMatches('-');
                        if (count == 0) {
                            level = 'level1';
                            seqForWrap = seq;
                        } else if (count == 1) {
                            level = 'level2';
                            seqForWrap = seq.subStringAfter('-');
                        } else {
                            level = 'level3';
                            seqForWrap = seq.substringAfterLast('-');
                        }
                    }

                    List<String> ansOpList = new List<String>();
                    List<QuesAnswerWrapper> quesAnsWrpList = new List<QuesAnswerWrapper>();

                    String questionDataType = resp.caresp__Assessment_Question__r?.caresp__Question__r?.caresp__Question_Data_type__c;
                    if (questionDataType == 'Radio Box' || questionDataType == 'Picklist' || questionDataType == 'Checkbox') {
                        String temp = resp.caresp__Assessment_Question__r?.caresp__Question__r?.caresp__Answer_Options__c;
                        System.debug(LoggingLevel.Error ,'temp >> ' + temp);
                        
                        if (String.isNotBlank(temp)) {
                            ansOpList = temp.split('\\|');
                            System.debug(LoggingLevel.Error ,'ansOpList >> ' + ansOpList);
                            
                            if (ansOpList != null && ansOpList.size() > 0) {
                                for (String ans : ansOpList) {
                                    if (String.isNotBlank(ans)) {
                                        quesAnsWrpList.add(new QuesAnswerWrapper(ans, ans));
                                    }
                                }
                            }
                        }
                    }

                    prevSectionSeq = resp.caresp__Assessment_Question__r?.caresp__Section_Sequence__c != null ? 
                        (Integer)resp.caresp__Assessment_Question__r.caresp__Section_Sequence__c : prevSectionSeq;
                    System.debug(LoggingLevel.Error ,'prevSectionSeq # ' + prevSectionSeq);
                    
                    prevSection = String.isNotBlank(resp.caresp__Assessment_Question__r?.caresp__Section__c) ? 
                        resp.caresp__Assessment_Question__r.caresp__Section__c : prevSection;
                    System.debug(LoggingLevel.Error ,'prevSection # ' + prevSection);

                    quesWrpList.add(new QuestionsWrapper(
                        level, 
                        (String)resp.Id, 
                        resp.caresp__Question_Text__c, 
                        questionDataType, 
                        resp.caresp__Backend_Sequence__c, 
                        seqForWrap, 
                        prevSection, 
                        prevSectionSeq, 
                        questionDataType == 'Text', 
                        questionDataType == 'Number',
                        questionDataType == 'Checkbox', 
                        questionDataType == 'Radio Box',
                        questionDataType == 'Picklist',
                        questionDataType == 'Long Text Area',
                        questionDataType == 'Currency',
                        questionDataType == 'Date',
                        questionDataType == 'Telephone',
                        questionDataType == 'Signature',
                        resp.caresp__Response__c, 
                        quesAnsWrpList
                    ));
                }
            }

            return quesWrpList;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getResponses: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve responses: ' + ex.getMessage());
        }
    }

    public class QuestionsWrapper {
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
        @AuraEnabled public Boolean isSignature;
        @AuraEnabled public String response;
        @AuraEnabled public List<QuesAnswerWrapper> quesAnsList;
        
        public QuestionsWrapper(String level, String responseId, String quesText, String dataType, Decimal sequence, 
                               String sfSeq, String section, Decimal sectionSequence, Boolean isText, Boolean isNumber, 
                               Boolean isCheckbox, Boolean isRadio, Boolean isCombobox, Boolean isLongText, 
                               Boolean isCurrency, Boolean isDate, Boolean isPhone, Boolean isSignature, String response, 
                               List<QuesAnswerWrapper> quesAnsList) {
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
            this.isSignature = isSignature;
            this.response = response;
            this.quesAnsList = quesAnsList;
        }
    }

    public class OutcomeDetailsWrapper {
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
        @AuraEnabled public String clientId {get;set;}
        @AuraEnabled public String clientName {get;set;}
        @AuraEnabled public String associatedRecordName {get;set;}
        @AuraEnabled public String associatedRecordId {get;set;}
        @AuraEnabled public String additionalLookupLabel {get;set;}
    }

    public class QuesAnswerWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public QuesAnswerWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}