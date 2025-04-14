public with sharing class PlanTemplateUtil {
    
    @AuraEnabled(cacheable=true)
    Public Static PlanTemplateUtilWrapper getObjectFieldNames(String objName, String parentRecId, String dummyParam)
    {
        try{
             if (!Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access caresp__Plan_Template_Field_Blueprint__c records.');
            }
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = PlanTemplateUtil.getDynamicPlanRestrictionSettings();
            List<String> lstParentFieldsToShow = activeSetting.Plan_Template_Fields_To_Show__c != null ? activeSetting.Plan_Template_Fields_To_Show__c.split(',') : new List<String>();// bring fields to show in plan template.
            List<Map<String, String>> listFieldName = new List<Map<String, String>>();
            listFieldName = getFieldNames(objName);
            System.debug('listFieldName>>>' + listFieldName);
            PlanTemplateUtilWrapper panTemplateUtilWrapper = getUsedPicklistValues(parentRecId);
            System.debug('panTemplateUtilWrapper>>>' + panTemplateUtilWrapper);
            List<PicklistWrapper> filteredFieldNames = new List<PicklistWrapper>();
            for (Map<String, String> field : listFieldName) {
                if ((lstParentFieldsToShow.contains(field.get('name'))) && !panTemplateUtilWrapper.setUsedPicklistValues.contains(field.get('name'))) {
                    filteredFieldNames.add(new PicklistWrapper(field.get('label'), field.get('name'), field.get('dataType'), Boolean.valueOf(field.get('isMandatory')), Boolean.valueOf(field.get('isEditable')), null));
                }
            }
            
            // Replace the original list with the filtered list
            panTemplateUtilWrapper.listFieldName.addAll(filteredFieldNames);
            System.debug('panTemplateUtilWrapper return >>>' + panTemplateUtilWrapper);
            return panTemplateUtilWrapper;
        }catch(Exception ex)
        {
            System.debug('Exception in getObjectFieldNames >> ' + ex);
            throw new AuraHandledException('Error Occured in getObjectFieldNames: ' + ex.getMessage());
            
        }
    }
    
    
    Private Static PlanTemplateUtilWrapper getUsedPicklistValues(Id parentRecId)
    {
        try
        {
            if (!Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access Plan_Template_Field_Blueprint__c records.');
            }
            List<caresp__Plan_Template_Field_Blueprint__c> listFieldBluePrintRec = [SELECT Id, Plan_Field_List__c, Section_Name__c FROM Plan_Template_Field_Blueprint__c WHERE Plan_Template__c =: parentRecId  AND isActive__c = true WITH SECURITY_ENFORCED];
            Set<String> setUsedField = new Set<String>();
            PlanTemplateUtilWrapper panTemplateUtilWrapper = new PlanTemplateUtilWrapper();
            for(caresp__Plan_Template_Field_Blueprint__c ptfb : listFieldBluePrintRec)
            {
                if(ptfb.caresp__Plan_Field_List__c != null)
                {
                    List< Object> parsedJson = (List<Object>) JSON.deserializeUntyped(ptfb.caresp__Plan_Field_List__c);                
                    for(Object pj : parsedJson)
                    {
                        panTemplateUtilWrapper.setUsedPicklistValues.add(String.valueOf(((Map<String, Object>)pj).get('value')));
                        
                    }
                    
                }
                panTemplateUtilWrapper.setExistingSections.add(ptfb.caresp__Section_Name__c);
                
            }
            System.debug('panTemplateUtilWrapper>>>' + panTemplateUtilWrapper);
            return panTemplateUtilWrapper;
            
            
        }
        catch(Exception ex)
        {
            System.debug('Exception in getUsedPicklistValues >> ' + ex);
            throw new AuraHandledException('Error Occured in getUsedPicklistValues: ' + ex.getMessage());
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
                Map<String, String> fieldInfo = new Map<String, String>();
                fieldInfo.put('name', fieldDescribe.getName());
                fieldInfo.put('label', fieldDescribe.getLabel());
                fieldInfo.put('dataType', String.valueOf(fieldDescribe.getType()));
                fieldInfo.put('isMandatory', String.valueOf(!fieldDescribe.isNillable()));
                fieldInfo.put('isEditable', String.valueOf(fieldDescribe.isUpdateable()));
                fieldInfo.put('isFormulaField', String.valueOf(fieldDescribe.isCalculated()));
                
                fieldDetails.add(fieldInfo);
            }
            return fieldDetails;
        } catch (Exception e) {
            System.debug('Error in getFieldNames: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('An error occurred while retrieving field names.');
        }
        
    }
    
    
    
    
    
    @AuraEnabled(cacheable=true)
    Public Static Map<String, PlanTempWrapper> getPlanTemplates(String parentChildRelName)
    {
        System.debug('parentChildRelName>>> ' + parentChildRelName);
        try{
            // CRUD Check: Ensure the user has read access to Plan_Template__c
            if (!Schema.sObjectType.caresp__Plan_Template__c.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access Plan_Template__c records.');
            }
            Map<String, PlanTempWrapper> mapIdToPlnTempDetails = new Map<String, PlanTempWrapper>();
           List<caresp__Plan_Template__c> lstPlnTemp = [
                SELECT Id, Name, Parent_Date_Field__c, No_of_days_to_add_in_date__c, Parent_Child_Relation__c, 
                Plan_template_Name__c, 
                (SELECT Id, isActive__c, Section_Name__c, Plan_Field_List__c 
                 FROM Plan_Template_Field_Blueprints__r WHERE isActive__c = true ORDER BY createdDate ASC) 
                FROM Plan_Template__c 
                WHERE isActive__c = true AND Parent_Child_Relation__c =: parentChildRelName WITH SECURITY_ENFORCED
                ORDER BY createdDate ASC
                
            ];            System.debug('lstPlnTemp>>> ' + lstPlnTemp);
            for(caresp__Plan_Template__c pt : lstPlnTemp)
            {
                PlanTempWrapper ptw = new PlanTempWrapper();
                ptw.templateName = pt.caresp__Plan_template_Name__c;
                ptw.parentDateField = pt.caresp__Parent_Date_Field__c;
                ptw.noOfDaysToAdd = pt.caresp__No_of_days_to_add_in_date__c;
                ptw.SectionInformations = new List<PlanTempWrapper.SectionInformation>();
                for(Plan_Template_Field_Blueprint__c ptfb : pt.caresp__Plan_Template_Field_Blueprints__r)
                {
                    PlanTempWrapper.SectionInformation ptwSections = new PlanTempWrapper.SectionInformation();
                    ptwSections.sectionName = ptfb.caresp__Section_Name__c;
                    ptwSections.fieldBlueprints = new List<PlanTempWrapper.PicklistWrapper>();
                    System.debug('ptwSections>>> ' + ptwSections);
                    if(ptfb.caresp__Plan_Field_List__c != null)
                    {
                        List<Object> fieldDetailList = (List<Object>) JSON.deserializeUntyped(ptfb.caresp__Plan_Field_List__c);
                        for(Object fdl : fieldDetailList)
                        {
                            Map<String, Object> mapObject = (Map<String, Object>)fdl;
                            PlanTempWrapper.PicklistWrapper tempPickWrapper = new PlanTempWrapper.PicklistWrapper();
                            tempPickWrapper.label = String.valueOf(mapObject.get('label'));
                            tempPickWrapper.value = String.valueOf(mapObject.get('value'));
                            tempPickWrapper.dataType = String.valueOf(mapObject.get('dataType'));
                            tempPickWrapper.isMandatory = String.valueOf(mapObject.get('isMandatory')) == 'true' ? true: false;
                            tempPickWrapper.isEditable = String.valueOf(mapObject.get('isEditable')) == 'true' ? true: false;
                            tempPickWrapper.isReadOnly = String.valueOf(mapObject.get('isEditable')) == 'false' ? true : false;
                            tempPickWrapper.defaultValue = String.valueOf(mapObject.get('defaultValue'));
                            tempPickWrapper.isEditDisabled = String.valueOf(mapObject.get('isEditDisabled')) == 'true' ? true : false;
                            tempPickWrapper.isReqDisabled = String.valueOf(mapObject.get('isReqDisabled')) == 'true' ? true : false;
                            tempPickWrapper.isFormulaField = String.valueOf(mapObject.get('isFormulaField')) == 'true' ? true : false;
                            ptwSections.fieldBlueprints.add(tempPickWrapper);
                            
                        }
                        System.debug('ptwSections.fieldBlueprints>>> ' + ptwSections.fieldBlueprints );
                    }
                    System.debug('ptw>>> ' + ptw);
                    ptw.SectionInformations.add(ptwSections);
                }
                
                mapIdToPlnTempDetails.put(pt.Id, ptw);
                System.debug('mapIdToPlnTempDetails>>> ' + mapIdToPlnTempDetails);
                
                
            }
            
            return mapIdToPlnTempDetails;
        }
        catch(Exception ex) {
            System.debug('Exception occurred in getPlanTemplates: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            return null;
        }
    }
    

    Public static caresp__Dynamic_Plans_Restriction_Setttings__mdt getDynamicPlanRestrictionSettings()
    {
        caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = [SELECT Id, caresp__Field_Blueprint_Default_Section_Fields__c, caresp__Plan_Template_Fields_To_Show__c FROM caresp__Dynamic_Plans_Restriction_Setttings__mdt WHERE caresp__isActive__c = true WITH SECURITY_ENFORCED LIMIT 1];
        return activeSetting;

    }
    
    
    Public class PlanTemplateUtilWrapper
    {
        @AuraEnabled public List<PicklistWrapper> listFieldName; 
        @AuraEnabled public List<String>  setExistingSections;
        @AuraEnabled public List<String>  setUsedPicklistValues;
        
        public PlanTemplateUtilWrapper ()
        {
            this.listFieldName = new List<PicklistWrapper>();
            this.setExistingSections = new List<String>();
            this.setUsedPicklistValues = new List<String>();
        }
        
        
    }
    
    Public class PicklistWrapper 
    {
        @AuraEnabled Public String label;
        @AuraEnabled Public String value;
        @AuraEnabled Public String dataType;
        @AuraEnabled Public Boolean isMandatory;
        @AuraEnabled public Boolean isEditable;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean isEditDisabled;
        @AuraEnabled public Boolean isReqDisabled;
        @AuraEnabled public Boolean isFormulaField;
        
        Public PicklistWrapper(String label, String value, String dataType, Boolean isMandatory, Boolean isEditable, String defaultValue)
        {
            this.label = label;
            this.value = value;
            this.dataType = dataType;
            this.isMandatory = isMandatory;
            this.isEditable = isEditable;
            this.defaultValue  = defaultValue;
            this.isEditDisabled = !isEditable;
            this.isReqDisabled = !isEditable;
            
            
        }
        
    }
    
    
    
    
}