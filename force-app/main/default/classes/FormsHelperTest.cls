@IsTest
private class FormsHelperTest {
    @TestSetup
    static void setupData() {
        Form__c form = new Form__c(
            Form_Name__c = 'Test Form Name',
            Object_Name_for_Prefill_Fields__c = 'Contact',
            Prefill_Fields__c = true,
            Create_PDF_Only__c = false
        );
        insert form;

        Account account = new Account(Name = 'Setup Account');
        insert account;

        Contact contact = new Contact(
            FirstName = 'Setup',
            LastName = 'Contact',
            AccountId = account.Id,
            Email = 'setup@example.com'
        );
        insert contact;
    }

    private static FormsHelper.FieldValue fieldValue(String apiName, String value) {
        return fieldValue(apiName, value, null);
    }

    private static FormsHelper.FieldValue fieldValue(String apiName, String value, Integer identifier) {
        FormsHelper.FieldValue fv = new FormsHelper.FieldValue();
        fv.fieldApi = apiName;
        fv.inputValue = value;
        fv.recordIdentifier = identifier;
        return fv;
    }

    private static FormsHelper.ParentData parentLink(
        String parentApi,
        String relationshipField,
        Integer parentRecordIdentifier,
        String parentId
    ) {
        FormsHelper.ParentData parent = new FormsHelper.ParentData();
        parent.parentApi = parentApi;
        parent.parentFieldApi = relationshipField;
        parent.parentRecordIdentifier = parentRecordIdentifier;
        parent.parentId = parentId;
        return parent;
    }

    private static FormsHelper.RecordData recordData(
        String objectName,
        Integer recordIdentifier,
        List<FormsHelper.FieldValue> fields,
        List<FormsHelper.ParentData> parents
    ) {
        FormsHelper.RecordData record = new FormsHelper.RecordData();
        record.objectName = objectName;
        record.recordIdentifier = recordIdentifier;
        record.fieldValue = fields != null ? fields : new List<FormsHelper.FieldValue>();
        record.parents = parents != null ? parents : new List<FormsHelper.ParentData>();
        return record;
    }

    private static String buildPayload(
        FormsHelper.RecordData primary,
        List<FormsHelper.RecordData> parents,
        List<FormsHelper.RecordData> children,
        List<FormsHelper.RecordData> grandchildren
    ) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('primaryObjectList', primary == null ? null : JSON.serialize(primary));
        payload.put(
            'parentObjectList',
            JSON.serialize(parents == null ? new List<FormsHelper.RecordData>() : parents)
        );
        payload.put(
            'childObjectsList',
            JSON.serialize(children == null ? new List<FormsHelper.RecordData>() : children)
        );
        payload.put(
            'grandChildObjectList',
            JSON.serialize(grandchildren == null ? new List<FormsHelper.RecordData>() : grandchildren)
        );
        return JSON.serialize(payload);
    }

    private static Contact fetchSetupContact() {
        return [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Email = 'setup@example.com'
            LIMIT 1
        ];
    }

    private static Form__c fetchSetupForm() {
        return [
            SELECT Id, Form_Name__c
            FROM Form__c
            WHERE Form_Name__c = 'Test Form Name'
            LIMIT 1
        ];
    }

    @IsTest
    static void testSaveObjectStructure_createsHierarchy() {
        FormsHelper.RecordData parentAccount = recordData(
            'Account',
            1,
            new List<FormsHelper.FieldValue>{
                fieldValue('Name', 'FormsHelper Parent Account')
            },
            null
        );

        FormsHelper.RecordData primaryContact = recordData(
            'Contact',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('FirstName', 'Automation'),
                fieldValue('LastName', 'Primary')
            },
            new List<FormsHelper.ParentData>{
                parentLink('Account', 'Account|AccountId', 1, null)
            }
        );

        FormsHelper.RecordData childCase = recordData(
            'Case',
            1,
            new List<FormsHelper.FieldValue>{
                fieldValue('Subject', 'Generated Case', 1)
            },
            new List<FormsHelper.ParentData>{
                parentLink('Contact', 'Contact|ContactId', 0, null)
            }
        );

        Test.startTest();
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(
            buildPayload(
                primaryContact,
                new List<FormsHelper.RecordData>{ parentAccount },
                new List<FormsHelper.RecordData>{ childCase },
                new List<FormsHelper.RecordData>()
            )
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Save should succeed.');
        System.assertNotEquals(null, result.primaryRecordId, 'Primary record Id expected.');
        System.assert(result.recordIdsByObject.containsKey('Account'), 'Account Id should be tracked.');
        System.assert(result.recordIdsByObject.containsKey('Case'), 'Case Id should be tracked.');

        Contact insertedContact = [
            SELECT Id, AccountId, FirstName, LastName
            FROM Contact
            WHERE Id = :result.primaryRecordId
        ];
        System.assertEquals('Automation', insertedContact.FirstName);
        System.assertEquals('Primary', insertedContact.LastName);
        System.assertEquals(result.recordIdsByObject.get('Account'), insertedContact.AccountId);

        Case insertedCase = [
            SELECT Id, ContactId, Subject
            FROM Case
            WHERE ContactId = :insertedContact.Id
            LIMIT 1
        ];
        System.assertEquals('Generated Case', insertedCase.Subject);
    }

    @IsTest
    static void testSaveObjectStructure_acceptsIsoDateTime() {
        FormsHelper.RecordData eventRecord = recordData(
            'Event',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('Subject', 'ISO DateTime'),
                fieldValue('StartDateTime', '2025-11-06T08:30:00.000Z'),
                fieldValue('EndDateTime', '2025-11-06T09:30:00.000Z')
            },
            null
        );

        Test.startTest();
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(
            buildPayload(
                eventRecord,
                new List<FormsHelper.RecordData>(),
                new List<FormsHelper.RecordData>(),
                new List<FormsHelper.RecordData>()
            )
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Event save should succeed.');
        System.assertNotEquals(null, result.primaryRecordId, 'Primary event Id expected.');

        Event insertedEvent = [
            SELECT Id, StartDateTime, EndDateTime
            FROM Event
            WHERE Id = :result.primaryRecordId
        ];
        DateTime expectedStart = DateTime.valueOfGmt('2025-11-06 08:30:00');
        DateTime expectedEnd = DateTime.valueOfGmt('2025-11-06 09:30:00');
        System.assertEquals(expectedStart, insertedEvent.StartDateTime);
        System.assertEquals(expectedEnd, insertedEvent.EndDateTime);
    }

    @IsTest
    static void testParseTime_handlesLightningIsoFormat() {
        Time expected = Time.newInstance(8, 30, 0, 0);

        Time parsedWithZ = FormsHelper.parseTime('08:30:00.000Z');
        System.assertEquals(expected, parsedWithZ, 'Parser should handle trailing Z.');

        Time parsedWithOffset = FormsHelper.parseTime('08:30:00.000+05:30');
        System.assertEquals(expected, parsedWithOffset, 'Parser should ignore timezone offset for time values.');

        Time parsedWithoutSeconds = FormsHelper.parseTime('08:30');
        System.assertEquals(expected, parsedWithoutSeconds, 'Parser should pad missing seconds.');
    }

    @IsTest
    static void testSaveObjectStructure_defaultsBooleanFields() {
        FormsHelper.RecordData contactRecord = recordData(
            'Contact',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('LastName', 'Boolean Default'),
                fieldValue('HasOptedOutOfEmail', ''),
                fieldValue('DoNotCall', 'invalid')
            },
            null
        );

        Test.startTest();
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(
            buildPayload(
                contactRecord,
                new List<FormsHelper.RecordData>(),
                new List<FormsHelper.RecordData>(),
                new List<FormsHelper.RecordData>()
            )
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Contact save should succeed.');
        System.assertNotEquals(null, result.primaryRecordId, 'Primary contact Id expected.');

        Contact insertedContact = [
            SELECT Id, HasOptedOutOfEmail, DoNotCall
            FROM Contact
            WHERE Id = :result.primaryRecordId
        ];
        System.assertEquals(false, insertedContact.HasOptedOutOfEmail, 'Blank checkbox should use default value.');
        System.assertEquals(false, insertedContact.DoNotCall, 'Invalid checkbox input should use default value.');
    }

    @IsTest
    static void testSaveObjectStructure_updatesExisting() {
        Account existingAccount = [SELECT Id, Name FROM Account WHERE Name = 'Setup Account' LIMIT 1];
        Contact existingContact = [
            SELECT Id, AccountId, LastName
            FROM Contact
            WHERE Email = 'setup@example.com'
            LIMIT 1
        ];

        FormsHelper.RecordData parentAccount = recordData(
            'Account',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('Id', existingAccount.Id),
                fieldValue('Name', 'Updated Setup Account')
            },
            null
        );

        FormsHelper.RecordData primaryContact = recordData(
            'Contact',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('Id', existingContact.Id),
                fieldValue('LastName', 'Updated LastName')
            },
            new List<FormsHelper.ParentData>{
                parentLink('Account', 'Account|AccountId', null, existingAccount.Id)
            }
        );

        Test.startTest();
        FormsHelper.InsertResult result = FormsHelper.saveObjectStructure(
            buildPayload(
                primaryContact,
                new List<FormsHelper.RecordData>{ parentAccount },
                new List<FormsHelper.RecordData>(),
                new List<FormsHelper.RecordData>()
            )
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Update should succeed.');
        System.assertEquals(existingContact.Id, result.primaryRecordId, 'Existing contact Id should be returned.');

        Contact refreshedContact = [
            SELECT Id, LastName, AccountId
            FROM Contact
            WHERE Id = :existingContact.Id
        ];
        System.assertEquals('Updated LastName', refreshedContact.LastName);
        System.assertEquals(existingAccount.Id, refreshedContact.AccountId);
    }

    @IsTest
    static void testSaveObjectStructure_rejectsRestrictedFields() {
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User standardUser = new User(
            FirstName = 'Standard',
            LastName = 'User',
            Alias = 'stduser',
            Email = 'stduser@example.com',
            Username = 'stduser' + DateTime.now().getTime() + '@example.com',
            CommunityNickname = 'stduser' + DateTime.now().getTime(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert standardUser;

        String restrictedTimestamp = DateTime.now().formatGmt('yyyy-MM-dd HH:mm:ss');

        FormsHelper.RecordData primaryContact = recordData(
            'Contact',
            null,
            new List<FormsHelper.FieldValue>{
                fieldValue('LastName', 'Restricted'),
                fieldValue('CreatedDate', restrictedTimestamp)
            },
            null
        );

        FormsHelper.InsertResult runAsResult;
        Test.startTest();
        System.runAs(standardUser) {
            runAsResult = FormsHelper.saveObjectStructure(
                buildPayload(
                    primaryContact,
                    new List<FormsHelper.RecordData>(),
                    new List<FormsHelper.RecordData>(),
                    new List<FormsHelper.RecordData>()
                )
            );
        }
        Test.stopTest();
        System.assertEquals(
            false,
            runAsResult.isSuccess,
            'Operation should fail due to restricted field.'
        );
        System.assertNotEquals(
            null,
            runAsResult.errorMessage,
            'Error message should be returned.'
        );
    }

    @IsTest
    static void testAttachJSONForPDF() {
        Form__c form = fetchSetupForm();

        Test.startTest();
        FormsHelper.attachJSONForPDF('{"sample":"data"}', form.Id);
        Test.stopTest();

        List<ContentVersion> versions = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Title LIKE :('%' + form.Id + '%')
        ];
        System.assertEquals(1, versions.size(), 'A JSON attachment should be created.');
    }

    @IsTest
    static void testAttachPdfToRecord() {
        Form__c form = fetchSetupForm();
        Contact contact = fetchSetupContact();

        Test.startTest();
        FormsHelper.attachPdfToRecord(form.Id, contact.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contact.Id
        ];
        System.assertEquals(1, links.size(), 'PDF should be linked to the record.');
    }

    @IsTest
    static void testAttachPDF() {
        Contact contact = fetchSetupContact();

        Test.startTest();
        FormsHelper.attachPDF('{"payload":"value"}', contact.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contact.Id
        ];
        System.assertEquals(true, links.size() > 0, 'PDF content should be linked.');
    }

    @IsTest
    static void testAttachDocsToApplication() {
        Contact contact = fetchSetupContact();
        Account stagingAccount = new Account(Name = 'Staging Account');
        insert stagingAccount;

        ContentVersion cv = new ContentVersion(
            Title = 'Docs Attachment',
            PathOnClient = 'doc.txt',
            VersionData = Blob.valueOf('Sample'),
            FirstPublishLocationId = stagingAccount.Id
        );
        insert cv;

        Test.startTest();
        FormsHelper.attachDocsToApplication(contact.Id, stagingAccount.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contact.Id
        ];
        System.assertEquals(true, links.size() > 0, 'Document links should be copied.');
    }

    @IsTest
    static void testAttachPrintJsonToRecord() {
        Contact contact = fetchSetupContact();
        Form__c form = fetchSetupForm();

        Test.startTest();
        String response = FormsHelper.attachPrintJsonToRecord('{"print":"json"}', contact.Id, form.Id);
        Test.stopTest();

        System.assert(response.contains(form.Id), 'Response should include the form Id.');

        List<ContentVersion> versions = [
            SELECT Id, FirstPublishLocationId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :contact.Id
        ];
        System.assertEquals(1, versions.size(), 'Print JSON attachment should exist.');
    }

    @IsTest
    static void testGetFormsForPrimaryObject() {
        Test.startTest();
        List<FormsHelper.PicklistWrapper> wrappers =
            FormsHelper.getFormsForPrimaryObject('Contact', false);
        Test.stopTest();

        System.assertEquals(true, wrappers.size() > 0, 'Forms should be returned.');
        System.assertEquals(true, wrappers[0].label != null, 'Wrapper label should be populated.');
    }

    @IsTest
    static void testCreateDependentFormsTrackerRecord() {
        Form__c form = fetchSetupForm();

        Test.startTest();
        String trackerId = FormsHelper.createDependentFormsTrackerRecord(
            'parentJsId',
            form.Id,
            form.Id,
            true
        );
        Test.stopTest();

        System.assertNotEquals(null, trackerId, 'Tracker Id should be returned.');

        List<Dependent_Forms_Tracker__c> trackers = [
            SELECT Id, caresp__Required__c
            FROM Dependent_Forms_Tracker__c
            WHERE Id = :trackerId
        ];
        System.assertEquals(1, trackers.size(), 'Tracker record should be created.');
        System.assertEquals(true, trackers[0].caresp__Required__c);
    }

    @IsTest
    static void testDeleteDependentFormsTrackerRecord() {
        Form__c form = fetchSetupForm();
        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            caresp__Parent_Form_JS_Id__c = 'deleteJsId',
            caresp__Parent_Form_Id__c = form.Id,
            caresp__Dependent_Form_Id__c = form.Id,
            caresp__Required__c = true
        );
        insert tracker;

        Test.startTest();
        FormsHelper.deleteDependentFormsTrackerRecord('deleteJsId', form.Id, form.Id, true);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Dependent_Forms_Tracker__c WHERE Id = :tracker.Id],
            'Tracker record should be deleted.'
        );
    }

    @IsTest
    static void testGetTrackerRecordStatus() {
        Form__c form = fetchSetupForm();
        List<Dependent_Forms_Tracker__c> trackers = new List<Dependent_Forms_Tracker__c>{
            new Dependent_Forms_Tracker__c(
                caresp__Parent_Form_JS_Id__c = 'statusJs',
                caresp__Parent_Form_Id__c = form.Id,
                caresp__Dependent_Form_Id__c = form.Id,
                caresp__Completed__c = true
            ),
            new Dependent_Forms_Tracker__c(
                caresp__Parent_Form_JS_Id__c = 'statusJs',
                caresp__Parent_Form_Id__c = form.Id,
                caresp__Dependent_Form_Id__c = form.Id,
                caresp__Completed__c = false
            )
        };
        insert trackers;

        Test.startTest();
        List<caresp__Dependent_Forms_Tracker__c> results = FormsHelper.getTrackerRecordStatus('statusJs');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Only completed trackers should be returned.');
        System.assertEquals(true, results[0].Completed__c);
    }

    @IsTest
    static void testMoveJsonsAndDeleteTrackerRecords() {
        Contact contact = fetchSetupContact();
        Form__c form = fetchSetupForm();

        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            caresp__Parent_Form_JS_Id__c = 'moveJs',
            caresp__Parent_Form_Id__c = form.Id,
            caresp__Dependent_Form_Id__c = form.Id,
            caresp__Required__c = true
        );
        insert tracker;

        ContentVersion jsonVersion = new ContentVersion(
            Title = 'Tracker JSON',
            PathOnClient = 'tracker.json',
            VersionData = Blob.valueOf('{"key":"value"}'),
            FirstPublishLocationId = tracker.Id
        );
        insert jsonVersion;

        Test.startTest();
        String response = FormsHelper.moveJsonsAndDeleteTrackerRecords(
            contact.Id,
            new List<String>{ tracker.Id }
        );
        Test.stopTest();

        System.assertEquals('Done', response);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Dependent_Forms_Tracker__c WHERE Id = :tracker.Id],
            'Tracker should be deleted.'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :contact.Id],
            'Content should be linked to the primary record.'
        );
    }

    @isTest
    static void testMarkAdditionalFormComplete() {
        Form__c form = fetchSetupForm();
        Dependent_Forms_Tracker__c tracker = new Dependent_Forms_Tracker__c(
            caresp__Parent_Form_JS_Id__c = 'completeJs',
            caresp__Parent_Form_Id__c = form.Id,
            caresp__Dependent_Form_Id__c = form.Id,
            caresp__Required__c = true,
            caresp__Completed__c = false
        );
        insert tracker;

        Test.startTest();
        FormsHelper.markAdditionalFormComplete(tracker.Id);
        Test.stopTest();

        Dependent_Forms_Tracker__c updatedTracker = [
            SELECT caresp__Completed__c
            FROM Dependent_Forms_Tracker__c
            WHERE Id = :tracker.Id
        ];
        System.assertEquals(true, updatedTracker.caresp__Completed__c);
    }

    @isTest
    static void testWrapperInstantiation() {
        Test.startTest();
        FormsHelper.LwcResponse lwcResponse = new FormsHelper.LwcResponse();
        lwcResponse.isSuccess = true;
        lwcResponse.error = 'error';
        lwcResponse.url = 'http://example.com';

        FormsHelper.ClientEmailWrapper emailWrapper = new FormsHelper.ClientEmailWrapper();
        emailWrapper.label = 'Label';
        emailWrapper.value = 'Value';

        FormsHelper.PicklistWrapper picklistWrapper = new FormsHelper.PicklistWrapper();
        picklistWrapper.label = 'Picklist';
        picklistWrapper.value = 'Value';
        Test.stopTest();

        System.assertEquals(true, lwcResponse.isSuccess);
        System.assertEquals('Label', emailWrapper.label);
        System.assertEquals('Picklist', picklistWrapper.label);
    }
}