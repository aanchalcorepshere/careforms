public with sharing class PlanTemplateUtil {
    
    @AuraEnabled(cacheable=true)
    public static PlanTemplateUtilWrapper getObjectFieldNames(String objName, String parentRecId, String dummyParam) {
        
        
        try {
            // Validate parent record ID format
            Id validatedParentRecId = Id.valueOf(parentRecId);
            
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = PlanTemplateUtil.getDynamicPlanRestrictionSettings();
            List<String> lstParentFieldsToShow = activeSetting.caresp__Plan_Template_Fields_To_Show__c != null ? 
                activeSetting.caresp__Plan_Template_Fields_To_Show__c.split(',') : new List<String>();
            
            List<Map<String, String>> listFieldName = getFieldNames(objName);
            System.debug('listFieldName>>>' + listFieldName);
            
            PlanTemplateUtilWrapper panTemplateUtilWrapper = getUsedPicklistValues(validatedParentRecId);
            System.debug('panTemplateUtilWrapper>>>' + panTemplateUtilWrapper);
            
            List<PicklistWrapper> filteredFieldNames = new List<PicklistWrapper>();
            for (Map<String, String> field : listFieldName) {
                if ((lstParentFieldsToShow.contains(field.get('name'))) && 
                    !panTemplateUtilWrapper.setUsedPicklistValues.contains(field.get('name'))) {
                    filteredFieldNames.add(new PicklistWrapper(
                        field.get('label'), 
                        field.get('name'), 
                        field.get('dataType'), 
                        Boolean.valueOf(field.get('isMandatory')), 
                        Boolean.valueOf(field.get('isEditable')), 
                        null
                    ));
                }
            }
            
            // Replace the original list with the filtered list
            panTemplateUtilWrapper.listFieldName.addAll(filteredFieldNames);
            System.debug('panTemplateUtilWrapper return >>>' + panTemplateUtilWrapper);
            return panTemplateUtilWrapper;
            
        } catch (Exception ex) {
            System.debug('Exception in getObjectFieldNames >> ' + ex);
            throw new AuraHandledException('Error occurred in getObjectFieldNames: ' + ex.getMessage());
        }
    }
    
    private static PlanTemplateUtilWrapper getUsedPicklistValues(Id parentRecId) {
        
        
        try {
            List<caresp__Plan_Template_Field_Blueprint__c> listFieldBluePrintRec = [
                SELECT Id, caresp__Plan_Field_List__c, caresp__Section_Name__c 
                FROM caresp__Plan_Template_Field_Blueprint__c 
                WHERE caresp__Plan_Template__c = :parentRecId AND caresp__isActive__c = true 
                WITH USER_MODE
                LIMIT 10000
            ];
            
            Set<String> setUsedField = new Set<String>();
            PlanTemplateUtilWrapper panTemplateUtilWrapper = new PlanTemplateUtilWrapper();
            
            for(caresp__Plan_Template_Field_Blueprint__c ptfb : listFieldBluePrintRec) {
                if(String.isNotBlank(ptfb.caresp__Plan_Field_List__c)) {
                    try {
                        List<Object> parsedJson = (List<Object>) JSON.deserializeUntyped(ptfb.caresp__Plan_Field_List__c);                
                        for(Object pj : parsedJson) {
                            if (pj != null) {
                                Map<String, Object> objMap = (Map<String, Object>)pj;
                                Object valueObj = objMap.get('value');
                                if (valueObj != null) {
                                    panTemplateUtilWrapper.setUsedPicklistValues.add(String.valueOf(valueObj));
                                }
                            }
                        }
                    } catch (JSONException je) {
                        System.debug('JSON parsing error: ' + je.getMessage());
                        // Continue processing other records
                    }
                }
                
                if (String.isNotBlank(ptfb.caresp__Section_Name__c)) {
                    panTemplateUtilWrapper.setExistingSections.add(ptfb.caresp__Section_Name__c);
                }
            }
            
            System.debug('panTemplateUtilWrapper>>>' + panTemplateUtilWrapper);
            return panTemplateUtilWrapper;
            
        } catch (Exception ex) {
            System.debug('Exception in getUsedPicklistValues >> ' + ex);
            throw new AuraHandledException('Error occurred in getUsedPicklistValues: ' + ex.getMessage());
        }
    }
    
    public static List<Map<String, String>> getFieldNames(String objectName) {
        
        
        List<Map<String, String>> fieldDetails = new List<Map<String, String>>();
        
        try {
            if (!Schema.getGlobalDescribe().containsKey(objectName) || 
                !Schema.getGlobalDescribe().get(objectName).getDescribe().isAccessible()) {
                throw new AuraHandledException('You do not have permission to access this object.');
            }
            
            // Get the DescribeSObjectResult for the specified object
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            
            // Get the map of fields for the object
            Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
            
            // Iterate over the fields map and add field names and labels to the list
            for (Schema.SObjectField field : fieldsMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                
                // Only include accessible fields
                if (fieldDescribe.isAccessible()) {
                    Map<String, String> fieldInfo = new Map<String, String>();
                    fieldInfo.put('name', fieldDescribe.getName());
                    fieldInfo.put('label', fieldDescribe.getLabel());
                    fieldInfo.put('dataType', String.valueOf(fieldDescribe.getType()));
                    fieldInfo.put('isMandatory', String.valueOf(!fieldDescribe.isNillable()));
                    fieldInfo.put('isEditable', String.valueOf(fieldDescribe.isUpdateable()));
                    fieldInfo.put('isFormulaField', String.valueOf(fieldDescribe.isCalculated()));
                    
                    fieldDetails.add(fieldInfo);
                }
            }
            return fieldDetails;
            
        } catch (Exception e) {
            System.debug('Error in getFieldNames: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while retrieving field names: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, PlanTempWrapper> getPlanTemplates(String parentChildRelName) {
                
        System.debug('parentChildRelName>>> ' + parentChildRelName);
        
        try {
            Map<String, PlanTempWrapper> mapIdToPlnTempDetails = new Map<String, PlanTempWrapper>();
            
            List<caresp__Plan_Template__c> lstPlnTemp = [
                SELECT Id, Name, caresp__Parent_Date_Field__c, caresp__No_of_days_to_add_in_date__c, 
                       caresp__Parent_Child_Relation__c, caresp__Plan_template_Name__c, 
                       (SELECT Id, caresp__isActive__c, caresp__Section_Name__c, caresp__Plan_Field_List__c 
                        FROM caresp__Plan_Template_Field_Blueprints__r 
                        WHERE caresp__isActive__c = true ORDER BY createdDate ASC) 
                FROM caresp__Plan_Template__c 
                WHERE caresp__isActive__c = true AND caresp__Parent_Child_Relation__c = :parentChildRelName 
                WITH USER_MODE
                ORDER BY createdDate ASC
                LIMIT 10000
            ];
            
            System.debug('lstPlnTemp>>> ' + lstPlnTemp);
            
            for(caresp__Plan_Template__c pt : lstPlnTemp) {
                PlanTempWrapper ptw = new PlanTempWrapper();
                ptw.templateName = pt.caresp__Plan_template_Name__c;
                ptw.parentDateField = pt.caresp__Parent_Date_Field__c;
                ptw.noOfDaysToAdd = pt.caresp__No_of_days_to_add_in_date__c;
                ptw.SectionInformations = new List<PlanTempWrapper.SectionInformation>();
                
                for(caresp__Plan_Template_Field_Blueprint__c ptfb : pt.caresp__Plan_Template_Field_Blueprints__r) {
                    PlanTempWrapper.SectionInformation ptwSections = new PlanTempWrapper.SectionInformation();
                    ptwSections.sectionName = ptfb.caresp__Section_Name__c;
                    ptwSections.fieldBlueprints = new List<PlanTempWrapper.PicklistWrapper>();
                    System.debug('ptwSections>>> ' + ptwSections);
                    
                    if(String.isNotBlank(ptfb.caresp__Plan_Field_List__c)) {
                        try {
                            List<Object> fieldDetailList = (List<Object>) JSON.deserializeUntyped(ptfb.caresp__Plan_Field_List__c);
                            for(Object fdl : fieldDetailList) {
                                if (fdl != null) {
                                    Map<String, Object> mapObject = (Map<String, Object>)fdl;
                                    PlanTempWrapper.PicklistWrapper tempPickWrapper = new PlanTempWrapper.PicklistWrapper();
                                    tempPickWrapper.label = String.valueOf(mapObject.get('label'));
                                    tempPickWrapper.value = String.valueOf(mapObject.get('value'));
                                    tempPickWrapper.dataType = String.valueOf(mapObject.get('dataType'));
                                    tempPickWrapper.isMandatory = String.valueOf(mapObject.get('isMandatory')) == 'true';
                                    tempPickWrapper.isEditable = String.valueOf(mapObject.get('isEditable')) == 'true';
                                    tempPickWrapper.isReadOnly = String.valueOf(mapObject.get('isEditable')) == 'false';
                                    tempPickWrapper.defaultValue = String.valueOf(mapObject.get('defaultValue'));
                                    tempPickWrapper.isEditDisabled = String.valueOf(mapObject.get('isEditDisabled')) == 'true';
                                    tempPickWrapper.isReqDisabled = String.valueOf(mapObject.get('isReqDisabled')) == 'true';
                                    tempPickWrapper.isFormulaField = String.valueOf(mapObject.get('isFormulaField')) == 'true';
                                    ptwSections.fieldBlueprints.add(tempPickWrapper);
                                }
                            }
                        } catch (JSONException je) {
                            System.debug('JSON parsing error in getPlanTemplates: ' + je.getMessage());
                            // Continue processing other records
                        }
                        System.debug('ptwSections.fieldBlueprints>>> ' + ptwSections.fieldBlueprints);
                    }
                    System.debug('ptw>>> ' + ptw);
                    ptw.SectionInformations.add(ptwSections);
                }
                
                mapIdToPlnTempDetails.put(pt.Id, ptw);
                System.debug('mapIdToPlnTempDetails>>> ' + mapIdToPlnTempDetails);
            }
            
            return mapIdToPlnTempDetails;
            
        } catch (Exception ex) {
            System.debug('Exception occurred in getPlanTemplates: ' + ex.getMessage());
            throw new AuraHandledException('Error occurred in getPlanTemplates: ' + ex.getMessage());
        }
    }
    
    public static caresp__Dynamic_Plans_Restriction_Setttings__mdt getDynamicPlanRestrictionSettings() {
        try {
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = [
                SELECT Id, caresp__Field_Blueprint_Default_Section_Fields__c, caresp__Plan_Template_Fields_To_Show__c 
                FROM caresp__Dynamic_Plans_Restriction_Setttings__mdt 
                WHERE caresp__isActive__c = true 
                WITH USER_MODE 
                LIMIT 1
            ];
            return activeSetting;
        } catch (Exception ex) {
            System.debug('Exception in getDynamicPlanRestrictionSettings: ' + ex.getMessage());
            throw new AuraHandledException('Error retrieving restriction settings: ' + ex.getMessage());
        }
    }
    
    public class PlanTemplateUtilWrapper {
        @AuraEnabled public List<PicklistWrapper> listFieldName; 
        @AuraEnabled public List<String> setExistingSections;
        @AuraEnabled public List<String> setUsedPicklistValues;
        
        public PlanTemplateUtilWrapper() {
            this.listFieldName = new List<PicklistWrapper>();
            this.setExistingSections = new List<String>();
            this.setUsedPicklistValues = new List<String>();
        }
    }
    
    public class PicklistWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String dataType;
        @AuraEnabled public Boolean isMandatory;
        @AuraEnabled public Boolean isEditable;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean isEditDisabled;
        @AuraEnabled public Boolean isReqDisabled;
        @AuraEnabled public Boolean isFormulaField;
        
        public PicklistWrapper(String label, String value, String dataType, Boolean isMandatory, Boolean isEditable, String defaultValue) {
            this.label = label;
            this.value = value;
            this.dataType = dataType;
            this.isMandatory = isMandatory;
            this.isEditable = isEditable;
            this.defaultValue = defaultValue;
            this.isEditDisabled = !isEditable;
            this.isReqDisabled = !isEditable;
        }
    }
}