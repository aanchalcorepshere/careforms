public with sharing class PlanTemplateUtil {
    
    @AuraEnabled(cacheable=true)
    public static PlanTemplateUtilWrapper getObjectFieldNames(String objName, String parentRecId, String dummyParam) {
        
        
        try {
            // Validate parent record ID format
            Id validatedParentRecId = Id.valueOf(parentRecId);
            
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = PlanTemplateUtil.getDynamicPlanRestrictionSettings();
            String planFieldsCsv = getPlanTemplateFieldsToShowCsv(activeSetting);
            List<String> lstParentFieldsToShow = String.isNotBlank(planFieldsCsv)
                ? planFieldsCsv.split(',')
                : new List<String>();
            
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

    /**
     * @description Parses a comma-separated API list into a normalized lower-case set.
     * @param csv Comma-separated field API names
     * @return Lower-case set of allowed API names; empty set means "allow all"
     */
    private static Set<String> parseAllowedFieldCsv(String csv) {
        Set<String> allowed = new Set<String>();
        if (String.isBlank(csv)) {
            return allowed;
        }
        for (String token : csv.split(',')) {
            if (String.isNotBlank(token)) {
                allowed.add(token.trim().toLowerCase());
            }
        }
        return allowed;
    }

    /**
     * @description Returns true when a field is allowed by the configured allowlist.
     *              Empty allowlist intentionally permits all accessible fields.
     * @param allowed Normalized allowlist values
     * @param fieldApi API name to check
     * @return true when field can be shown in blueprint selector
     */
    private static Boolean isAllowedByRestriction(Set<String> allowed, String fieldApi) {
        if (allowed == null || allowed.isEmpty()) {
            return true;
        }
        return String.isNotBlank(fieldApi) && allowed.contains(fieldApi.trim().toLowerCase());
    }
    
    /**
     * @description Returns available Goal__c fields for the admin to configure on a Goal Template,
     *              excluding fields already used in existing Goal_Template_Field_Blueprint__c records.
     * @param objName     API name of Goal__c (always caresp__Goal__c)
     * @param parentRecId Id of the Goal_Template__c record
     * @param dummyParam  Cache-busting timestamp parameter
     * @return PlanTemplateUtilWrapper containing available field list and existing sections
     */
    @AuraEnabled(cacheable=true)
    public static PlanTemplateUtilWrapper getGoalObjectFieldNames(String objName, String parentRecId, String dummyParam) {
        try {
            if (String.isBlank(parentRecId)) {
                throw new AuraHandledException('Goal Template record Id is required.');
            }
            Id validatedParentRecId = Id.valueOf(parentRecId);
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = getDynamicPlanRestrictionSettings();
            Set<String> allowedGoalFields = parseAllowedFieldCsv(
                activeSetting == null ? null : activeSetting.caresp__Goal_Template_Fields_To_Show__c
            );

            List<caresp__Goal_Template_Field_Blueprint__c> existingBlueprints = [
                SELECT Id, caresp__Goal_Field_List__c, caresp__Section_Name__c
                FROM caresp__Goal_Template_Field_Blueprint__c
                WHERE caresp__Goal_Template__c = :validatedParentRecId AND caresp__isActive__c = true
                WITH USER_MODE
                LIMIT 10000
            ];

            Set<String> usedFields = new Set<String>();
            List<String> existingSections = new List<String>();

            for (caresp__Goal_Template_Field_Blueprint__c bp : existingBlueprints) {
                if (String.isNotBlank(bp.caresp__Goal_Field_List__c)) {
                    try {
                        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(bp.caresp__Goal_Field_List__c);
                        for (Object item : parsed) {
                            if (item != null) {
                                Map<String, Object> fieldMap = (Map<String, Object>) item;
                                Object val = fieldMap.get('value');
                                if (val != null) {
                                    usedFields.add(String.valueOf(val));
                                }
                            }
                        }
                    } catch (JSONException je) {
                        System.debug('JSON parsing error in getGoalObjectFieldNames: ' + je.getMessage());
                    }
                }
                if (String.isNotBlank(bp.caresp__Section_Name__c)) {
                    existingSections.add(bp.caresp__Section_Name__c);
                }
            }

            List<Map<String, String>> allFields = getFieldNames(objName);
            PlanTemplateUtilWrapper wrapper = new PlanTemplateUtilWrapper();
            wrapper.setExistingSections = existingSections;
            wrapper.setUsedPicklistValues = new List<String>(usedFields);

            for (Map<String, String> field : allFields) {
                if (!usedFields.contains(field.get('name')) &&
                    isAllowedByRestriction(allowedGoalFields, field.get('name'))) {
                    wrapper.listFieldName.add(new PicklistWrapper(
                        field.get('label'),
                        field.get('name'),
                        field.get('dataType'),
                        Boolean.valueOf(field.get('isMandatory')),
                        Boolean.valueOf(field.get('isEditable')),
                        null
                    ));
                }
            }
            return wrapper;
        } catch (Exception ex) {
            System.debug('Exception in getGoalObjectFieldNames: ' + ex.getMessage());
            throw new AuraHandledException('Error in getGoalObjectFieldNames: ' + ex.getMessage());
        }
    }

    /**
     * @description Returns available Step__c fields for the admin to configure on a Step Template,
     *              excluding fields already used in existing Step_Template_Field_Blueprint__c records.
     * @param objName     API name of Step__c (always caresp__Step__c)
     * @param parentRecId Id of the Step_Template__c record
     * @param dummyParam  Cache-busting timestamp parameter
     * @return PlanTemplateUtilWrapper containing available field list and existing sections
     */
    @AuraEnabled(cacheable=true)
    public static PlanTemplateUtilWrapper getStepObjectFieldNames(String objName, String parentRecId, String dummyParam) {
        try {
            if (String.isBlank(parentRecId)) {
                throw new AuraHandledException('Step Template record Id is required.');
            }
            Id validatedParentRecId = Id.valueOf(parentRecId);
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = getDynamicPlanRestrictionSettings();
            Set<String> allowedStepFields = parseAllowedFieldCsv(
                activeSetting == null ? null : activeSetting.caresp__Step_Template_Fields_To_Show__c
            );

            List<caresp__Step_Template_Field_Blueprint__c> existingBlueprints = [
                SELECT Id, caresp__Step_Field_List__c, caresp__Section_Name__c
                FROM caresp__Step_Template_Field_Blueprint__c
                WHERE caresp__Step_Template__c = :validatedParentRecId AND caresp__isActive__c = true
                WITH USER_MODE
                LIMIT 10000
            ];

            Set<String> usedFields = new Set<String>();
            List<String> existingSections = new List<String>();

            for (caresp__Step_Template_Field_Blueprint__c bp : existingBlueprints) {
                if (String.isNotBlank(bp.caresp__Step_Field_List__c)) {
                    try {
                        List<Object> parsed = (List<Object>) JSON.deserializeUntyped(bp.caresp__Step_Field_List__c);
                        for (Object item : parsed) {
                            if (item != null) {
                                Map<String, Object> fieldMap = (Map<String, Object>) item;
                                Object val = fieldMap.get('value');
                                if (val != null) {
                                    usedFields.add(String.valueOf(val));
                                }
                            }
                        }
                    } catch (JSONException je) {
                        System.debug('JSON parsing error in getStepObjectFieldNames: ' + je.getMessage());
                    }
                }
                if (String.isNotBlank(bp.caresp__Section_Name__c)) {
                    existingSections.add(bp.caresp__Section_Name__c);
                }
            }

            List<Map<String, String>> allFields = getFieldNames(objName);
            PlanTemplateUtilWrapper wrapper = new PlanTemplateUtilWrapper();
            wrapper.setExistingSections = existingSections;
            wrapper.setUsedPicklistValues = new List<String>(usedFields);

            for (Map<String, String> field : allFields) {
                if (!usedFields.contains(field.get('name')) &&
                    isAllowedByRestriction(allowedStepFields, field.get('name'))) {
                    wrapper.listFieldName.add(new PicklistWrapper(
                        field.get('label'),
                        field.get('name'),
                        field.get('dataType'),
                        Boolean.valueOf(field.get('isMandatory')),
                        Boolean.valueOf(field.get('isEditable')),
                        null
                    ));
                }
            }
            return wrapper;
        } catch (Exception ex) {
            System.debug('Exception in getStepObjectFieldNames: ' + ex.getMessage());
            throw new AuraHandledException('Error in getStepObjectFieldNames: ' + ex.getMessage());
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
            
            // Collect Plan Template IDs for downstream queries
            Set<Id> planTemplateIds = new Map<Id, caresp__Plan_Template__c>(lstPlnTemp).keySet();

            // Goal Template Field Blueprints grouped by Plan Template Id
            Map<Id, List<caresp__Goal_Template_Field_Blueprint__c>> goalBpByPlanTemplate =
                new Map<Id, List<caresp__Goal_Template_Field_Blueprint__c>>();
            for (caresp__Goal_Template_Field_Blueprint__c gb : [
                SELECT Id, caresp__Goal_Field_List__c, caresp__Section_Name__c,
                       caresp__Goal_Template__r.caresp__Plan_Template__c
                FROM caresp__Goal_Template_Field_Blueprint__c
                WHERE caresp__Goal_Template__r.caresp__Plan_Template__c IN :planTemplateIds
                  AND caresp__isActive__c = true
                  AND caresp__Goal_Template__r.caresp__isActive__c = true
                WITH USER_MODE
                ORDER BY CreatedDate ASC
                LIMIT 10000
            ]) {
                Id ptId = (Id) gb.caresp__Goal_Template__r.caresp__Plan_Template__c;
                if (!goalBpByPlanTemplate.containsKey(ptId)) {
                    goalBpByPlanTemplate.put(ptId, new List<caresp__Goal_Template_Field_Blueprint__c>());
                }
                goalBpByPlanTemplate.get(ptId).add(gb);
            }

            // Map Goal Template Id → Plan Template Id (for step blueprint lookup)
            Map<Id, Id> goalTemplToPlanTempl = new Map<Id, Id>();
            for (caresp__Goal_Template__c gt : [
                SELECT Id, caresp__Plan_Template__c
                FROM caresp__Goal_Template__c
                WHERE caresp__Plan_Template__c IN :planTemplateIds
                  AND caresp__isActive__c = true
                WITH USER_MODE
                LIMIT 10000
            ]) {
                goalTemplToPlanTempl.put(gt.Id, gt.caresp__Plan_Template__c);
            }

            // Step Template Field Blueprints grouped by Plan Template Id
            Map<Id, List<caresp__Step_Template_Field_Blueprint__c>> stepBpByPlanTemplate =
                new Map<Id, List<caresp__Step_Template_Field_Blueprint__c>>();
            if (!goalTemplToPlanTempl.isEmpty()) {
                Set<Id> goalTemplateIds = goalTemplToPlanTempl.keySet();
                for (caresp__Step_Template_Field_Blueprint__c sb : [
                    SELECT Id, caresp__Step_Field_List__c, caresp__Section_Name__c,
                           caresp__Step_Template__r.caresp__Goal_Template__c
                    FROM caresp__Step_Template_Field_Blueprint__c
                    WHERE caresp__Step_Template__r.caresp__Goal_Template__c IN :goalTemplateIds
                      AND caresp__isActive__c = true
                      AND caresp__Step_Template__r.caresp__isActive__c = true
                    WITH USER_MODE
                    ORDER BY CreatedDate ASC
                    LIMIT 10000
                ]) {
                    Id gtId = (Id) sb.caresp__Step_Template__r.caresp__Goal_Template__c;
                    Id ptId = goalTemplToPlanTempl.get(gtId);
                    if (ptId != null) {
                        if (!stepBpByPlanTemplate.containsKey(ptId)) {
                            stepBpByPlanTemplate.put(ptId, new List<caresp__Step_Template_Field_Blueprint__c>());
                        }
                        stepBpByPlanTemplate.get(ptId).add(sb);
                    }
                }
            }

            for(caresp__Plan_Template__c pt : lstPlnTemp) {
                PlanTempWrapper ptw = new PlanTempWrapper();
                ptw.templateName = pt.caresp__Plan_template_Name__c;
                ptw.parentDateField = pt.caresp__Parent_Date_Field__c;
                ptw.noOfDaysToAdd = pt.caresp__No_of_days_to_add_in_date__c;
                ptw.SectionInformations = new List<PlanTempWrapper.SectionInformation>();
                ptw.goalSectionInformations = new List<PlanTempWrapper.SectionInformation>();
                ptw.stepSectionInformations = new List<PlanTempWrapper.SectionInformation>();

                // Plan field sections (existing)
                for(caresp__Plan_Template_Field_Blueprint__c ptfb : pt.caresp__Plan_Template_Field_Blueprints__r) {
                    ptw.SectionInformations.add(buildSectionInfo(ptfb.caresp__Section_Name__c, ptfb.caresp__Plan_Field_List__c));
                }

                // Goal field sections
                List<caresp__Goal_Template_Field_Blueprint__c> goalBps = goalBpByPlanTemplate.get(pt.Id);
                if (goalBps != null) {
                    for (caresp__Goal_Template_Field_Blueprint__c gb : goalBps) {
                        ptw.goalSectionInformations.add(buildSectionInfo(gb.caresp__Section_Name__c, gb.caresp__Goal_Field_List__c));
                    }
                }

                // Step field sections
                List<caresp__Step_Template_Field_Blueprint__c> stepBps = stepBpByPlanTemplate.get(pt.Id);
                if (stepBps != null) {
                    for (caresp__Step_Template_Field_Blueprint__c sb : stepBps) {
                        ptw.stepSectionInformations.add(buildSectionInfo(sb.caresp__Section_Name__c, sb.caresp__Step_Field_List__c));
                    }
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

    /**
     * @description Returns goal/step blueprint sections for a specific Plan record by resolving
     *              its plan type text against active Plan Templates for that parent-child relation.
     *              Used as a fallback when client-side blueprint props are not yet hydrated.
     * @param planId Id of Plan__c
     * @return PlanTempWrapper with goalSectionInformations and stepSectionInformations populated when found
     */
    @AuraEnabled(cacheable=true)
    public static PlanTempWrapper getBlueprintSectionsForPlan(Id planId) {
        PlanTempWrapper emptyWrapper = new PlanTempWrapper();
        emptyWrapper.goalSectionInformations = new List<PlanTempWrapper.SectionInformation>();
        emptyWrapper.stepSectionInformations = new List<PlanTempWrapper.SectionInformation>();

        if (planId == null) {
            return emptyWrapper;
        }

        try {
            caresp__Plan__c planRec = [
                SELECT Id, caresp__Plan_Type_Txt__c, caresp__Parent_Child_Name__c
                FROM caresp__Plan__c
                WHERE Id = :planId
                WITH USER_MODE
                LIMIT 1
            ];

            if (String.isBlank(planRec.caresp__Plan_Type_Txt__c) || String.isBlank(planRec.caresp__Parent_Child_Name__c)) {
                return emptyWrapper;
            }

            Map<String, PlanTempWrapper> templateMap = getPlanTemplates(planRec.caresp__Parent_Child_Name__c);
            String normalizedPlanType = planRec.caresp__Plan_Type_Txt__c.trim().toLowerCase();

            for (PlanTempWrapper ptw : templateMap.values()) {
                if (ptw != null && String.isNotBlank(ptw.templateName) && ptw.templateName.trim().toLowerCase() == normalizedPlanType) {
                    if (ptw.goalSectionInformations == null) {
                        ptw.goalSectionInformations = new List<PlanTempWrapper.SectionInformation>();
                    }
                    if (ptw.stepSectionInformations == null) {
                        ptw.stepSectionInformations = new List<PlanTempWrapper.SectionInformation>();
                    }
                    return ptw;
                }
            }

            return emptyWrapper;
        } catch (Exception ex) {
            System.debug('Exception in getBlueprintSectionsForPlan: ' + ex.getMessage());
            throw new AuraHandledException('Error in getBlueprintSectionsForPlan: ' + ex.getMessage());
        }
    }

    /**
     * @description Flattens goal blueprint field definitions for a Plan in section order, deduped by field API name.
     * @param planId Id of the Plan__c record whose plan type resolves to a Plan Template with goal blueprints
     * @return Ordered list of PicklistWrapper entries (label, value API name, etc.); empty when no blueprint
     */
    public static List<PlanTempWrapper.PicklistWrapper> getGoalBlueprintFieldsInOrderForPlan(Id planId) {
        List<PlanTempWrapper.PicklistWrapper> ordered = new List<PlanTempWrapper.PicklistWrapper>();
        if (planId == null) {
            return ordered;
        }
        PlanTempWrapper ptw = getBlueprintSectionsForPlan(planId);
        if (ptw == null || ptw.goalSectionInformations == null || ptw.goalSectionInformations.isEmpty()) {
            return ordered;
        }
        Set<String> seenApis = new Set<String>();
        for (PlanTempWrapper.SectionInformation sec : ptw.goalSectionInformations) {
            if (sec == null || sec.fieldBlueprints == null) {
                continue;
            }
            for (PlanTempWrapper.PicklistWrapper pw : sec.fieldBlueprints) {
                if (pw == null || String.isBlank(pw.value)) {
                    continue;
                }
                if (seenApis.contains(pw.value)) {
                    continue;
                }
                seenApis.add(pw.value);
                ordered.add(pw);
            }
        }
        return ordered;
    }

    /**
     * @description Flattens step blueprint field definitions for a Plan in section order, deduped by field API name.
     * @param planId Id of the Plan__c record whose plan type resolves to a Plan Template with step blueprints
     * @return Ordered list of PicklistWrapper entries (label, value API name, etc.); empty when no blueprint
     */
    public static List<PlanTempWrapper.PicklistWrapper> getStepBlueprintFieldsInOrderForPlan(Id planId) {
        List<PlanTempWrapper.PicklistWrapper> ordered = new List<PlanTempWrapper.PicklistWrapper>();
        if (planId == null) {
            return ordered;
        }
        PlanTempWrapper ptw = getBlueprintSectionsForPlan(planId);
        if (ptw == null || ptw.stepSectionInformations == null || ptw.stepSectionInformations.isEmpty()) {
            return ordered;
        }
        Set<String> seenApis = new Set<String>();
        for (PlanTempWrapper.SectionInformation sec : ptw.stepSectionInformations) {
            if (sec == null || sec.fieldBlueprints == null) {
                continue;
            }
            for (PlanTempWrapper.PicklistWrapper pw : sec.fieldBlueprints) {
                if (pw == null || String.isBlank(pw.value)) {
                    continue;
                }
                if (seenApis.contains(pw.value)) {
                    continue;
                }
                seenApis.add(pw.value);
                ordered.add(pw);
            }
        }
        return ordered;
    }
    
    /**
     * @description Builds a SectionInformation from a section name and a raw JSON field list.
     * @param sectionName Display name for the section
     * @param fieldListJson JSON string containing the array of field config objects
     * @return Populated SectionInformation wrapper
     */
    private static PlanTempWrapper.SectionInformation buildSectionInfo(String sectionName, String fieldListJson) {
        PlanTempWrapper.SectionInformation section = new PlanTempWrapper.SectionInformation();
        section.sectionName = sectionName;
        section.fieldBlueprints = new List<PlanTempWrapper.PicklistWrapper>();

        if (String.isNotBlank(fieldListJson)) {
            try {
                List<Object> fieldDetailList = (List<Object>) JSON.deserializeUntyped(fieldListJson);
                for (Object fdl : fieldDetailList) {
                    if (fdl != null) {
                        Map<String, Object> mapObject = (Map<String, Object>) fdl;
                        PlanTempWrapper.PicklistWrapper pw = new PlanTempWrapper.PicklistWrapper();
                        pw.label = String.valueOf(mapObject.get('label'));
                        pw.value = String.valueOf(mapObject.get('value'));
                        pw.dataType = String.valueOf(mapObject.get('dataType'));
                        pw.isMandatory = String.valueOf(mapObject.get('isMandatory')) == 'true';
                        pw.isEditable = String.valueOf(mapObject.get('isEditable')) == 'true';
                        pw.isReadOnly = String.valueOf(mapObject.get('isEditable')) == 'false';
                        pw.defaultValue = String.valueOf(mapObject.get('defaultValue'));
                        pw.isEditDisabled = String.valueOf(mapObject.get('isEditDisabled')) == 'true';
                        pw.isReqDisabled = String.valueOf(mapObject.get('isReqDisabled')) == 'true';
                        pw.isFormulaField = String.valueOf(mapObject.get('isFormulaField')) == 'true';
                        // Goal Status and Domain must remain user-editable in the plan wizard even if older blueprint JSON stored isEditable=false.
                        if (pw.value != null
                            && ('caresp__Domain__c'.equals(pw.value) || 'caresp__Status__c'.equals(pw.value))) {
                            pw.isEditable = true;
                            pw.isReadOnly = false;
                            pw.isEditDisabled = false;
                        }
                        section.fieldBlueprints.add(pw);
                    }
                }
            } catch (JSONException je) {
                System.debug('JSON parsing error in buildSectionInfo: ' + je.getMessage());
            }
        }
        return section;
    }

    /**
     * @description Subscriber-controlled PT_Fields_To_Show__c overrides packaged Plan_Template_Fields_To_Show__c when populated.
     */
    private static String getPlanTemplateFieldsToShowCsv(caresp__Dynamic_Plans_Restriction_Setttings__mdt setting) {
        if (setting == null) {
            return null;
        }
        if (String.isNotBlank(setting.caresp__PT_Fields_To_Show__c)) {
            return setting.caresp__PT_Fields_To_Show__c;
        }
        return setting.caresp__Plan_Template_Fields_To_Show__c;
    }

    /**
     * @description Retrieves the active Dynamic Plans Restriction Settings CMDT record.
     * @return Active Dynamic_Plans_Restriction_Setttings__mdt record
     */
    public static caresp__Dynamic_Plans_Restriction_Setttings__mdt getDynamicPlanRestrictionSettings() {
        try {
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = [
                SELECT Id, caresp__Field_Blueprint_Default_Section_Fields__c, caresp__Plan_Template_Fields_To_Show__c,
                       caresp__PT_Fields_To_Show__c, caresp__Goal_Template_Fields_To_Show__c, caresp__Step_Template_Fields_To_Show__c
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