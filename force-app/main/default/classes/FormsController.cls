/*
###########################################################################
# File.................: FormsController
# Created by...........: Ankit Chowhan
# Created Date.........: 24th Feb, 2022
# Last Modified by.....: Ankit Chowhan
# Last Modified Date...: 13th July, 2022
# Description..........: This is controller class for Forms application
# Story No.............: UST-00023/UST-00036/UST-00073
# UI Comp..............: formsContainer/formsObjectStructureScreen/formsCreateFormScreen/formsObjectSelectionScreen
# Test Class…..........: TBD
# Change Log...........: 
#
#############################################################################
*/


  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : This method gets the list of all the objects in the Salesforce org except for ones with share/history/tag/feed extensions and ones that are restricted. Restricted objects functionality still needs to be implemented.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : none
      # Param2      : 
      # Return      : List<ObjectWrapper>
      # Change Log  : 
  */

  //Code moved to ObjectInformationUtil class
  /*  @AuraEnabled(cacheable = true)
  public static List < ObjectWrapper > getObjectsList() {
    List < ObjectWrapper > respList = new List < ObjectWrapper > ();
    String restrictedSObjectListString = System.Label.RestrictedObjectList;
    List< String > restrictedSObjectList = restrictedSObjectListString.split(',');
    System.debug('restrictedSObjectList - '+ restrictedSObjectList);
    if(!restrictedSObjectList.isEmpty()){
      Map < String, Schema.SObjectType > gd = Schema.getGlobalDescribe();
      for (Schema.SObjectType gdValue: gd.values()) {
        String objName = String.valueOf(gdValue.getDescribe().getName());
        if (!restrictedSObjectList.contains(objName) && !objName.containsignorecase('history') && !objName.containsignorecase('tag') && !objName.containsignorecase('share') && !objName.containsignorecase('feed') && !objName.containsignorecase('ChangeEvent') && gdValue.getDescribe().isCreateable() == true) {
          ObjectWrapper newObj = new ObjectWrapper();
          newObj.label = String.valueOf(gdValue.getDescribe().getLabel());
          System.debug('newObj.label >> '+newObj.label);
          newObj.value = String.valueOf(gdValue.getDescribe().getName());
          newObj.isCustom = gdValue.getDescribe().isCustom();
          newObj.relation = 'self';
          respList.add(newObj);
        }
      }
    }
    System.debug('respList >> '+respList);
    return respList;
  } */

  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : Once the primary or child object is selected on the object structure screen this method gets it's related objects both parents(lookup) and children.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : parentObjectName
      # Param2      : 
      # Return      : List<ObjectWrapperCategory>
      # Change Log  : 
  */
    public with sharing class FormsController {
    
      @AuraEnabled
      public static List<ObjectWrapperCategory> getRelatedObjectsList(
        String parentObjectName
      ) {
        List<ObjectWrapperCategory> respList = new List<ObjectWrapperCategory>();
    
        Map<string, string> objectRelationshipMap = new Map<string, string>();
    
        List<caresp__Forms_Setting__mdt> restrictedList = [select Id, caresp__Restricted_Object_List__c from caresp__Forms_Setting__mdt WITH USER_MODE limit 1];
    
        String restrictedSObjectListString = restrictedList[0].caresp__Restricted_Object_List__c;
        List<String> restrictedSObjectList = restrictedSObjectListString.split(',');
    
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    
        List<String> uniqueChildList;
        List<String> uniqueParentList;
    
        for (String ss1 : schemaMap.keyset()) {
          Schema.SObjectType objToken = schemaMap.get(ss1);
    
          if (ss1.equalsignorecase(parentObjectName)) {
            //find details about sobject
            Schema.DescribeSObjectResult objDescribe = objToken.getdescribe();
            List<Schema.ChildRelationship> childRelationshipList = objDescribe.getChildRelationships();
            uniqueChildList = new List<String>();
            uniqueParentList = new List<String>();
    
            ObjectWrapperCategory objWrapChildRec = new ObjectWrapperCategory();
            objWrapChildRec.categoryName = 'Children';
            List<ObjectWrapper> childObjList = new List<ObjectWrapper>();
    
            // Getting child objects
            for (Schema.ChildRelationship ss : childRelationshipList) {
              String parentLabelOnChild = ss.getField().getDescribe().getLabel();
              String parentApiOnChild = ss.getField().getDescribe().getName();
              Schema.SObjectType childObjectApi = ss.getChildSObject();
              String childObjectApiString = String.valueOf(ss.getChildSObject());
              String childObjectLabel = ss.getChildSObject()
                .getDescribe()
                .getLabel();
              if (!restrictedSObjectList.contains(childObjectLabel) && parentApiOnChild != 'WhoId' &&
                parentApiOnChild != 'LinkedEntityId' &&
                !childObjectApiString.containsignorecase('__share') &&
                !childObjectApiString.containsignorecase('__ChangeEvent') &&
                !childObjectApiString.containsignorecase('__feed') &&
                !childObjectApiString.containsignorecase('__history') &&
                !childObjectApiString.containsignorecase('__tag') &&
                childObjectApi.getDescribe().isCreateable() &&
                !childObjectApiString.equalsignorecase('User')
              ) {
                ObjectWrapper newObj = new ObjectWrapper();
                newObj.label = String.valueOf(
                  childObjectLabel +
                    '(' +
                    parentObjectName +
                    '-' +
                    parentLabelOnChild +
                    ')'
                );
                //as this same object can be used multiple times so for differentiation making unique name identifier by adding relationship fields to the object name
                newObj.value = String.valueOf(
                  childObjectApi + '|' + parentObjectName + '|' + parentApiOnChild
                );
                newObj.isCustom = childObjectApi.getDescribe().isCustom();
                newObj.relation = 'child';
                childObjList.add(newObj);
              }
            }
            objWrapChildRec.objectList = childObjList;
    
            if (objWrapChildRec != null) respList.add(objWrapChildRec);
    
            //Getting parent(lookup) objects
            ObjectWrapperCategory objWrapParentRec = new ObjectWrapperCategory();
            objWrapParentRec.categoryName = 'Lookup(Parent)';
            List<ObjectWrapper> parentObjList = new List<ObjectWrapper>();
    
            for (
              Schema.SobjectField strFld : objDescribe.fields.getMap().Values()
            ) {
              if (strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                String parentFieldLabel = strFld.getDescribe().getLabel();
                String parentFieldApi = strFld.getDescribe().getName();
                String objectLabel = strFld.getDescribe().getReferenceTo()[0]
                  .getDescribe()
                  .getLabel();
                String objectApiString = strFld.getDescribe().getReferenceTo()[0]
                  .getDescribe()
                  .getName();
                Schema.SObjectType objectApi = strFld.getDescribe()
                    .getReferenceTo()[0]
                  .getDescribe()
                  .getSObjectType();
                if (
                  !restrictedSObjectList.contains(objectLabel) &&
                  !objectApiString.containsignorecase('history') &&
                  !objectApiString.containsignorecase('tag') &&
                  !objectApiString.containsignorecase('share') &&
                  !objectApiString.containsignorecase('feed') &&
                  !objectApiString.containsignorecase('ChangeEvent') &&
                  !objectApiString.equalsignorecase('User')
                ) {
                  ObjectWrapper newObj = new ObjectWrapper();
                  newObj.label =
                    objectLabel +
                    '(' +
                    parentObjectName +
                    '-' +
                    parentFieldLabel +
                    ')';
                  //as this same object can be used multiple times so for differentiation making unique name identifier by adding relationship fields to the object name
                  newObj.value =
                    objectApiString +
                    '|' +
                    parentObjectName +
                    '|' +
                    parentFieldApi;
                  newObj.isCustom = objectApi.getDescribe().isCustom();
                  newObj.relation = 'parent';
                  parentObjList.add(newObj);
                }
              }
            }
    
            objWrapParentRec.objectList = parentObjList;
    
            if (objWrapParentRec != null)
              respList.add(objWrapParentRec);

              for(ObjectWrapperCategory resp:respList){
                System.debug('Object >>> '+resp);
              }
          }
        }
        system.debug(LoggingLevel.Error ,'respList ' + respList);
        return respList;
      }

  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : After object structure has been seleted by the user and he/she goes to the next screen, this method fetches all the fields for the selected objects.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : objectList
      # Param2      : 
      # Return      : List < FieldsWrapper >
      # Change Log  : 
  */
      @AuraEnabled
      public static List<FieldsWrapper> getFieldsData(
        List<String> objectList,
        Boolean prefillFields
      ) {
        List<FieldsWrapper> fieldsWrapperList = new List<FieldsWrapper>();
        System.debug(LoggingLevel.Error ,'objectList - ' + objectList);
    
        List<String> listOfRestrictedObjectLookup = new List<String>();
        for (String objectString : objectList) {
          String objectNameString = objectString.subStringBefore('#');
          if (objectNameString.countMatches('|') == 2) {
            String restrictedLookupField = objectNameString.substringAfterLast('|');
            Boolean isChild = Boolean.valueOf(
              objectString.subStringAfter('#').subStringBefore('#')
            );
            String isMulti = objectString.subStringAfter('#').subStringAfter('#');
            String objectName = '';
            if (!isChild) {
              objectName = objectNameString.substringBeforeLast('|').substringAfter('|');
            } else {
              objectName = objectNameString.substringBeforeLast('|')
                .substringBefore('|');
            }
            listOfRestrictedObjectLookup.add(
              objectName + '|' + restrictedLookupField + '#' + isMulti
            );
            System.System.debug(LoggingLevel.Error ,
              'listOfRestrictedObjectLookup - ' + listOfRestrictedObjectLookup
            );
          }
        }
    
        for (String objectString : objectList) {
          String objectName = objectString.subStringBefore('#');
          String type = objectName.subStringBefore('|');
          System.debug(LoggingLevel.Error ,'type - ' + type);
          Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
          Schema.SObjectType objSchema = schemaMap.get(type);
          Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe()
            .fields.getMap();
    
          FieldsWrapper fieldsWrpObj = new FieldsWrapper();
          fieldsWrpObj.objectName = objSchema.getDescribe().getName();
          fieldsWrpObj.objectLabel = objSchema.getDescribe().getLabel();
          fieldsWrpObj.objectUniqueName = objectName;
    
          //checking if the object selected is marked as 'multi'
          fieldsWrpObj.isChild = Boolean.valueOf(
            objectString.subStringAfter('#').subStringBefore('#')
          );
          fieldsWrpObj.isMulti = Boolean.valueOf(
            objectString.subStringAfter('#').subStringAfter('#')
          );
          String objApi = objSchema.getDescribe().getName();
          fieldsWrpObj.fields = new List<Fields>();
    
          for (String fieldName : fieldMap.keySet()) {
            //getting all the fields that are creatable by current user except for OwnerId field. May also implement restricted field list in this method in future.
            if (prefillFields) {
              if (
                fieldMap.get(fieldName).getDescribe().getName() != 'OwnerId' &&
                fieldMap.get(fieldName).getDescribe().getName() != 'CreatedById' &&
                fieldMap.get(fieldName).getDescribe().getName() != 'CreatedDate' &&
                fieldMap.get(fieldName).getDescribe().getName() !=
                'LastModifiedById' &&
                fieldMap.get(fieldName).getDescribe().getName() !=
                'LastModifiedDate' &&
                fieldMap.get(fieldName).getDescribe().getName() !=
                'SystemModstamp' &&
                fieldMap.get(fieldName).getDescribe().getName() != 'Id' &&
                !fieldMap.get(fieldName).getDescribe().isAutoNumber()
              ) {
                System.debug(LoggingLevel.Error ,'fieldName >>' + fieldName);
                System.debug(LoggingLevel.Error ,
                  'isAutoNumber >>' +
                  fieldMap.get(fieldName).getDescribe().isAutoNumber()
                );
                Boolean isLookupRestricted = false;
                if (!listOfRestrictedObjectLookup.isEmpty()) {
                  for (
                    String eachLookupObjectString : listOfRestrictedObjectLookup
                  ) {
                    if (
                      type.equals(eachLookupObjectString.substringBefore('|')) &&
                      fieldMap.get(fieldName)
                        .getDescribe()
                        .getName()
                        .equals(
                          eachLookupObjectString.substringAfter('|')
                            .substringBefore('#')
                        ) &&
                      Boolean.valueOf(eachLookupObjectString.substringAfter('#')) == fieldsWrpObj.isMulti
                    ) {
                      isLookupRestricted = true;
                    }
                  }
                }
                if (!isLookupRestricted) {
                  Fields fieldsObj = new Fields();
                  fieldsObj.fieldName = fieldMap.get(fieldName)
                    .getDescribe()
                    .getLabel();
                  fieldsObj.fieldApi = fieldMap.get(fieldName)
                    .getDescribe()
                    .getName();
                  fieldsObj.isFormulaField = fieldMap.get(fieldName)
                    .getDescribe()
                    .isCalculated();
                  fieldsObj.objectName = objectName;
                  //fieldsObj.fieldUniqueName = objLabel.replaceAll(' ','_')+'_'+(fieldsObj.fieldApi);
                  fieldsObj.fieldUniqueName = objApi + '::' + (fieldsObj.fieldApi);
                  fieldsObj.dataType = String.valueOf(
                    fieldMap.get(fieldName).getDescribe().getType()
                  );
                  if (fieldsObj.dataType != 'BOOLEAN') {
                    fieldsObj.required = !fieldMap.get(fieldName)
                      .getDescribe()
                      .isNillable();
                    fieldsObj.isNotNillable = !fieldMap.get(fieldName)
                      .getDescribe()
                      .isNillable();
                  } else {
                    fieldsObj.required = false;
                    fieldsObj.isNotNillable = false;
                  }
                  fieldsObj.isDependentPicklist = fieldMap.get(fieldName)
                    .getDescribe()
                    .isDependentPicklist();
                  if (fieldsObj.isDependentPicklist) {
                    fieldsObj.controllingField = fieldMap.get(fieldName).getDescribe().getController().getDescribe().getName();
                    fieldsObj.controllingFieldValue = '';
                  }
                  fieldsObj.customlabel = '';
                  /* System.debug('fieldName >> '+fieldsObj.fieldName);
                   System.debug('default value >> '+String.valueOf(fieldMap.get(fieldName).getDescribe().getDefaultValue())); */
                  fieldsObj.defaultValue = String.valueOf(
                    fieldMap.get(fieldName).getDescribe().getDefaultValue()
                  );
                  fieldsObj.isLabelEdit = false;
                  fieldsObj.isQuestion = false;
                  fieldsObj.inputValue = '';
                  fieldsObj.identifier = 'Record1'; //this identifier will help in identification of records in case 'multi' is seleted.
                  fieldsWrpObj.fields.add(fieldsObj);
                }
              }
            } else {
              System.debug(LoggingLevel.Error ,
                'prefill Fields >> ' +
                fieldMap.get(fieldName).getDescribe().isCreateable()
              );
              System.debug(LoggingLevel.Error ,
                'Field Name >> ' + fieldMap.get(fieldName).getDescribe().getName()
              );
              if (fieldMap.get(fieldName).getDescribe().isAccessible() && fieldMap.get(fieldName).getDescribe().isCreateable() && fieldMap.get(fieldName).getDescribe().getName() != 'OwnerId') {
                Boolean isLookupRestricted = false;
                if (!listOfRestrictedObjectLookup.isEmpty()) {
                  for (String eachLookupObjectString : listOfRestrictedObjectLookup) {
                    if (type.equals(eachLookupObjectString.substringBefore('|')) && fieldMap.get(fieldName).getDescribe().getName().equals(eachLookupObjectString.substringAfter('|').substringBefore('#')) &&Boolean.valueOf(eachLookupObjectString.substringAfter('#')) ==fieldsWrpObj.isMulti) {
                      isLookupRestricted = true;
                    }
                  }
                }
                if (!isLookupRestricted) {
                  Fields fieldsObj = new Fields();
                  fieldsObj.fieldName = fieldMap.get(fieldName).getDescribe().getLabel();
                  fieldsObj.fieldApi = fieldMap.get(fieldName).getDescribe().getName();
                  fieldsObj.objectName = objectName;
                  //fieldsObj.fieldUniqueName = objLabel.replaceAll(' ','_')+'_'+(fieldsObj.fieldApi);
                  fieldsObj.fieldUniqueName = objApi + '::' + (fieldsObj.fieldApi);
                  fieldsObj.dataType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());
                  if (fieldsObj.dataType != 'BOOLEAN') {
                    fieldsObj.required = !fieldMap.get(fieldName).getDescribe().isNillable();
                    fieldsObj.isNotNillable = !fieldMap.get(fieldName).getDescribe().isNillable();
                  } else {
                    fieldsObj.required = false;
                    fieldsObj.isNotNillable = false;
                  }
                  fieldsObj.isDependentPicklist = fieldMap.get(fieldName).getDescribe().isDependentPicklist();
                  if (fieldsObj.isDependentPicklist) {
                    fieldsObj.controllingField = fieldMap.get(fieldName).getDescribe().getController().getDescribe().getName();
                    fieldsObj.controllingFieldValue = '';
                  }
                  fieldsObj.customlabel = '';
                  /* System.debug('fieldName >> '+fieldsObj.fieldName);
                   System.debug('default value >> '+String.valueOf(fieldMap.get(fieldName).getDescribe().getDefaultValue())); */
                  fieldsObj.defaultValue = String.valueOf(
                    fieldMap.get(fieldName).getDescribe().getDefaultValue()
                  );
                  fieldsObj.isLabelEdit = false;
                  fieldsObj.isQuestion = false;
                  fieldsObj.inputValue = '';
                  fieldsObj.identifier = 'Record1'; //this identifier will help in identification of records in case 'multi' is seleted.
                  fieldsWrpObj.fields.add(fieldsObj);
                }
              }
            }
          }
          fieldsWrapperList.add(fieldsWrpObj);
        }

    //no matter what objects are selected, all the questions will always tag along in the field list.
    List<caresp__Question__c> quesList = [
      SELECT
        Id,
        Question_Text__c,
        Question_Data_type__c,
        (SELECT Id, Answer_Text__c FROM Answer_Options__r  ORDER BY Sequence__c)
      FROM Question__c WITH USER_MODE LIMIT 50000
    ];

    if (quesList != null && quesList.size() > 0) {
      FieldsWrapper quesWrpObj = new FieldsWrapper();
      quesWrpObj.objectName = 'Question';
      quesWrpObj.fields = new List<Fields>();
      for (caresp__Question__c ques : quesList) {
        Fields quesObj = new Fields();
        quesObj.fieldName = ques.caresp__Question_Text__c;
        quesObj.fieldApi = ques.Id;
        quesObj.objectName = 'Question';
        quesObj.fieldUniqueName = 'Question::' + ques.Id;
        if (ques.caresp__Question_Data_type__c == 'Radio Box') {
          quesObj.dataType = 'RADIOBOX';
        } else if (ques.caresp__Question_Data_type__c == 'Checkbox') {
          quesObj.dataType = 'CHECKBOX';
        } else if (ques.caresp__Question_Data_type__c == 'Text') {
          quesObj.dataType = 'STRING';
        } else if (ques.caresp__Question_Data_type__c == 'Number') {
          quesObj.dataType = 'INTEGER';
        } else if (ques.caresp__Question_Data_type__c == 'Picklist') {
          quesObj.dataType = 'PICKLIST';
        } else if (ques.caresp__Question_Data_type__c == 'Long Text Area') {
          quesObj.dataType = 'TEXTAREA';
        } else if (ques.caresp__Question_Data_type__c == 'Date') {
          quesObj.dataType = 'DATE';
        } else if (ques.caresp__Question_Data_type__c == 'Currency') {
          quesObj.dataType = 'CURRENCY';
        } else if (ques.caresp__Question_Data_type__c == 'Telephone') {
          quesObj.dataType = 'PHONE';
        }
        List<OptionsWrapper> options = new List<OptionsWrapper>();
        for (caresp__Question_Answer_Option__c qao : ques.caresp__Answer_Options__r) {
          OptionsWrapper op = new OptionsWrapper();
          op.label = qao.caresp__Answer_Text__c;
          op.value = qao.caresp__Answer_Text__c;
          options.add(op);
        }
        quesObj.quesAnsOptions = options;
        quesObj.required = false;
        quesObj.isNotNillable = false;
        quesObj.customlabel = '';
        quesObj.isLabelEdit = false;
        quesObj.isQuestion = true;
        quesObj.inputValue = '';
        quesObj.identifier = 'Record1';
        System.debug(LoggingLevel.Error ,'quesObj >> ' + quesObj);
        quesWrpObj.fields.add(quesObj);
      }
      fieldsWrapperList.add(quesWrpObj);
    }

    return fieldsWrapperList;
  }

  /*
      # Author      : Ankit Chowhan
      # Date        : 7th Oct, 2022
      # Description : This method gets all the record types for an object if available.
      # Story No    : 
      # Param1      : objectApiName
      # Param2      : 
      # Return      : wrapper of record type name and ids.
      # Change Log  : 
  */

  @AuraEnabled
  public static List<RecordTypeWrapper> getRecordTypes(String objectApiName) {
    System.debug(LoggingLevel.Error ,'objectApiName >> ' + objectApiName);
    List<RecordTypeWrapper> respList = new List<RecordTypeWrapper>();
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType obj = schemaMap.get(objectApiName);
    Schema.DescribeSObjectResult R = obj.getDescribe();
    List<Schema.RecordTypeInfo> rtList = R.getRecordTypeInfos();
    for (Schema.RecordTypeInfo rt : rtList) {
      if (!rt.isMaster()) {
        RecordTypeWrapper rtRec = new RecordTypeWrapper();
        rtRec.label = rt.getName();
        rtRec.value = rt.getRecordTypeId();
        respList.add(rtRec);
      }
    }
    System.debug('resp >> ' + respList);
    return respList;
  }

  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : This method creates the form record.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : formName
      # Param2      : 
      # Return      : String (id of created form)
      # Change Log  : 
  */
     @AuraEnabled
    public static String createFormRecord(String formName, Boolean isEdit, String recordId, String confirmationMessage, Boolean requiresSignature, Boolean requiresTextOnSignaturePage, String signaturePageText, Boolean requiresDocUpload, Boolean showSummary, Boolean generatePDF, Boolean prefillFields, String primaryObjectForPrefillForm, Boolean isPDFOnly) {
        System.debug(LoggingLevel.Error ,'isEdit >> ' + isEdit);
        System.debug(LoggingLevel.Error ,'recordId >> ' + recordId);
        System.debug(LoggingLevel.Error ,'requiresSignature >> ' + requiresSignature);
        System.debug(LoggingLevel.Error ,'requiresTextOnSignaturePage >> ' + requiresTextOnSignaturePage);
        System.debug(LoggingLevel.Error ,'signaturePageText >> ' + signaturePageText);
        System.debug(LoggingLevel.Error ,'generatePDF >> ' + generatePDF);
        System.debug(LoggingLevel.Error ,'requiresDocUpload >> ' + requiresDocUpload);
        System.debug(LoggingLevel.Error ,'showSummary >> ' + showSummary);
        System.debug(LoggingLevel.Error ,'isPDFOnly >> ' + isPDFOnly);
        
        // Create new Form__c record or update an existing one
        caresp__Form__c form = new caresp__Form__c();
        form.caresp__Form_Name__c = formName;
        form.caresp__Confirmation_Message__c = confirmationMessage;
        form.caresp__Requires_Signature__c = requiresSignature == null ? false : requiresSignature;
        form.caresp__Requires_Text_for_Signature_Page__c = requiresTextOnSignaturePage == null ? false : requiresTextOnSignaturePage;
        form.caresp__Signature_Page_Text__c = String.isNotBlank(signaturePageText) ? signaturePageText : '';
        form.caresp__Requires_Document_Upload__c = requiresDocUpload == null ? false : requiresDocUpload;
        form.caresp__Show_Summary__c = showSummary == null ? false : showSummary;
        form.caresp__Generate_PDF__c = generatePDF == null ? false : generatePDF;
        form.caresp__Prefill_Fields__c = prefillFields == null ? false : prefillFields;
        form.caresp__Create_PDF_Only__c = isPDFOnly == null ? false : isPDFOnly;
        form.caresp__Object_Name_for_Prefill_Fields__c = String.isNotBlank(primaryObjectForPrefillForm) ? primaryObjectForPrefillForm : '';
    
        // If in edit mode, assign the recordId
        if (isEdit == true) form.Id = recordId;
    
        System.debug(LoggingLevel.Error ,'form.Id >> ' + form.Id);
    
        try {
            // Upsert the record and capture the result list
            List<Database.UpsertResult> results = Database.upsert(Security.stripInaccessible(AccessType.UPSERTABLE, new List<caresp__Form__c>{form}).getRecords(), false, AccessLevel.USER_MODE);
    
            // Handle the result for a single record
            if (!results.isEmpty()) {
                Database.UpsertResult result = results[0];  // Get the first (and only) result
    
                // Check if the upsert was successful
                if (result.isSuccess()) {
                    System.debug(LoggingLevel.Error ,'Upsert successful. Form Id: ' + result.getId());
                    return result.getId();  // Return the Id of the upserted record
                } else {
                    // Handle failure
                    for (Database.Error err : result.getErrors()) {
                        System.debug(LoggingLevel.Error ,'Error during upsert: ' + err.getMessage());
                        throw new AuraHandledException('Upsert failed: ' + err.getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.Error ,'Exception - ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    
        return null;  // In case of failure, return null
    }

  /*
        # Author      : Ankit Chowhan
        # Date        : 24th Feb, 2022
        # Description : This method saves the JSON files created for object structure, page data(form) and rules in the form of salesforce files with form record as parent.
        # Story No    : UST-00023/UST-00036/UST-00073
        # Param1      : recordId
        # Param2      : objectStructureJson
        # Param3      : pageDataJson
        # Param4      : rulesJson
        # Return      : String ('done')
        # Change Log  : Modified By Abhiraj (2nd Sept, 2022) - isEditFunctionality
    */
    @AuraEnabled
    public static String saveFormData(String recordId, String objectStructureJson, String pageDataJson, String rulesJson, Boolean isEdit) {
        // public static String saveFormData(String recordId, String objectStructureJson, String pageDataJson, String rulesJson, Boolean isEdit, String pageData) {
        // public static String saveFormData(String recordId, String objectStructureJson, String pageDataJson, String rulesJson) { //without Edit
        System.debug(LoggingLevel.Error ,'recordId >> ' + recordId);
        System.debug(LoggingLevel.Error ,'objectStructureJson >> ' + objectStructureJson);
        System.debug(LoggingLevel.Error ,'pageDataJson >> ' + pageDataJson);
        System.debug(LoggingLevel.Error ,'rulesJson >> ' + rulesJson);
        System.debug(LoggingLevel.Error ,'isEdit >> ' + isEdit);

        if (isEdit) {
            List < ContentDocumentLink > cdlList = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId WITH USER_MODE];
            Set < Id > cdConDocIdSet = new Set < Id > ();
            List < ContentDocument > cdConDocIdListToDelete = new List < ContentDocument > ();
            if (cdlList != null && !cdlList.isEmpty()) {
                for (ContentDocumentLink eachDocLink: cdlList) {
                    cdConDocIdSet.add(eachDocLink.ContentDocumentId);
                }
            }

            if (cdConDocIdSet != null && !cdConDocIdSet.isEmpty()) {
                cdConDocIdListToDelete = [SELECT Id FROM ContentDocument WHERE Id IN: cdConDocIdSet WITH USER_MODE];
                if (cdConDocIdListToDelete != null && !cdConDocIdListToDelete.isEmpty() && ContentDocument.sObjectType.getDescribe().isDeletable()) {
                    try {
                        delete as user cdConDocIdListToDelete;
                    } catch (Exception ex) {
                        System.debug(LoggingLevel.Error ,'Exception - ' + ex.getMessage());
                        throw new AuraHandledException(ex.getMessage());
                    }
                }
            }
        }

        List < ContentVersion > cvList = new List < ContentVersion > ();
        List < ContentDocumentLink > cdlList = new List < ContentDocumentLink > ();
        List < ContentVersion > conVerList = new List < ContentVersion > ();
        Set < String > cvIdSet = new Set < String > ();

        //Create Document
        if (String.isNotBlank(objectStructureJson)) {
            ContentVersion cvOBJ = new ContentVersion();
            cvOBJ.VersionData = Blob.valueOf(objectStructureJson);
            cvOBJ.Title = 'Object Structure';
            cvOBJ.PathOnClient = 'Object_Structure.txt';
            cvList.add(cvOBJ);
        }

        if (String.isNotBlank(pageDataJson)) {
            ContentVersion cvPDJ = new ContentVersion();
            cvPDJ.VersionData = Blob.valueOf(pageDataJson);
            cvPDJ.Title = 'Page Data';
            cvPDJ.PathOnClient = 'Page_Data.txt';
            cvList.add(cvPDJ);
        }

        if (String.isNotBlank(rulesJson)) {
            ContentVersion cvRJ = new ContentVersion();
            cvRJ.VersionData = Blob.valueOf(rulesJson);
            cvRJ.Title = 'Rules';
            cvRJ.PathOnClient = 'Rules.txt';
            cvList.add(cvRJ);
        }

        if (cvList != null && !cvList.isEmpty() && Schema.sObjectType.ContentVersion.isCreateable()) {
            try {
                insert as user cvList;
            } catch (Exception ex) {
                System.debug(LoggingLevel.Error ,'Exception - ' + ex.getMessage());
                throw new AuraHandledException(ex.getMessage());
            }

            for (ContentVersion cv: cvList) {
                cvIdSet.add(cv.Id);
            }
        }

        if (cvIdSet != null && !cvIdSet.isEmpty()) {
            conVerList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id In: cvIdSet WITH USER_MODE];
        }

        if (conVerList != null && !conVerList.isEmpty()) {
            for (ContentVersion cv: conVerList) {
                //Create ContentDocumentLink 
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = recordId;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.shareType = 'V';
                cdl.visibility = 'AllUsers';
                cdlList.add(cdl);
            }
        }

        if (cdlList != null && !cdlList.isEmpty() && Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            try {
                insert as user cdlList;
            } catch (Exception ex) {
                System.debug(LoggingLevel.Error ,'Exception - ' + ex.getMessage());
                throw new AuraHandledException(ex.getMessage());
            }
        }

        return 'done';
    }



  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : This method fetches the JSON files created for object structure, page data(form) and rules in the form of salesforce files with form record as parent.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : formId
      # Param2      : 
      # Return      : FormDataWrapper
      # Change Log  : 
  */
      @AuraEnabled(cacheable=true)
      public static FormDataWrapper fetchFormData(String formId) {
        System.debug(LoggingLevel.Error ,'formId >> ' + formId);
        List<String> cDocList = new List<String>();
        FormDataWrapper formDataWrap = new FormDataWrapper();
        List<caresp__Form__c> formList = [
          SELECT
            Id,
            Form_Name__c,
            Confirmation_Message__c,
            Requires_Signature__c,
            Requires_Text_for_Signature_Page__c,
            Signature_Page_Text__c,
            Generate_PDF__c,
            Requires_Document_Upload__c,
            Show_Summary__c,
            Prefill_Fields__c,
            Create_PDF_Only__c
          FROM Form__c 
          WHERE Id = :formId WITH USER_MODE
        ];
        System.debug(LoggingLevel.Error ,'Create_PDF_Only__c >> ' + formList[0].caresp__Create_PDF_Only__c);
        formDataWrap.formName = formList[0].caresp__Form_Name__c;
        formDataWrap.confirmationMessage = String.isNotBlank(
            formList[0].caresp__Confirmation_Message__c
          )
          ? formList[0].caresp__Confirmation_Message__c: null;
        formDataWrap.requiresDocUpload = formList[0].caresp__Requires_Document_Upload__c;
        formDataWrap.generatePDF = formList[0].caresp__Generate_PDF__c;
        formDataWrap.requiresSignature = formList[0].caresp__Requires_Signature__c;
        formDataWrap.requiresTextOnSignaturePage = formList[0]
          .caresp__Requires_Text_for_Signature_Page__c;
        formDataWrap.signaturePageText = formList[0].caresp__Signature_Page_Text__c;
        formDataWrap.hasSummary = formList[0].caresp__Show_Summary__c;
        formDataWrap.prefillFields = formList[0].caresp__Prefill_Fields__c;
        formDataWrap.pdfOnly = formList[0].caresp__Create_PDF_Only__c;
        List<ContentDocumentLink> cDocLinkList = [
          SELECT Id, ContentDocumentId
          FROM ContentDocumentLink
          WHERE LinkedEntityId = :formId WITH USER_MODE
        ];
    
        if (cDocLinkList != null && cDocLinkList.size() > 0) {
          for (ContentDocumentLink cDoc : cDocLinkList) {
            cDocList.add(cDoc.ContentDocumentId);
          }
        }
    
        if (cDocList != null && cDocList.size() > 0) {
          List<ContentVersion> cVersionList = [SELECT Id, Title, IsLatest, VersionData FROM ContentVersion WHERE ContentDocumentId IN :cDocList AND IsLatest = TRUE WITH USER_MODE];
    
          for (ContentVersion cVersion : cVersionList) {
            if (cVersion.Title == 'Object Structure') {
              formDataWrap.objectStructure = String.valueOf(cVersion.VersionData.toString());
            } else if (cVersion.Title == 'Page Data') {
              formDataWrap.pageData = String.valueOf( cVersion.VersionData.toString());
            } else if (cVersion.Title == 'Rules') {
              formDataWrap.rules = String.valueOf(cVersion.VersionData.toString());
            }
          }
        }
    
        System.debug(LoggingLevel.Error ,'obj st >> ' + formDataWrap.objectStructure);
        System.debug(LoggingLevel.Error ,'page dt >> ' + formDataWrap.pageData);
        System.debug(LoggingLevel.Error ,'rules >> ' + formDataWrap.rules);
    
        return formDataWrap;
      }

  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : This method fetches the Question Answer Options of the question records.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : quesId
      # Param2      : 
      # Return      : List < Question_Answer_Option__c >
      # Change Log  : 
  */
  @AuraEnabled
  public static List<Question_Answer_Option__c> getQuestionAnswerOptions(
    String quesId
  ) {
    return [
      SELECT Id, Answer_Text__c
      FROM Question_Answer_Option__c 
      WHERE Question__c = :quesId WITH USER_MODE
      ORDER BY Sequence__c
    ];
  }

  /*  @AuraEnabled
  public static List<String> getHouseholdMembersFromStaging(String pendingApplicationId){
    try {
      List<String> pendingClients = new List<String>();
      //pendingClients[0] = '';
      if(String.isNotBlank(pendingApplicationId)){
        List<Household_Member_Staging__c> pendingClientList = [select Id, Relation__c from Household_Member_Staging__c where Application_Staging__c =: pendingApplicationId];

        if(pendingClientList!=null && pendingClientList.size()>0){
          for(Household_Member_Staging__c client:pendingClientList){
            if(client.Relation__c == 'Self'){
              if(pendingClients.size()>0){
                pendingClients.add(0, client.Id);
              }else{
                pendingClients.add(client.Id);  
              }
            }else{
              pendingClients.add(client.Id);
            }
            //pendingClients.add(client.Id);
          }
        }
      }
      return pendingClients;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /*  @AuraEnabled
  public static List<String> getUtilityRecordsFromStaging(String pendingApplicationId){
    try {
      List<String> pendingUtilities = new List<String>();
      System.debug(' >> '+pendingApplicationId);
      List<Utility_Staging__c> pendingUtilityList = [select Id from Utility_Staging__c where Application__c =: pendingApplicationId];

      if(pendingUtilityList!=null && pendingUtilityList.size()>0){
        for(Utility_Staging__c utility:pendingUtilityList){
          pendingUtilities.add(utility.Id);
        }
      }
      return pendingUtilities;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /*  @AuraEnabled
  public static List<String> getIncomeRecordsFromStaging(String pendingApplicationId){
    try {
      List<String> pendingIncomes = new List<String>();
      System.debug(' >> '+pendingApplicationId);
      if(String.isNotBlank(pendingApplicationId)){
        List<Pending_Income__c> pendingIncomeList = [select Id from Pending_Income__c where Pending_Application__c =: pendingApplicationId];

        if(pendingIncomeList!=null && pendingIncomeList.size()>0){
          for(Pending_Income__c income:pendingIncomeList){
            pendingIncomes.add(income.Id);
          }
        }
      }
      return pendingIncomes;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /*  @AuraEnabled
  public static List<String> getHouseholdMembersFromApplication(String applicationId){
    try {
      System.debug('applicationId >> '+applicationId);
      List<String> clientList = new List<String>();
      //pendingClients[0] = '';
      if(String.isNotBlank(applicationId)){
        List<Client_Referral__c> clientReferralList = [select Id, Relation__c from Client_Referral__c where Referral__c =: applicationId];

        if(clientReferralList!=null && clientReferralList.size()>0){
          for(Client_Referral__c client:clientReferralList){
            if(client.Relation__c == 'Self'){
              if(clientList.size()>0){
                clientList.add(0, client.Id);
              }else{
                clientList.add(client.Id);  
              }
            }else{
              clientList.add(client.Id);
            }
            //pendingClients.add(client.Id);
          }
        }
      }
      return clientList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /*  @AuraEnabled
  public static List<String> getUtilityRecordsFromApplication(String applicationId){
    try {
      System.debug('applicationId >> '+applicationId);
      List<String> utilityList = new List<String>();
      //pendingClients[0] = '';
      if(String.isNotBlank(applicationId)){
        List<Utility__c> utilityRecs = [select Id from Utility__c where Application__c =: applicationId];

        if(utilityRecs!=null && utilityRecs.size()>0){
          for(Utility__c util:utilityRecs){
            utilityList.add(util.Id);
          }
        }
      }
      return utilityList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /*  @AuraEnabled
  public static List<String> getIncomeRecordsFromApplication(String applicationId){
    try {
      System.debug('applicationId >> '+applicationId);
      List<String> incomeList = new List<String>();
      //pendingClients[0] = '';
      if(String.isNotBlank(applicationId)){
        List<Income__c> incomeRecs = [select Id from Income__c where Application_ID__c =: applicationId AND RecordType.Name = 'Application Income'];

        if(incomeRecs!=null && incomeRecs.size()>0){
          for(Income__c income:incomeRecs){
            incomeList.add(income.Id);
          }
        }
      }
      return incomeList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }*/

  /* @AuraEnabled
  public static Client__c getClientData(String clientId) {
    return [
      SELECT Id, First_Name__c, Last_Name__c, Date_of_Birth__c, SSN__c
      FROM client__c
      WHERE Id = :clientId
    ];
  } */

  @AuraEnabled(cacheable=true)
  public static List<Doc_Category_Help_Text__mdt> getDocumentTypes() {
    return [
      SELECT Id, label, DeveloperName, Help_Text_Value__c
      FROM Doc_Category_Help_Text__mdt WITH USER_MODE
      LIMIT 100
    ];
  }

  /* @AuraEnabled(cacheable=true)
  public static List<SP_Service__c> getServiceData() {
    return [SELECT Id, Name FROM SP_Service__c WITH USER_MODE LIMIT 100];
  } */

 // Retrieves print JSON data and related signature details for a given record
@AuraEnabled
public static PrintWrapper getPrintJson(
    String recordId,
    String printJsonTitle
) {
    System.debug(LoggingLevel.Error ,'printJsonTitle >> ' + printJsonTitle);
    List<String> cDocList = new List<String>();
    PrintWrapper resp = new PrintWrapper();
    List<String> splitPrintJsonTitle = new List<String>();
    splitPrintJsonTitle = printJsonTitle.split('__');
    System.debug(LoggingLevel.Error ,'splitPrintJsonTitle -- ' + splitPrintJsonTitle[0]);
    String formId = splitPrintJsonTitle[0].split('_')[0];

    Form__c formRec = [
        SELECT Id, Signature_Page_Text__c
        FROM Form__c 
        WHERE Id = :formId WITH USER_MODE
    ];

    List<ContentDocumentLink> cDocLinkList = [
        SELECT Id, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :recordId WITH USER_MODE
    ];

    if (cDocLinkList != null && cDocLinkList.size() > 0) {
        for (ContentDocumentLink cDoc : cDocLinkList) {
            cDocList.add(cDoc.ContentDocumentId);
        }
    }

    if (cDocList != null && cDocList.size() > 0) {
        List<ContentVersion> cVersionList = [
            SELECT Id, Title, IsLatest, VersionData
            FROM ContentVersion 
            WHERE ContentDocumentId IN :cDocList AND IsLatest = TRUE WITH USER_MODE
        ];
        if (cVersionList != null && cVersionList.size() > 0) {
            for (ContentVersion cv : cVersionList) {
                if (cv.Title == printJsonTitle) {
                    resp.pageData = String.valueOf(cv.VersionData.toString());
                } else if (cv.Title.startsWithIgnoreCase(splitPrintJsonTitle[0])) {
                    resp.signature = cv.Id;
                }
            }
            if (
                formRec != null && String.isNotBlank(formRec.caresp__Signature_Page_Text__c)
            ) {
                resp.signatureText = formRec.caresp__Signature_Page_Text__c;
            }
        }
    }

    return resp;
}

// Retrieves the list of forms available for printing for a given record
@AuraEnabled
public static List<FormOptionsWrapper> getFormsAvailableForPrint(String recordId) {
    List<String> cDocList = new List<String>();
    List<FormOptionsWrapper> resp = new List<FormOptionsWrapper>();
    List<String> formIdList = new List<String>();
    List<String> formIdDateTimeList = new List<String>();
    Map<String, String> formIdNameMap = new Map<String, String>();

    // Fetch ContentDocumentLinks and gather ContentDocumentIds
    for (ContentDocumentLink cDoc : [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :recordId
        WITH USER_MODE
    ]) {
        cDocList.add(cDoc.ContentDocumentId);
    }

    if (!cDocList.isEmpty()) {
        // Fetch latest ContentVersion records
        for (ContentVersion cv : [
            SELECT Title
            FROM ContentVersion
            WHERE ContentDocumentId IN :cDocList AND IsLatest = TRUE
            WITH USER_MODE
        ]) {
            if (Schema.sObjectType.ContentVersion.fields.Title.isAccessible() && cv.Title != null && cv.Title.contains('Print_JSON')) {
                String[] breakName = cv.Title.split('_');
                if (breakName.size() >= 2) {
                    formIdList.add(breakName[0]);
                    formIdDateTimeList.add(breakName[0] + ' ' + breakName[1]);
                }
            }
        }
    }

    if (!formIdList.isEmpty()) {
        // Fetch form records and populate formIdNameMap
        for (caresp__Form__c formRec : [
            SELECT Id, careSP__Form_Name__c
            FROM careSP__Form__c
            WHERE Id IN :formIdList
            WITH USER_MODE
        ]) {
            formIdNameMap.put(formRec.Id, formRec.careSP__Form_Name__c);
        }

        // Construct FormOptionsWrapper list
        for (String formDateTimeStr : formIdDateTimeList) {
            String formId = formDateTimeStr.split(' ')[0];
            if (formIdNameMap.containsKey(formId)) {
                resp.add(createWrapper(formDateTimeStr, formId, formIdNameMap));
            }
        }
    }

    resp.sort();
    return resp;
}

// Creates a FormOptionsWrapper instance with label, value, and datetime based on form metadata
private static FormOptionsWrapper createWrapper(String formDateTimeStr, String formId, Map<String, String> formIdNameMap) {
    FormOptionsWrapper a = new FormOptionsWrapper();
    a.label = formDateTimeStr.replace(formId, formIdNameMap.get(formId));
    a.value = formDateTimeStr.replaceFirst(' ', '_') + '__Print_JSON';
    a.dateTimeVal = DateTime.parse(formDateTimeStr.replaceFirst(' ', '_').split('_')[1].replaceFirst(' ', ', '));
    return a;
}

// Retrieves a list of forms with their Id and Name (limited to 200 records)
@AuraEnabled(cacheable=true)
public static List<caresp__Form__c> getFormsList() {
    return [SELECT Id, Form_Name__c FROM Form__c WITH USER_MODE LIMIT 200];
}



  /*
      # Author      : Ankit Chowhan
      # Date        : 24th Feb, 2022
      # Description : Below are all the data wrappers for the LWC components.
      # Story No    : UST-00023/UST-00036/UST-00073
      # Param1      : 
      # Param2      : 
      # Return      : 
      # Change Log  : 
  */
  public class FormDataWrapper {
    @AuraEnabled
    public string formName { get; set; }
    @AuraEnabled
    public string confirmationMessage { get; set; }
    @AuraEnabled
    public Boolean requiresSignature { get; set; }
    @AuraEnabled
    public Boolean requiresTextOnSignaturePage { get; set; }
    @AuraEnabled
    public String signaturePageText { get; set; }
    @AuraEnabled
    public Boolean hasSummary { get; set; }
    @AuraEnabled
    public Boolean generatePDF { get; set; }
    @AuraEnabled
    public Boolean requiresDocUpload { get; set; }
    @AuraEnabled
    public Boolean prefillFields { get; set; }
    @AuraEnabled
    public Boolean pdfOnly { get; set; }
    @AuraEnabled
    public string objectStructure { get; set; }
    @AuraEnabled
    public string pageData { get; set; }
    @AuraEnabled
    public string rules { get; set; }
  }

  public class FieldsWrapper {
    @AuraEnabled
    public String objectName { get; set; }

    @AuraEnabled
    public String objectLabel { get; set; }

    @AuraEnabled
    public String objectUniqueName { get; set; }
    @AuraEnabled
    public Boolean isChild { get; set; }
    @AuraEnabled
    public Boolean isMulti { get; set; }
    @AuraEnabled
    public List<Fields> fields { get; set; }
  }

  public class FormOptionsWrapper implements Comparable {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }

    @AuraEnabled
    public DateTime dateTimeVal { get; set; }

    public Integer compareTo(Object instance) {
      FormOptionsWrapper that = (FormOptionsWrapper) instance;
      if (this.dateTimeVal > that.dateTimeVal)
        return -1;
      if (this.dateTimeVal < that.dateTimeVal)
        return 1;
      return 0;
    }
  }

  public class OptionsWrapper {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
  }

  public class RecordTypeWrapper {
    @AuraEnabled
    public String label { get; set; }

    @AuraEnabled
    public String value { get; set; }
  }

  public class Fields {
    @AuraEnabled
    public string fieldName { get; set; }
    @AuraEnabled
    public string fieldApi { get; set; }
    @AuraEnabled
    public string objectName { get; set; }
    @AuraEnabled
    public string fieldUniqueName { get; set; }
    @AuraEnabled
    public string dataType { get; set; }
    @AuraEnabled
    public Boolean required { get; set; }
    @AuraEnabled
    public Boolean isNotNillable { get; set; }
    @AuraEnabled
    public string customlabel { get; set; }
    @AuraEnabled
    public Boolean isLabelEdit { get; set; }
    @AuraEnabled
    public Boolean isQuestion { get; set; }
    @AuraEnabled
    public List<OptionsWrapper> quesAnsOptions { get; set; }
    @AuraEnabled
    public String inputValue { get; set; }
    @AuraEnabled
    public String identifier { get; set; }

    @AuraEnabled
    public Boolean isDependentPicklist { get; set; }

    @AuraEnabled
    public String defaultValue { get; set; }

    @AuraEnabled
    public String controllingField { get; set; }

    @AuraEnabled
    public String controllingFieldValue { get; set; }

    @AuraEnabled
    public Boolean isFormulaField { get; set; }
  }

  public class ObjectWrapperCategory {
    @AuraEnabled
    public String categoryName { get; set; }
    @AuraEnabled
    public List<ObjectWrapper> objectList { get; set; }
  }

  public class ObjectWrapper {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
    @AuraEnabled
    public Boolean isCustom { get; set; }
    @AuraEnabled
    public String relation { get; set; }
  }

  public class PrintWrapper {
    @AuraEnabled
    public String pageData { get; set; }
    @AuraEnabled
    public String signature { get; set; }
    @AuraEnabled
    public String signatureText { get; set; }
  }
}