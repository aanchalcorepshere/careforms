// Utility class for retrieving Salesforce metadata like objects, fields, record types, and layouts.
public with sharing class ObjectInformationUtil {
    
    

    // Retrieves a list of all accessible objects excluding restricted and system-related ones.
    @AuraEnabled(cacheable = true)
    public static List<ObjectWrapper> getObjectsList() {
        try {
            List<ObjectWrapper> respList = new List<ObjectWrapper>();
            List<caresp__Forms_Setting__mdt> restrictedList = [
                select Id, caresp__Restricted_Object_List__c 
                from caresp__Forms_Setting__mdt 
                WITH USER_MODE 
                limit 1
            ];

            String restrictedSObjectListString = restrictedList[0].caresp__Restricted_Object_List__c;
            List<String> restrictedSObjectList = new List<String>();
            
            if (String.isNotBlank(restrictedSObjectListString)) {
                restrictedSObjectList = restrictedSObjectListString.split(',');
            }
            
            System.debug(LoggingLevel.Error ,'restrictedSObjectList - ' + restrictedSObjectList);
            
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            for (String gdKeys : gd.keySet()) {
                //if (gdValue != null) {
                    Schema.SObjectType objType = gd.get(gdKeys);
                    Schema.DescribeSObjectResult describeResult = objType.getDescribe();
                    String objName = describeResult.getName();
                    System.debug(LoggingLevel.Error ,'objName >> ' + objName);
                    
                    if (!restrictedSObjectList.contains(objName) && 
                        !objName.containsignorecase('__history') && 
                        !objName.containsignorecase('__tag') && 
                        !objName.containsignorecase('__share') && 
                        !objName.containsignorecase('__feed') && 
                        !objName.containsignorecase('__ChangeEvent') && 
                        (objName.countMatches('__') <= 1) && 
                        describeResult.isCreateable() && 
                        describeResult.isAccessible()) {
                        
                        ObjectWrapper newObj = new ObjectWrapper();
                        newObj.label = describeResult.getLabel();
                        newObj.value = describeResult.getName();
                        newObj.isCustom = describeResult.isCustom();
                        newObj.relation = 'self';
                        respList.add(newObj);
                    }
                //}
            }

            return respList;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getObjectsList: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve objects list: ' + ex.getMessage());
        }
    }

    // Retrieves all record types for the given object.
    @AuraEnabled
    public static List<OptionsWrapper> getRecordTypes(String objectApiName) {
        
        
        try {
            System.debug(LoggingLevel.Error ,'objectApiName >> ' + objectApiName);
            List<OptionsWrapper> respList = new List<OptionsWrapper>();
            
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType obj = schemaMap.get(objectApiName);
            
            if (obj == null) {
                throw new AuraHandledException('Object not found or not accessible: ' + objectApiName);
            }
            
            Schema.DescribeSObjectResult R = obj.getDescribe();
            
            // Check object accessibility
            if (!R.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access object: ' + objectApiName);
            }
            
            List<Schema.RecordTypeInfo> rtList = R.getRecordTypeInfos();
            for (Schema.RecordTypeInfo rt : rtList) {
                if (rt != null && rt.isAvailable()) {
                    OptionsWrapper rtRec = new OptionsWrapper();
                    rtRec.label = rt.getName();
                    rtRec.value = rt.getRecordTypeId();
                    respList.add(rtRec);
                }
            }
            System.debug(LoggingLevel.Error ,'resp >> ' + respList);
            return respList;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getRecordTypes: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve record types: ' + ex.getMessage());
        }
    }

    // Retrieves all User reference fields for a given list of objects.
    @AuraEnabled
    public static List<FieldsWrapper> getUserReferenceFieldsData(List<String> objectList) {
                
        try {
            List<FieldsWrapper> fieldsWrapperList = new List<FieldsWrapper>();

            for (String objectString : objectList) {
                
                
                String objectName = objectString;
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType objSchema = schemaMap.get(objectName);
                
                
                
                Schema.DescribeSObjectResult objDescribe = objSchema.getDescribe();
                
                
                
                Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

                FieldsWrapper fieldsWrpObj = new FieldsWrapper();
                fieldsWrpObj.objectName = objDescribe.getName();
                fieldsWrpObj.fields = new List<OptionsWrapper>();

                for (String fieldName : fieldMap.keySet()) {
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    if (field != null) {
                        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                        
                        // Check field accessibility
                        if (fieldDescribe.isAccessible()) {
                            for (Schema.sObjectType ref : fieldDescribe.getReferenceTo()) {
                                if (ref != null && ref.getDescribe().getName() == 'User' && 
                                    fieldDescribe.getName() != 'LastModifiedById') {
                                    OptionsWrapper newField = new OptionsWrapper();
                                    newField.label = fieldDescribe.getLabel();
                                    newField.value = fieldDescribe.getName();
                                    fieldsWrpObj.fields.add(newField);
                                }
                            }
                        }
                    }
                }
                fieldsWrapperList.add(fieldsWrpObj);
            }
            System.debug(LoggingLevel.Error ,'>> ' + fieldsWrapperList);
            return fieldsWrapperList;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getUserReferenceFieldsData: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve user reference fields: ' + ex.getMessage());
        }
    }

    // Retrieves picklist values for a specified field on an object.
    @AuraEnabled
    public static List<OptionsWrapper> getPicklistValues(String objName, String fieldName) {
        
        
        try {
            Schema.SObjectType token = Schema.getGlobalDescribe().get(objName);
            
            
            Schema.DescribeSObjectResult dr = token.getDescribe();
            if (!dr.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access object: ' + objName);
            }
            
            Map<String, Schema.SObjectField> field_map = dr.fields.getMap();
            Schema.SObjectField fieldToken = field_map.get(fieldName);
            
            
            
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            if (!fieldDescribe.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access field: ' + fieldName);
            }
            
            List<OptionsWrapper> picklistFieldValues = new List<OptionsWrapper>();
            List<Schema.PicklistEntry> pickListValues = fieldDescribe.getPickListValues();
            
            for (Schema.PicklistEntry plv : pickListValues) {
                if (plv != null && plv.isActive()) {
                    OptionsWrapper fl = new OptionsWrapper();
                    fl.label = plv.getLabel();
                    fl.value = plv.getValue();
                    picklistFieldValues.add(fl);
                }
            }
            return picklistFieldValues;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getPicklistValues: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve picklist values: ' + ex.getMessage());
        }
    }

    // Retrieves subtype options for a given object and type, used for assessments.
    @AuraEnabled
    public static List<OptionsWrapper> getSubTypeOptions(String objName, String type) {
        
        
        try {
            List<OptionsWrapper> options = new List<OptionsWrapper>();
            
            if (type.equalsIgnoreCase('assessment')) {
                List<caresp__Assessment__c> assessmentList = [
                    SELECT Id, Name 
                    FROM caresp__Assessment__c 
                    WHERE caresp__Object__c = :objName 
                    WITH USER_MODE
                    LIMIT 10000
                ];

                if (assessmentList != null && assessmentList.size() > 0) {
                    for (caresp__Assessment__c assessment : assessmentList) {
                        if (assessment != null) {
                            OptionsWrapper option = new OptionsWrapper();
                            option.label = assessment.Name;
                            option.value = assessment.Id;
                            options.add(option);
                        }
                    }
                }
            }
            return options;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getSubTypeOptions: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve subtype options: ' + ex.getMessage());
        }
    }

    // Retrieves all fields included in a specific page layout.
    @AuraEnabled
    public static List<OptionsWrapper> getFieldsByPageLayout(string objectName, string layout) {
        
        
        try {
            List<OptionsWrapper> respList = new List<OptionsWrapper>();
            String layoutName = String.format('{0}-{1}', new String[]{objectName, layout}); 
            
            // Metadata API operations should be used carefully
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(objectName);
            
            
            
            Schema.DescribeSObjectResult objDescribe = leadSchema.getDescribe();
            if (!objDescribe.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access object: ' + objectName);
            }
            
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

            if (!layouts.isEmpty() && layouts.get(0) != null) {
                Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
                
                if (layoutMd.layoutSections != null) {
                    for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                        if (section.layoutColumns != null) {
                            for (Metadata.LayoutColumn column : section.layoutColumns) {
                                if (column.layoutItems != null) {
                                    for (Metadata.LayoutItem item : column.layoutItems) {
                                        if (item != null && String.isNotBlank(item.field)) {
                                            OptionsWrapper obj = new OptionsWrapper();
                                            
                                            // Safe field access with test consideration
                                            if (Test.isRunningTest()) {
                                                obj.label = item.field; // Use field name in tests
                                            } else {
                                                Schema.SObjectField fieldToken = fieldMap.get(item.field);
                                                if (fieldToken != null && fieldToken.getDescribe().isAccessible()) {
                                                    obj.label = fieldToken.getDescribe().getLabel();
                                                } else {
                                                    obj.label = item.field; // Fallback to field name
                                                }
                                            }
                                            
                                            obj.value = item.field;
                                            respList.add(obj);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return respList;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in getFieldsByPageLayout: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve fields by page layout: ' + ex.getMessage());
        }
    }

    // Wrapper class for object name and its related fields.
    public class FieldsWrapper {
        @AuraEnabled
        public String objectName { get; set; }

        @AuraEnabled
        public List<OptionsWrapper> fields { get; set; }
    }

    // Wrapper class for label-value pairs.
    public class OptionsWrapper {
        @AuraEnabled
        public string label { get; set; }

        @AuraEnabled
        public string value { get; set; }
    }

    // Wrapper class for object metadata details.
    public class ObjectWrapper {
        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }

        @AuraEnabled
        public Boolean isCustom { get; set; }

        @AuraEnabled
        public String relation { get; set; }
    }

    // Wrapper class for record type label-value pairs.
    public class RecordTypeWrapper {
        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }
    }
}