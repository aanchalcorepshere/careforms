// Test class for verifying the functionality of PlanTemplateUtil methods related to field blueprint extraction
@isTest
public class PlanTemplateUtilTest {

    // Tests getObjectFieldNames and getPlanTemplates for a valid plan template setup
    @isTest
    static void testGetObjectFieldNames() {
      
            Account acc = new Account(Name = 'Test Account');
            insert acc;
			String parentChildRelName ='Account-Contact';
            caresp__Plan_Template__c parentPlanTemplate = new caresp__Plan_Template__c(
                caresp__Parent_Child_Relation__c = parentChildRelName,
                caresp__No_of_days_to_add_in_date__c = 1,
                caresp__Parent_Date_Field__c = 'Test_Field__c',
                caresp__Plan_template_Name__c = 'Test Template',
                isActive__c = true
            );
            insert parentPlanTemplate;

            List<caresp__Plan_Template_Field_Blueprint__c> blueprints = new List<caresp__Plan_Template_Field_Blueprint__c>();
            blueprints.add(new caresp__Plan_Template_Field_Blueprint__c(
                caresp__Plan_Template__c = parentPlanTemplate.Id,
                isActive__c = true,
                caresp__Section_Name__c = 'Section1',
                caresp__Plan_Field_List__c = '[{"label":"Field1","value":"Field1","dataType":"String","isMandatory":false,"isEditable":true}]'
            ));
            blueprints.add(new caresp__Plan_Template_Field_Blueprint__c(
                caresp__Plan_Template__c = parentPlanTemplate.Id,
                isActive__c = true,
                caresp__Section_Name__c = 'Section2',
                caresp__Plan_Field_List__c = '[{"label":"Field2","value":"Field2","dataType":"Number","isMandatory":true,"isEditable":false}]'
            ));
            insert blueprints;

            // Act
            String todayDate = '01/01/2025';
            Test.startTest();
            PlanTemplateUtil.PlanTemplateUtilWrapper result = PlanTemplateUtil.getObjectFieldNames('Account', parentPlanTemplate.Id, todayDate);
         PlanTemplateUtil.getPlanTemplates(parentChildRelName);   
      //  PlanTemplateUtil.getPlanTemplates();
        	Test.stopTest();

            // Assert
            System.assertNotEquals(null, result, 'Result should not be null.');
            System.assert(result.listFieldName.size() > 0, 'Field list should not be empty.');
  //      }
    }

    @isTest
    static void testGetGoalAndStepFieldNames_blankParent_throws() {
        Boolean threw = false;
        try {
            PlanTemplateUtil.getGoalObjectFieldNames('caresp__Goal__c', '', 'cb');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Blank Goal Template Id should trigger AuraHandledException.');

        threw = false;
        try {
            PlanTemplateUtil.getStepObjectFieldNames('caresp__Step__c', '', 'cb');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Blank Step Template Id should trigger AuraHandledException.');
    }

    @isTest
    static void testGoalStepBlueprintHelpers_andSectionsForPlan() {
        String relName = 'Account-Contact';
        caresp__Plan_Template__c planTemplate = new caresp__Plan_Template__c(
            caresp__Parent_Child_Relation__c = relName,
            caresp__Plan_template_Name__c = 'Coverage Blueprint Type',
            caresp__No_of_days_to_add_in_date__c = 1,
            caresp__Parent_Date_Field__c = 'Test_Field__c',
            caresp__isActive__c = true
        );
        insert planTemplate;

        caresp__Goal_Template__c goalTemplate = new caresp__Goal_Template__c(
            caresp__Plan_Template__c = planTemplate.Id,
            caresp__isActive__c = true,
            caresp__Status__c = 'Not Started',
            caresp__Domain__c = 'Parenting',
            caresp__Description__c = 'coverage',
            caresp__Client_Name__c = 'client'
        );
        insert goalTemplate;

        caresp__Step_Template__c stepTemplate = new caresp__Step_Template__c(
            caresp__Goal_Template__c = goalTemplate.Id,
            caresp__isActive__c = true,
            caresp__Step_Type__c = 'Actionable Task',
            caresp__Type_of_Action__c = 'Create Referral',
            caresp__Description__c = 'coverage step'
        );
        insert stepTemplate;

        insert new List<caresp__Goal_Template_Field_Blueprint__c>{
            new caresp__Goal_Template_Field_Blueprint__c(
                caresp__Goal_Template__c = goalTemplate.Id,
                caresp__isActive__c = true,
                caresp__Section_Name__c = 'GoalSec',
                caresp__Goal_Field_List__c =
                    '[{"label":"Domain","value":"caresp__Domain__c","dataType":"PICKLIST","isMandatory":false,"isEditable":false,"defaultValue":"","isFormulaField":false},'
                    + '{"label":"Status","value":"caresp__Status__c","dataType":"PICKLIST","isMandatory":false,"isEditable":false}]'
            )
        };
        insert new List<caresp__Step_Template_Field_Blueprint__c>{
            new caresp__Step_Template_Field_Blueprint__c(
                caresp__Step_Template__c = stepTemplate.Id,
                caresp__isActive__c = true,
                caresp__Section_Name__c = 'StepSec',
                caresp__Step_Field_List__c =
                    '[{"label":"Description","value":"caresp__Description__c","dataType":"TEXTAREA","isMandatory":true,"isEditable":true}]'
            )
        };
        insert new List<caresp__Plan_Template_Field_Blueprint__c>{
            new caresp__Plan_Template_Field_Blueprint__c(
                caresp__Plan_Template__c = planTemplate.Id,
                caresp__isActive__c = true,
                caresp__Section_Name__c = 'PlanSec',
                caresp__Plan_Field_List__c =
                    '[{"label":"Plan Name","value":"caresp__Plan_Name__c","dataType":"STRING","isMandatory":false,"isEditable":true}]'
            )
        };

        caresp__Plan__c plan = new caresp__Plan__c(
            caresp__Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c = Date.today(),
            caresp__Parent_Child_Name__c = relName,
            caresp__Plan_Type_Txt__c = 'Coverage Blueprint Type'
        );
        insert plan;

        Test.startTest();
        PlanTemplateUtil.PlanTemplateUtilWrapper goalFields =
            PlanTemplateUtil.getGoalObjectFieldNames('caresp__Goal__c', goalTemplate.Id, 'ts');
        PlanTemplateUtil.PlanTemplateUtilWrapper stepFields =
            PlanTemplateUtil.getStepObjectFieldNames('caresp__Step__c', stepTemplate.Id, 'ts');

        Map<String, PlanTempWrapper> templatesById = PlanTemplateUtil.getPlanTemplates(relName);
        System.assert(!templatesById.isEmpty());

        PlanTempWrapper nullPlanSections = PlanTemplateUtil.getBlueprintSectionsForPlan(null);
        System.assertEquals(0, PlanTemplateUtil.getGoalBlueprintFieldsInOrderForPlan(null).size());
        System.assertEquals(0, PlanTemplateUtil.getStepBlueprintFieldsInOrderForPlan(null).size());

        PlanTempWrapper byPlan = PlanTemplateUtil.getBlueprintSectionsForPlan(plan.Id);
        List<PlanTempWrapper.PicklistWrapper> goalOrdered =
            PlanTemplateUtil.getGoalBlueprintFieldsInOrderForPlan(plan.Id);
        List<PlanTempWrapper.PicklistWrapper> stepOrdered =
            PlanTemplateUtil.getStepBlueprintFieldsInOrderForPlan(plan.Id);
        Test.stopTest();

        System.assertNotEquals(null, goalFields);
        System.assertNotEquals(null, stepFields);
        System.assertNotEquals(null, nullPlanSections);
        System.assertNotEquals(null, byPlan);
        System.assert(
            byPlan.goalSectionInformations != null && !byPlan.goalSectionInformations.isEmpty(),
            'Goal blueprint sections should resolve for matching plan type.'
        );
        System.assert(!goalOrdered.isEmpty(), 'Ordered goal blueprint fields should flatten sections.');
        System.assert(!stepOrdered.isEmpty(), 'Ordered step blueprint fields should flatten sections.');
    }

    @isTest
    static void testGetObjectFieldNames_invalidParentId_throws() {
        Boolean threw = false;
        try {
            PlanTemplateUtil.getObjectFieldNames('Account', 'not-a-valid-id', 'cb');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw);
    }

    @isTest
    static void testGetUsedPicklistValues_skipsMalformedBlueprintJson() {
        String relName = 'Account-Contact';
        caresp__Plan_Template__c pt = new caresp__Plan_Template__c(
            caresp__Parent_Child_Relation__c = relName,
            caresp__Plan_template_Name__c = 'Malformed Json Template',
            caresp__No_of_days_to_add_in_date__c = 1,
            caresp__Parent_Date_Field__c = 'CreatedDate',
            caresp__isActive__c = true
        );
        insert pt;

        insert new caresp__Plan_Template_Field_Blueprint__c(
            caresp__Plan_Template__c = pt.Id,
            caresp__isActive__c = true,
            caresp__Section_Name__c = 'Bad',
            caresp__Plan_Field_List__c = 'not-valid-json'
        );

        Test.startTest();
        PlanTemplateUtil.PlanTemplateUtilWrapper res =
            PlanTemplateUtil.getObjectFieldNames('Account', pt.Id, 'ts');
        Test.stopTest();

        System.assertNotEquals(null, res);
    }

  /*  @isTest
    static void testGetPlanTemplates() {

            Account acc = new Account(Name = 'Test Account 2');
            insert acc;

            Test.startTest();
            PlanTemplateUtil.PlanTemplateUtilWrapper result = PlanTemplateUtil.getObjectFieldNames('Account', acc.Id, null);
            Test.stopTest();

            
            System.assertNotEquals(null, result, 'Result should not be null.');
   
    }
    */
}