@isTest
public class PlanTemplateUtilTest {
    @isTest
    static void testGetObjectFieldNames() {
      
            Account acc = new Account(Name = 'Test Account');
            insert acc;
			String parentChildRelName ='Account-Contact';
            caresp__Plan_Template__c parentPlanTemplate = new caresp__Plan_Template__c(
                Parent_Child_Relation__c = parentChildRelName,
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