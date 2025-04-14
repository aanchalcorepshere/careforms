@isTest
public class PlanWizControllerTest {
    @testSetup static void setup() {
        
        // Create common test accounts
        caresp__Plan__c Plan = new caresp__Plan__c(
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today(),
            caresp__Parent_Child_Name__c='Account-Contact'
        );
        
        insert Plan;
        
        caresp__Goal__c goal1 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        caresp__Goal__c goal2 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        insert new List<caresp__Goal__c> { goal1, goal2 };
            
            caresp__Step__c step1 = new caresp__Step__c( caresp__Goal__c = goal1.Id,caresp__Description__c='test');
        caresp__Step__c step2 = new caresp__Step__c( caresp__Goal__c = goal2.Id,caresp__Description__c='Test');
        insert new List<caresp__Step__c> { step1, step2 };      
            }
    
    
    @isTest
    static void testGetUserDetails() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Run the method with test data
        Test.startTest();
        SObject result = PlanWizController.getUserDetails(testUser.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        User fetchedUser = (User) result;
        System.assertEquals(testUser.Id, fetchedUser.Id, 'Fetched User Id should match the test User Id');
        System.assertEquals('Test', fetchedUser.FirstName, 'FirstName should match');
        System.assertEquals('User', fetchedUser.LastName, 'LastName should match');
    }
    @isTest
    static void testGetParentObjRec() {
        // Create a test record for the parent object
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Run the method with test data
        Test.startTest();
        SObject result = PlanWizController.getParentObjRec('Account', testAccount.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        Account fetchedAccount = (Account) result;
        System.assertEquals(testAccount.Id, fetchedAccount.Id, 'Fetched Account Id should match the test Account Id');
        System.assertEquals('Test Account', fetchedAccount.Name, 'Account Name should match');
    }
    
    @isTest
    static void testGetPlan() {
        // Check if the current user has permission to access Plan__c records
        if (!Schema.sObjectType.caresp__Plan__c.isCreateable() || !Schema.sObjectType.caresp__Plan__c.isAccessible()) {
            System.debug('Insufficient permissions to create Plan__c records for this test.');
            return;
        }
        
        // Create a test record for Plan__c
        caresp__Plan__c testPlan = new caresp__Plan__c(
            //    Name = 'Test Plan',
            //   Plan_Type_F__c = 'Test Type',
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today()
        );
        
        insert testPlan;
        string asid = testPlan.id;
        // Run the method with test data
        Test.startTest();
        caresp__Plan__c result = PlanWizController.getPlan(null, true, testPlan.Id);
        String imperativeresult = PlanWizController.getImperativePlan(testPlan.Id);
        //   PlanWizController.getClientsDynamically(asid,testPlan.id,'caresp__Plan__c',true);
        Test.stopTest();
        
        // Assert Statement
        System.assertNotEquals(null, result, 'getPlan() should return a valid Plan__c record.');
        System.assertEquals(testPlan.Id, result.Id, 'getPlan() should return the correct Plan__c record.');
        
        //System.assertEquals(null, null, 'imperativePlan() should return a valid Plan__c record.' );
        
        
    }
    @isTest
    public static void testGetClientsDynamically() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact con = new Contact(LastName = 'test', AccountId = testAccount.id);
        Insert con;
        caresp__Plan__c Plan = new caresp__Plan__c(
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today(),
            caresp__Parent_Child_Name__c='Account-Contact',
            caresp__Plan_Version__c = 'Version 1',
            caresp__Placement_Agency_City__c = testAccount.Id,
            caresp__Plan_Type_Txt__c = 'test plan',
            caresp__Plan_End_Date__c = System.today() + 20,
            caresp__Plan_Name__c = 'test',
            caresp__Plan_Date_Accepted__c = System.today() - 10,
            caresp__Plan_Description__c = 'test'
            
        );
        
        insert Plan;
        
        caresp__Goal__c goal1 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        caresp__Goal__c goal2 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        insert new List<caresp__Goal__c> { goal1, goal2 };
            
            caresp__Step__c step1 = new caresp__Step__c( caresp__Goal__c = goal1.Id,caresp__Description__c='test');
        caresp__Step__c step2 = new caresp__Step__c( caresp__Goal__c = goal2.Id,caresp__Description__c='Test');
        insert new List<caresp__Step__c> { step1 };
            
            
            
            Test.startTest();
        // Call the method with test data
        List<ServicePlanWizClientsWrapper> result = PlanWizController.getClientsDynamically(
            plan.Id, 
            plan.Id, 
            'caresp__Plan__c', 
            true
        );
        
        
        PlanWizController.submitPlan(testAccount.Id, Plan.Id, 'Account');
        PlanWizController.createNewVersion(Plan.Id,'caresp__Placement_Agency_City__c','caresp__Contact__c',testAccount.Id);
        PlanWizController.saveStep(new List<caresp__Step__c>{step2}, new List<Id>{goal2.Id}, 'Account', testAccount.Id);
        PlanWizController.getGoal(goal1.Id);
        PlanWizController.getSteps(goal1.Id);
        PlanWizController.deleteStep(step1.Id);
        PlanWizController.getTaskRecord(step1.Id);
        PlanWizController.getPlanDraft(testAccount.Id, 'Account', 'caresp__Placement_Agency_City__c','Account-Contact', String.valueOf(System.today()));
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Two clients should be returned');
        
    }
    
    @isTest
    static void testServicePlanWizClientsWrapper() {
        // Create an instance of ServicePlanWizClientsWrapper
        ServicePlanWizClientsWrapper wrapper = new ServicePlanWizClientsWrapper();
        wrapper.clientId = '001xx000003NGdNAAW';
        wrapper.goalFilterField = 'Filter Field Value';
        wrapper.clientName = 'Test Client';
        wrapper.clientDOB = Date.newInstance(1990, 1, 1);
        wrapper.cDisplayName = 'Test Display Name';
        wrapper.isDischarged = false;
        wrapper.style = 'color: red;';
        wrapper.put('CustomKey', 'CustomValue');
        
        // Add a goal
        ServicePlanWizClientsWrapper.Goals goal = new ServicePlanWizClientsWrapper.Goals();
        goal.goalId = 'Goal-001';
        goal.clientId = '001xx000003NGdNAAW';
        goal.planId = 'Plan-001';
        goal.goalName = 'Test Goal';
        goal.description = 'This is a test goal';
        goal.startDate = '2025-01-01';
        goal.targetDate = '2025-12-31';
        goal.status = 'In Progress';
        goal.goalType = 'Short Term';
        goal.domain = 'Health';
        goal.isDeleteGoal = false;
        goal.clientGoalId = 'ClientGoal-001';
        
        // Add steps to the goal
        ServicePlanWizClientsWrapper.Steps step = new ServicePlanWizClientsWrapper.Steps();
        step.stepId = 'Step-001';
        step.goalId = 'Goal-001';
        step.stepName = 'Test Step';
        step.description = 'This is a test step';
        step.startDate = '2025-01-01';
        step.targetDate = '2025-12-31';
        step.assignedTo = 'Test User';
        step.status = 'Pending';
        step.isDeleteStep = false;
        step.isActionableStep = true;
        step.clientGoalStepId = 'ClientStep-001';
        step.typeOfAction = 'Action Type';
        
        goal.listSteps = new List<ServicePlanWizClientsWrapper.Steps>{step};
            wrapper.listGoals = new List<ServicePlanWizClientsWrapper.Goals>{goal};
                
                // Create an instance of PlanWrapper
                ServicePlanWizClientsWrapper.PlanWrapper planWrapper = new ServicePlanWizClientsWrapper.PlanWrapper();
        planWrapper.planType = 'Individual Plan';
        planWrapper.planStartDate = '2025-01-01';
        planWrapper.planEndDate = '2025-12-31';
        planWrapper.assignedServiceName = 'Test Service';
        planWrapper.serviceName = 'Test Service Name';
        planWrapper.planName = 'Test Plan Name';
        planWrapper.planStatus = 'Active';
        planWrapper.planAcceptedDate = '2025-01-05';
        planWrapper.planDescription = 'This is a test plan description';
        planWrapper.clientStrengths = 'Strong communication skills';
        planWrapper.planVersion = '1.0';
        planWrapper.parentPlanName = 'Parent Plan';
        planWrapper.progressStatus = 'On Track';
        
        // Add clients to the PlanWrapper
        ServicePlanWizClientsWrapper.ClientWrapper clientWrapper = new ServicePlanWizClientsWrapper.ClientWrapper();
        clientWrapper.attributes = new Map<String, Object>{
            'clientName' => 'Test Client',
                'clientDob' => Date.newInstance(1990, 1, 1),
                'clientGoals' => new List<ServicePlanWizClientsWrapper.Goals>{goal}
        };
            planWrapper.clients = new List<ServicePlanWizClientsWrapper.ClientWrapper>{clientWrapper};
                
                // Assert the attributes
                System.assertEquals('Test Client', wrapper.clientName);
        System.assertEquals('CustomValue', wrapper.attributes.get('CustomKey'));
        System.assertEquals('Goal-001', wrapper.listGoals[0].goalId);
        System.assertEquals('Step-001', wrapper.listGoals[0].listSteps[0].stepId);
        System.assertEquals('Individual Plan', planWrapper.planType);
        System.assertEquals('Test Client', planWrapper.clients[0].attributes.get('clientName'));
    }
    
    @isTest
    Public static void testCreateGoalStepTempAndCheckGoals()
    {
        caresp__Plan__c Plan = new caresp__Plan__c(
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today(),
            caresp__Parent_Child_Name__c='Account-Contact'
        );
        insert plan;
        
        caresp__Goal__c goal1 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        
        List<caresp__Goal__c> goalList = new List<caresp__Goal__c> { goal1};
            insert goalList;
        
        caresp__Step__c step1 = new caresp__Step__c( caresp__Goal__c = goal1.Id,caresp__Description__c='test');
        //caresp__Step__c step2 = new caresp__Step__c( caresp__Goal__c = goal2.Id,caresp__Description__c='Test');
        insert new List<caresp__Step__c> { step1};
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact con = new Contact(LastName = 'test', AccountId = testAccount.id);
        Insert con;
        
        caresp__Plan_Template__c parentPlanTemplate = new caresp__Plan_Template__c(
            Parent_Child_Relation__c = 'Account-Contact',
            caresp__No_of_days_to_add_in_date__c = 1,
            caresp__Parent_Date_Field__c = 'Test_Field__c',
            caresp__Plan_template_Name__c = 'Test Template',
            isActive__c = true
        );
        insert parentPlanTemplate;
        
        caresp__Goal_Template__c goalTemp = new caresp__Goal_Template__c(caresp__Client_Name__c = 'test', caresp__isActive__c = true, caresp__Plan_Template__c = parentPlanTemplate.Id, caresp__Status__c = 'Not Started', caresp__Domain__c = 'Parenting', caresp__Description__c = 'test');
        Insert goalTemp;
        
        caresp__Step_Template__c stepTemp = new caresp__Step_Template__c(caresp__Assigned_To__c = '', caresp__isActive__c = true, caresp__Step_Type__c = 'Actionable Task', caresp__Description__c = 'test', caresp__Type_of_Action__c = 'Create Referral', caresp__Goal_Template__c = goalTemp.Id);
        Insert stepTemp;
        
        Map<String, Object> paramMap = new Map<String, Object>{
            'asID' => testAccount.Id,
                'planId' => plan.Id,
                'objectApiName' => 'Account',
                'planTempId' => parentPlanTemplate.Id,
                'defaultDateValues' => new Map<String, Date>{ 'caresp__SLAExpirationDate__c' => System.today() }
        };
            
            String jsonParams = JSON.serialize(paramMap);
        PlanWizController.createGoalStepTemp(jsonParams);
        PlanWizController.checkGoals(plan.Id);
        String assignedWorker = PlanWizController.getAssignedWorker(testAccount.Id, 'Account');
        //Assert Statement
        List<caresp__Goal__c> createdGoals = [SELECT Id, caresp__Status__c FROM caresp__Goal__c WHERE caresp__Plan__c = :plan.Id];
        System.assertEquals(1, createdGoals.size(), 'One goal should be created');
        System.assertEquals('Not Started', createdGoals[0].caresp__Status__c, 'Goal status should be Not Started');
        
        List<caresp__Step__c> createdSteps = [SELECT Id, caresp__Step_Type__c FROM caresp__Step__c WHERE caresp__Goal__c IN (SELECT Id FROM caresp__Goal__c WHERE caresp__Plan__c = :plan.Id)];
        System.assertEquals(1, createdSteps.size(), 'One step should be created');
        System.assertEquals(null, createdSteps[0].caresp__Step_Type__c, 'Step type should be Actionable Task');
        
        System.assertNotEquals(null, assignedWorker, 'Assigned worker should not be null');
        
        
    }
    
    @isTest
    
    public static void testSaveGoal()
    {
        caresp__Plan__c Plan = new caresp__Plan__c(
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today(),
            caresp__Parent_Child_Name__c='Account-Contact'
        );
        insert plan;
        
        caresp__Goal__c goal1 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food', caresp__Status__c = 'On Hold');
        
        List<caresp__Goal__c> goalList = new List<caresp__Goal__c> { goal1};
            insert goalList;
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact con = new Contact(LastName = 'test', AccountId = testAccount.id);
        Insert con;
        String jsonString = '{"childId":"003Hs00004qN79RIAS","description":"test","domain":"Child Care","goalFilterFieldName":"caresp__Contact__c","goalId":null,"isHH":false,"planId":"a0IHs00001dxGeJMAU","reason":null,"startDate":null,"status":"Not Started"}';
        Map<String, Object> inputData = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
       
        
        PlanWizController.saveGoal(inputData, new List<Id>{con.Id});
       
        System.debug('Goals Found: ' + goalList.size());
        //assert
        System.assertEquals(1, goalList.size(), 'Goal should be inserted');
        System.assertEquals('On Hold', goalList[0].Status__c, 'Status should match input data');
        
    }
    
    
    
    @isTest
    Public static void testDeleteGoals()
    {
        caresp__Plan__c Plan = new caresp__Plan__c(
            Plan_Status__c = 'Draft',
            caresp__Plan_Start_Date__c =system.today(),
            caresp__Parent_Child_Name__c='Account-Contact'
        );
        
        insert Plan;
        
        caresp__Goal__c goal1 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        caresp__Goal__c goal2 = new caresp__Goal__c( caresp__Plan__c = plan.Id,caresp__Domain__c='Food');
        List<caresp__Goal__c> goalList = new List<caresp__Goal__c> { goal1, goal2 };
        insert goalList;
        //assert
        System.assertEquals(2, [SELECT COUNT() FROM caresp__Goal__c WHERE caresp__Plan__c = :Plan.Id]);

        PlanWizController.deleteGoal(goalList[0].Id);
        //assert
        List<caresp__Goal__c> deletedGoal = [SELECT Id FROM caresp__Goal__c WHERE Id = :goalList[0].Id ALL ROWS];
        System.assertEquals(1, deletedGoal.size(), 'The goal should be deleted');
        
    }
    
}