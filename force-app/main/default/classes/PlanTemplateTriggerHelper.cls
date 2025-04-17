public with sharing class PlanTemplateTriggerHelper implements ITriggerHandler 
{
    public void BeforeInsert(List<SObject> newItems) {}
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    public void AfterInsert(Map<Id, SObject> newItems)
    {
        
        createDefaultSection(newItems.values());
        
    }
    
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems) {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    Public Static void createDefaultSection(List<Sobject> newItemList)
    {
        List<caresp__Plan_Template__c> newItems = (List<caresp__Plan_Template__c>) newItemList;
        
        List<Map<String, String>> jsonDefault = new List<Map<String, String>>();
        caresp__Dynamic_Plans_Restriction_Setttings__mdt activeSetting = PlanTemplateUtil.getDynamicPlanRestrictionSettings();
        List<String> lstFieldsForDefaultSection = activeSetting.caresp__Field_Blueprint_Default_Section_Fields__c != null ? activeSetting.caresp__Field_Blueprint_Default_Section_Fields__c.split(',') :new List<String>();
        PlanWizController.MetadataInfoWrapper metadataInfo = PlanWizController.getMetadataInfo(String.valueOf(newItems[0].get('caresp__Parent_Child_Relation__c')).split('-')[0], null);
        List<Map<String, String>> mapPlanFieldProp = PlanTemplateUtil.getFieldNames('caresp__Plan__c');
       
        
        if(mapPlanFieldProp != null)
        {
            for(Map<String, String> mapProp : mapPlanFieldProp)
            { 
                if(lstFieldsForDefaultSection.contains(mapProp.get('name')))
                {
                    Map<String, String> newField = new Map<String, String>();
                    newField.put('label', mapProp.get('label') + ' (' + mapProp.get('name') + ')');
                    newField.put('value', mapProp.get('name'));
                    newField.put('dataType', mapProp.get('dataType'));
                    newField.put('isMandatory', mapProp.get('isMandatory'));
                    newField.put('isEditable', mapProp.get('isEditable'));
                    newField.put('isFormulaField', mapProp.get('isFormulaField'));
                    
                    if(mapProp.get('name') == 'caresp__Plan_Start_Date__c')
                    {
                        newField.put('isMandatory','true');

                    }
                     
                    jsonDefault.add(newField);
                }
            }    
            if (Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.isCreateable() &&
            Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.fields.caresp__isActive__c.isCreateable() &&
            Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.fields.caresp__Plan_Template__c.isCreateable() &&
            Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.fields.caresp__Plan_Field_List__c.isCreateable() &&
            Schema.sObjectType.caresp__Plan_Template_Field_Blueprint__c.fields.caresp__Section_Name__c.isCreateable()) {
            
            Insert (new caresp__Plan_Template_Field_Blueprint__c(
                caresp__isActive__c = true, 
                caresp__Plan_Template__c = newItems[0].Id, 
                caresp__Plan_Field_List__c = JSON.serialize(jsonDefault), 
                caresp__Section_Name__c = 'Plan Details'
            ));
        }
            
        }
        
    }
}