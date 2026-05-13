/**
 * @description Wrapper representing a Plan Template structure, including plan field sections,
 *              goal field blueprints, and step field blueprints for the wizard UI.
 * @author Team Standard
 * @lastModified May 2026
 */
public with sharing class PlanTempWrapper {

    @AuraEnabled
    public String templateName {get; set;}

    /** Plan-level field sections from Plan_Template_Field_Blueprint__c */
    @AuraEnabled
    public List<SectionInformation> sectionInformations {get; set;}

    /** Goal-level field sections from Goal_Template_Field_Blueprint__c */
    @AuraEnabled
    public List<SectionInformation> goalSectionInformations {get; set;}

    /** Step-level field sections from Step_Template_Field_Blueprint__c */
    @AuraEnabled
    public List<SectionInformation> stepSectionInformations {get; set;}

    @AuraEnabled
    public String parentDateField {get; set;}

    @AuraEnabled
    public Decimal noOfDaysToAdd {get; set;}
    
    // Inner class to hold section-specific information, including fields and section name.
    Public Class SectionInformation {
        @AuraEnabled Public String sectionName {get; set;}
        @AuraEnabled Public List<PicklistWrapper> fieldBlueprints {get; set;}
    }

    // Inner class to define the structure of individual picklist or field data,
    // including metadata like type, default value, and editability.
    Public class PicklistWrapper {
        @AuraEnabled Public String label  {get; set;}
        @AuraEnabled Public String value  {get; set;}
        @AuraEnabled Public String dataType  {get; set;}
        @AuraEnabled Public Boolean isMandatory  {get; set;}
        @AuraEnabled public Boolean isEditable  {get; set;}
        @AuraEnabled public Boolean isReadOnly  {get; set;}
        @AuraEnabled public String defaultValue  {get; set;}
        @AuraEnabled public Boolean isEditDisabled  {get; set;}
        @AuraEnabled public Boolean isReqDisabled  {get; set;}
        @AuraEnabled public Boolean isFormulaField {get; set;}
    }
}