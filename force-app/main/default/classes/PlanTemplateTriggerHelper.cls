// Trigger helper class for handling DML events related to Plan Template.
// Implements ITriggerHandler to standardize trigger handling methods.
public with sharing class PlanTemplateTriggerHelper implements ITriggerHandler 
{
    // Executes before inserting new records.
    public void BeforeInsert(List<SObject> newItems) {}

    // Executes before updating existing records.
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

    // Executes before deleting records.
    public void BeforeDelete(Map<Id, SObject> oldItems) {}

    // Executes after records are inserted.
    public void AfterInsert(Map<Id, SObject> newItems)
    {
        createDefaultSection(newItems.values());
    }

    // Executes after records are updated.
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}

    // Executes after records are deleted.
    public void AfterDelete(Map<Id, SObject> oldItems) {}

    // Executes after records are undeleted.
    public void AfterUndelete(Map<Id, SObject> oldItems) {}

    // Creates a default section and inserts a field blueprint for a newly inserted plan template.
    public static void createDefaultSection(List<Sobject> newItemList) {
        // Input validation (Critical fix)
        if (newItemList == null || newItemList.isEmpty()) {
            return;
        }
        
        try {
            List<caresp__Plan_Template__c> newItems = (List<caresp__Plan_Template__c>) newItemList;
            
            // Null safety check (Critical fix)
            if (newItems.isEmpty() || newItems[0] == null) {
                return;
            }
            
            List<Map<String, String>> jsonDefault = new List<Map<String, String>>();
            caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = PlanTemplateUtil.getDynamicPlanRestrictionSettings();
            
            if (activeSetting == null) {
                System.debug('No active restriction settings found');
                return;
            }
            
            List<String> lstFieldsForDefaultSection = activeSetting.caresp__Field_Blueprint_Default_Section_Fields__c != null ? 
                activeSetting.caresp__Field_Blueprint_Default_Section_Fields__c.split(',') : new List<String>();
            
            // Safe string operations (High fix)
            String parentChildRelation = String.valueOf(newItems[0].get('caresp__Parent_Child_Relation__c'));
            if (String.isBlank(parentChildRelation) || !parentChildRelation.contains('-')) {
                System.debug('Invalid parent child relation format: ' + parentChildRelation);
                return;
            }
            
            String parentObjName = parentChildRelation.split('-')[0];
            PlanWizController.MetadataInfoWrapper metadataInfo = PlanWizController.getMetadataInfo(parentObjName, null);
            List<Map<String, String>> mapPlanFieldProp = PlanTemplateUtil.getFieldNames('caresp__Plan__c');

            if (mapPlanFieldProp != null && !mapPlanFieldProp.isEmpty()) {
                for (Map<String, String> mapProp : mapPlanFieldProp) { 
                    if (mapProp != null && lstFieldsForDefaultSection.contains(mapProp.get('name'))) {
                        Map<String, String> newField = new Map<String, String>();
                        newField.put('label', mapProp.get('label') + ' (' + mapProp.get('name') + ')');
                        newField.put('value', mapProp.get('name'));
                        newField.put('dataType', mapProp.get('dataType'));
                        newField.put('isMandatory', mapProp.get('isMandatory'));
                        newField.put('isEditable', mapProp.get('isEditable'));
                        newField.put('isFormulaField', mapProp.get('isFormulaField'));

                        if (mapProp.get('name') == 'caresp__Plan_Start_Date__c') {
                            newField.put('isMandatory','true');
                        }

                        jsonDefault.add(newField);
                    }
                }

                // Create blueprint record with proper security (High fix - removed redundant FLS checks)
                if (!jsonDefault.isEmpty()) {
                    caresp__Plan_Template_Field_Blueprint__c blueprintRecord = new caresp__Plan_Template_Field_Blueprint__c(
                        caresp__isActive__c = true, 
                        caresp__Plan_Template__c = newItems[0].Id, 
                        caresp__Plan_Field_List__c = JSON.serialize(jsonDefault), 
                        caresp__Section_Name__c = 'Plan Details'
                    );
                    
                    // Use Security.stripInaccessible for proper FLS enforcement
                    List<caresp__Plan_Template_Field_Blueprint__c> blueprintList = new List<caresp__Plan_Template_Field_Blueprint__c>{blueprintRecord};
                    List<SObject> insertableRecords = Security.stripInaccessible(AccessType.CREATABLE, blueprintList).getRecords();
                    
                    if (!insertableRecords.isEmpty()) {
                        Database.insert(insertableRecords, AccessLevel.USER_MODE);
                    }
                }
            }
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error in createDefaultSection: ' + ex.getMessage());
            // Don't throw exception in trigger context, just log the error
        }
    }
}