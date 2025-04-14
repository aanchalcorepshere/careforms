@isTest
public class PlanTemplateTriggerHelperTest {

    @testSetup
    static void setupData() {
        // Setup any labels or required data for the tests
      //  System.Label.Field_Blueprint_Default_Section_Fields = 'caresp__Plan_Start_Date__c,caresp__Plan_End_Date__c';

        // Insert necessary data or mock metadata info
        Plan_Template__c parentPlanTemplate = new Plan_Template__c( Parent_Child_Relation__c = 'Parent-Child',caresp__No_of_days_to_add_in_date__c =1, caresp__Parent_Date_Field__c='1', caresp__Plan_template_Name__c='test');
        
        insert parentPlanTemplate;
    }

    @isTest
    public static void testAfterInsertTrigger() {
        // Create a new Plan Template record
        Plan_Template__c newPlanTemplate = new Plan_Template__c(
           // Name = 'Test Plan Template',
             Parent_Child_Relation__c = 'Parent-Child',caresp__No_of_days_to_add_in_date__c =1, caresp__Parent_Date_Field__c='1', caresp__Plan_template_Name__c='test'
        );

        Test.startTest();
        insert newPlanTemplate; // Trigger AfterInsert
        Test.stopTest();

        // Verify that a default Plan Template Field Blueprint was created
        List<Plan_Template_Field_Blueprint__c> blueprints = [
            SELECT Id, Plan_Template__c, Plan_Field_List__c, Section_Name__c 
            FROM Plan_Template_Field_Blueprint__c 
            WHERE Plan_Template__c = :newPlanTemplate.Id
        ];

        System.assertEquals(1, blueprints.size(), 'A default field blueprint should be created');
        System.assertEquals(
            'Plan Details',
            blueprints[0].Section_Name__c,
            'The section name should be "Plan Details"'
        );

        // Verify the JSON structure
     /*   List<Map<String, String>> fieldList = (List<Map<String, String>>) JSON.deserializeUntyped(blueprints[0].Plan_Field_List__c);
        System.assert(fieldList.size() > 0, 'The field list should not be empty');
        System.assertEquals('caresp__Plan_Start_Date__c', fieldList[0].get('value'), 'First field should be Plan Start Date');
        System.assertEquals('true', fieldList[0].get('isMandatory'), 'Plan Start Date should be mandatory');*/
    }

    @isTest
    public static void testCreateDefaultSectionWithMockedMetadata() {
        // Mock MetadataInfoWrapper and field property logic
        Plan_Template__c mockPlanTemplate = new Plan_Template__c(
         //   Name = 'Mock Plan Template',
             Parent_Child_Relation__c = 'Parent-Child',caresp__No_of_days_to_add_in_date__c =1, caresp__Parent_Date_Field__c='1', caresp__Plan_template_Name__c='test'
        );
        insert mockPlanTemplate;

        // Mock method responses using Stubs (if applicable)
        Test.startTest();
        PlanTemplateTriggerHelper.createDefaultSection(new List<SObject>{ mockPlanTemplate });
        Test.stopTest();

        // Verify the field blueprint creation
        Plan_Template_Field_Blueprint__c blueprint = [
            SELECT Id, Plan_Template__c, Plan_Field_List__c 
            FROM Plan_Template_Field_Blueprint__c 
            WHERE Plan_Template__c = :mockPlanTemplate.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, blueprint, 'Blueprint record should be created');
        System.assert(blueprint.Plan_Field_List__c.contains('caresp__Plan_Start_Date__c'), 'Field list should include Plan Start Date');
    }
}