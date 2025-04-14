@IsTest
public with sharing class FormsControllerTest {
    @IsTest
    static void testGetRelatedObjectsListMethod(){

        FormsHelper.RecordData primary = new FormsHelper.RecordData();
        primary.objectName = 'Account';
        primary.recordType = '012000000000000AAA';
        primary.parents = new List<FormsHelper.ParentData>();
        primary.fieldValue = new List<FormsHelper.FieldValue>{
            new FormsHelper.FieldValue('Name', 'Test Account')
        };

        List<FormsHelper.RecordData> children = new List<FormsHelper.RecordData>{
            new FormsHelper.RecordData(
                'Contact|Account|AccountId',
                '012000000000000AAA',
                new List<FormsHelper.ParentData>{
                    new FormsHelper.ParentData('Account', 'Account|AccountId')
                },
                new List<FormsHelper.FieldValue>{
                    new FormsHelper.FieldValue('LastName', 'Doe'),
                    new FormsHelper.FieldValue('FirstName', 'John')
                }
            )
        };

        List<FormsHelper.RecordData> parents = new List<FormsHelper.RecordData>{
            new FormsHelper.RecordData(
                'Account|Contact|AccountId',
                '012000000000000AAA',
                new List<FormsHelper.ParentData>(),
                new List<FormsHelper.FieldValue>{
                    new FormsHelper.FieldValue('Name', 'Parent Account')
                }
            )

            
        };

        // Serialize test data
        Map<String, String> params = new Map<String, String>{
            'primaryObjectList' => JSON.serialize(primary),
            'childObjectsList' => JSON.serialize(children),
            'parentObjectList' => JSON.serialize(parents),
            'grandChildObjectList' => '[]',
            'questionObjectsList' => '[]',
            'formId' => '123',
            'isVerifyApplication' => 'false'
        };

        String testObjName = 'Account';
        String primaryTestJsonString = '{"objectName":"Application_Staging__c","recordType":"012000000000000AAA","parents":[],"fieldValue":[{"fieldApi":"Primary_Reason1__c","inputValue":"Home Repair and Weatherization"},{"fieldApi":"Other_Info__c","inputValue":""},{"fieldApi":"Community_Center__c","inputValue":"Oak Hill"},{"fieldApi":"Weatherized__c","inputValue":""},{"fieldApi":"Primary_Address_Street_Address_1__c","inputValue":"address"},{"fieldApi":"Primary_Address_Street_Address_2__c","inputValue":""},{"fieldApi":"City__c","inputValue":"city"},{"fieldApi":"State__c","inputValue":"AR"},{"fieldApi":"Zip_Code__c","inputValue":"12345"},{"fieldApi":"Mailing_Address_Street_Address_1__c","inputValue":""},{"fieldApi":"Mailing_Address_Street_Address_2__c","inputValue":""},{"fieldApi":"City_Mailing_Address__c","inputValue":""},{"fieldApi":"State_Mailing_Address__c","inputValue":""},{"fieldApi":"Zip_Code_Mailing_Address__c","inputValue":""},{"fieldApi":"Primary_Phone_Number__c","inputValue":"9876543210"},{"fieldApi":"Other_Phone__c","inputValue":""},{"fieldApi":"Email__c","inputValue":"test@test.com"},{"fieldApi":"What_is_the_best_way_to_contact_you__c","inputValue":""},{"fieldApi":"How_did_you_find_out_about_us__c","inputValue":""},{"fieldApi":"Primary_Language__c","inputValue":"English"},{"fieldApi":"Secondary_Language__c","inputValue":""},{"fieldApi":"Applicant_Name__c","inputValue":"test contact"},{"fieldApi":"Living_Situation__c","inputValue":"Own a Home"},{"fieldApi":"What_type_of_home_do_you_live_in__c","inputValue":"Single Family House"},{"fieldApi":"Received_assistance_to_pay_your_rent__c","inputValue":"Yes"},{"fieldApi":"Home_s_heating_source__c","inputValue":"Electric"},{"fieldApi":"Home_s_cooling_source__c","inputValue":"Central air"},{"fieldApi":"Bedrooms_in_home__c","inputValue":""},{"fieldApi":"What_is_the_square_footage_of_your_home__c","inputValue":""},{"fieldApi":"Utility_Type__c","inputValue":"Electric"},{"fieldApi":"Name_of_Utility_Company__c","inputValue":"ACTION PROPANE INC"},{"fieldApi":"Account_Number__c","inputValue":"12345"},{"fieldApi":"Customer_Name_on_Bill__c","inputValue":"test contact"}]}';
        // String primaryTestJsonString = '{"objectName":"Application_Staging__c","recordType":"012000000000000AAA","parents":[],"fieldValue":[{"fieldApi":"Primary_Reason1__c","inputValue":"Home Repair and Weatherization"},{"fieldApi":"Other_Info__c","inputValue":""},{"fieldApi":"Community_Center__c","inputValue":"Oak Hill"},{"fieldApi":"Weatherized__c","inputValue":""},{"fieldApi":"Primary_Address_Street_Address_1__c","inputValue":"address"},{"fieldApi":"Primary_Address_Street_Address_2__c","inputValue":""},{"fieldApi":"City__c","inputValue":"city"},{"fieldApi":"State__c","inputValue":"AR"},{"fieldApi":"Zip_Code__c","inputValue":"12345"},{"fieldApi":"Mailing_Address_Street_Address_1__c","inputValue":""},{"fieldApi":"Mailing_Address_Street_Address_2__c","inputValue":""},{"fieldApi":"City_Mailing_Address__c","inputValue":""},{"fieldApi":"State_Mailing_Address__c","inputValue":""},{"fieldApi":"Zip_Code_Mailing_Address__c","inputValue":""},{"fieldApi":"Primary_Phone_Number__c","inputValue":"9876543210"},{"fieldApi":"Other_Phone__c","inputValue":""},{"fieldApi":"Email__c","inputValue":"test@test.com"},{"fieldApi":"What_is_the_best_way_to_contact_you__c","inputValue":""},{"fieldApi":"How_did_you_find_out_about_us__c","inputValue":""},{"fieldApi":"Primary_Language__c","inputValue":"English"},{"fieldApi":"Secondary_Language__c","inputValue":""},{"fieldApi":"Applicant_Name__c","inputValue":"test contact"},{"fieldApi":"What_is_the_source_of_the_income__c","inputValue":"Alimony Support"},{"fieldApi":"How_often_is_this_income_received__c","inputValue":"Weekly"},{"fieldApi":"Amount_Received_in_last_30_days__c","inputValue":"5000"},{"fieldApi":"Living_Situation__c","inputValue":"Own a Home"},{"fieldApi":"What_type_of_home_do_you_live_in__c","inputValue":"Single Family House"},{"fieldApi":"Received_assistance_to_pay_your_rent__c","inputValue":"Yes"},{"fieldApi":"Home_s_heating_source__c","inputValue":"Electric"},{"fieldApi":"Home_s_cooling_source__c","inputValue":"Central air"},{"fieldApi":"Bedrooms_in_home__c","inputValue":""},{"fieldApi":"What_is_the_square_footage_of_your_home__c","inputValue":""},{"fieldApi":"Utility_Type__c","inputValue":"Electric"},{"fieldApi":"Name_of_Utility_Company__c","inputValue":"ACTION PROPANE INC"},{"fieldApi":"Account_Number__c","inputValue":"12345"},{"fieldApi":"Customer_Name_on_Bill__c","inputValue":"test contact"}]}';
        String parentTestJsonString = '[]';
        String childrenTestJsonString = '[{"objectName":"Household_Member_Staging__c|Application_Staging__c|Application_Staging__c","parents":[{"parentApi":"Application_Staging__c","parentFieldApi":"Application_Staging__c|Application_Staging__c"}],"fieldValue":[{"fieldApi":"First_Name__c","inputValue":"test","recordIdentifier":1},{"fieldApi":"Middle_Initial__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Last_Name__c","inputValue":"contact","recordIdentifier":1},{"fieldApi":"Other_Names_Used__c","inputValue":"","recordIdentifier":1},{"fieldApi":"SSN__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Date_of_Birth__c","inputValue":"1994-03-03","recordIdentifier":1},{"fieldApi":"Legal_Sex__c","inputValue":"Male","recordIdentifier":1},{"fieldApi":"Gender_Identity__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Chosen_Name__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Pronouns__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Relation__c","inputValue":"Self","recordIdentifier":1},{"fieldApi":"Race__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Ethnicity__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Highest_Grade_Completed__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Marital_Status__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Military_Status__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Disability_Status__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Is_Migrant_Farm_Worker__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Citizenship_Status__c","inputValue":"","recordIdentifier":1},{"fieldApi":"Receiving_food_stamps__c","inputValue":"","recordIdentifier":1}],"recordType":"012000000000000AAA"}]';
        String grandChildrenTestJsonString = '[]';
        String questionTestJsonString = '[{"fieldApi":"a04BZ000001LZzMYAW","inputValue":[""]}]';
   /*     Application_Staging__c appStageData=TestFactory.createPendingApplication(null,false);
        appStageData.Email__c='test@test.com';
        insert appStageData;*/
        
        Form__c testForm = new Form__c(Signature_Page_Text__c = 'Test Signature Page Text');
        insert testForm;
        
        ContentVersion testDocument = new ContentVersion(
            Title = 'Print_JSON',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient = 'Test'
         //   Share_With_Client_Portal__c=true
        );
        insert testDocument;
        ContentDocumentLink testCDL = new ContentDocumentLink(
            LinkedEntityId = testForm.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testDocument.Id].ContentDocumentId,
            Visibility = 'AllUsers'
        );
        insert testCDL;
        
        Question_Bank__c testQuesBank = TestFactory.createQuestionBank('Test Question Bank', '', true);
        Question__c testQuestion = TestFactory.createQuestion(testQuesBank.Id, '', 'Text', true);
        Question__c testQuestion2 = TestFactory.createQuestion(testQuesBank.Id, '', 'Number', true);
        
        Answer__c testAnswer = TestFactory.createAnswer('', 'Test Answer', true, true);
        Question_Answer_Option__c testQAOption = TestFactory.createQuestionAnswerOption(testAnswer.Id, testQuestion.Id, '', 'Test Question', true);
		Question_Answer_Option__c testQAOption2 = TestFactory.createQuestionAnswerOption(testAnswer.Id, testQuestion2.Id, '', 'Test Question', true);
        
        Account testAcc = TestFactory.createAccount('Test Account', null, true);
  /*      Service__c testService = TestFactory.createService('Test Service', '', true);
        SP_Service__c testSPService = TestFactory.createSPService(testAcc.Id, testService.Id, null, false);
        testSPService.Name = Label.Alert_Referral_Reason;
        insert testSPService;
      
        Client__c testClient=testFactory.createClient('TestClient', Null, true);
        Referral__c testApplication = TestFactory.createReferral('New', 'Normal Referral', true);
        Client_Referral__c testClientReferral = TestFactory.createClientReferral(testClient.Id, testApplication.Id, '', true);
        */
        Test.startTest();
        FormsController.getRelatedObjectsList(testObjName);
   		FormsController.getFieldsData(new List<String> {'caresp__Question_Bank__c#false#false','caresp__Answer__c||Question_Answer_Option__c#true#true'},true);
    //    FormsController.getFieldsData(new List<String> {'Application_Staging__c#false#false','Household_Member_Staging__c|Application_Staging__c|Application_Staging__c#true#true'}, false);

        FormsController.getRecordTypes(testObjName);
        //String testInsertedFormId = FormsController.createFormRecord('Test Form Name', false, '', 'Test Confirmation Message', true, true, 'true', true,false,false, true, true, true, true);
        String testInsertedFormId = FormsController.createFormRecord('Test Form Name', false, '', 'Test Confirmation Message', true, true,'signaturePageText', true, true,false,false,'primaryObjectForPrefillForm',true);
     //  String testUpdatedFormId = FormsController.createFormRecord('Test Form Name', false, '', 'Test Confirmation Message', true, true,'',false,false,false,false,'',false);
        //String testUpdatedFormId = FormsController.createFormRecord('Test Form Name', true, testInsertedFormId, 'Test Confirmation Message', true, true, 'true', true,false,false);
        String testUpdatedFormId = FormsController.createFormRecord('Test Form Name', true, testInsertedFormId, 'Test Confirmation Message', true, true,'signaturePageText', true, true,false,false,'primaryObjectForPrefillForm',true);
       // FormsController.saveFormData(testUpdatedFormId, 'Test Object Structure JSON', 'Test Page Data JSON', 'Test Rules JSON', true);
        FormsController.saveFormData(testForm.id, 'Test Object Structure JSON', 'Test Page Data JSON', 'Test Rules JSON', true);
        FormsController.fetchFormData(testUpdatedFormId);
        FormsController.getDocumentTypes();
   /*     FormsController.getDocumentTypesExternal();
        FormsController.getServiceData();
        FormsController.getDataFromApplication(testApplication.Id, 'Client_Referral__c');
        FormsController.getClientData(testClient.Id);*/
        FormsController.getQuestionAnswerOptions(testQuestion.Id);
          Map<String, String> paramsMap = new Map<String, String>{
            'parentObjectList' => parentTestJsonString,
                'primaryObjectList' => primaryTestJsonString,
                'childObjectsList' => childrenTestJsonString,
                'grandChildObjectList' => grandChildrenTestJsonString,
                'formId' => questionTestJsonString,
                'isVerifyApplication' => 'true'
                };
                    
                    String jsonParams = JSON.serialize(paramsMap);
    FormsHelper.InsertResult response = FormsHelper.saveObjectStructure(JSON.serialize(params));
        String testPendingApplicationObjId = response.primaryRecordId;
    /*    FormsController.getDataFromStaging(appStageData.Id, 'Household_Member_Staging__c');
        FormsController.getDataFromStaging(appStageData.Id, 'Utility_Staging__c');
        FormsController.getDataFromStaging(appStageData.Id, 'Pending_Income__c');*/
        FormsHelper.attachJSONForPDF('Test JSON', testUpdatedFormId);
    //    FormsHelper.attachPdfToRecord(testUpdatedFormId, testPendingApplicationObjId);
     //   FormsHelper.attachPDF('Test JSON', testPendingApplicationObjId);
    /*   FormsHelper.updateStagingApplicationStatus(testPendingApplicationObjId, testApplication.Id);
        FormsHelper.getStagingApplicationConversionStatus(testPendingApplicationObjId);
        FormsHelper.getReferralName(testApplication.Id);
        FormsHelper.attachDocsToApplication(testApplication.Id, testPendingApplicationObjId);
        FormsController.getDataFromStaging(appStageData.Id, 'Utility_Staging__c');
        FormsController.getDataFromStaging(appStageData.Id, 'Pending_Income__c');*/
        FormsController.getFormsAvailableForPrint(testUpdatedFormId);
        List<FormsController.FormOptionsWrapper> printForms1 = FormsController.getFormsAvailableForPrint(testForm.id);  
        System.assertNotEquals(null, printForms1, 'PrintForm should not be null');
        FormsController.PrintWrapper PrintJson = FormsController.getPrintJson(testForm.id,testForm.id+'__'+testDocument.Title);
        System.assertNotEquals(null, PrintJson, 'Print JSON should not be null');

        List<caresp__Form__c> formlist = FormsController.getFormsList();
        System.assertNotEquals(null, formlist, 'Form should not be null');
        
        FormsHelper.attachPrintJsonToRecord('Test JSON',testForm.id, testForm.Id);
        List<ContentDocumentLink> attachments = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testForm.Id];
        System.assertNotEquals(0, attachments.size(), 'There should be attachments linked to the form');
        
   /*     FormsHelper.getFormsForPrimaryObject('Form__c',true, appStageData.Id);
        FormsController.getFormsList('Utility_Staging__c','en_US');
        FormsController.getFormsList('Utility_Staging__c','es');
        FormsController.getDocumentTypesSpanish('es',true);
        FormsController.getDocumentTypesSpanish('es',false);*/
        //FormsHelper.isEligibleServiceContact(testSPService.Id);
        Test.stopTest();
    }    
    
}