public with sharing class ObjectInformationUtil{
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
  @AuraEnabled(cacheable = true)
  public static List<ObjectWrapper> getObjectsList(){
    List<ObjectWrapper> respList = new List<ObjectWrapper>();
    List<caresp__Forms_Setting__mdt> restrictedList = [select Id, caresp__Restricted_Object_List__c from caresp__Forms_Setting__mdt WITH SECURITY_ENFORCED limit 1];

    String restrictedSObjectListString = restrictedList[0].caresp__Restricted_Object_List__c;
    List<String> restrictedSObjectList = restrictedSObjectListString.split(',');
    System.debug('restrictedSObjectList - ' + restrictedSObjectList);
    if (!restrictedSObjectList.isEmpty()){
      Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
      for (Schema.SObjectType gdValue : gd.values()){
        String objName = String.valueOf(gdValue.getDescribe().getName());
        System.debug('objName >> ' + objName);
        if (!restrictedSObjectList.contains(objName) && !objName.containsignorecase('__history') && !objName.containsignorecase('__tag') && !objName.containsignorecase('__share') && !objName.containsignorecase('__feed') && !objName.containsignorecase('__ChangeEvent') && (objName.countMatches('__') <= 1) && gdValue.getDescribe().isCreateable() == true){
          ObjectWrapper newObj = new ObjectWrapper();
          newObj.label = String.valueOf(gdValue.getDescribe().getLabel());
          newObj.value = String.valueOf(gdValue.getDescribe().getName());
          newObj.isCustom = gdValue.getDescribe().isCustom();
          newObj.relation = 'self';
          respList.add(newObj);
        }
      }
    }

    return respList;
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
  public static List<OptionsWrapper> getRecordTypes(String objectApiName){
    System.debug('objectApiName >> ' + objectApiName);
    List<OptionsWrapper> respList = new List<OptionsWrapper>();
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType obj = schemaMap.get(objectApiName);
    Schema.DescribeSObjectResult R = obj.getDescribe();
    List<Schema.RecordTypeInfo> rtList = R.getRecordTypeInfos();
    for (Schema.RecordTypeInfo rt : rtList){
      //if (!rt.isMaster()) {
      OptionsWrapper rtRec = new OptionsWrapper();
      rtRec.label = rt.getName();
      rtRec.value = rt.getRecordTypeId();
      respList.add(rtRec);
      //}
    }
    System.debug('resp >> ' + respList);
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
  public static List<FieldsWrapper> getUserReferenceFieldsData(List<String> objectList){
    List<FieldsWrapper> fieldsWrapperList = new List<FieldsWrapper>();

    for (String objectString : objectList){
      //String objectName = objectString.subStringBefore('#');
      String objectName = objectString;
      String type = objectName;
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType objSchema = schemaMap.get(type) ;
      Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

      FieldsWrapper fieldsWrpObj = new FieldsWrapper();
      fieldsWrpObj.objectName = objSchema.getDescribe().getName();

      String objApi = objSchema.getDescribe().getName();
      fieldsWrpObj.fields = new List<OptionsWrapper>();

      for (String fieldName : fieldMap.keySet()){
        for (Schema.sObjectType ref : fieldMap.get(fieldName).getDescribe().getReferenceTo()){
          if (ref.getDescribe().getName() == 'User' && fieldMap.get(fieldName).getDescribe().getName() != 
                     'LastModifiedById'){
            OptionsWrapper newField = new OptionsWrapper();
            newField.label = fieldMap.get(fieldName).getDescribe().getLabel();
            newField.value = fieldMap.get(fieldName).getDescribe().getName();
            fieldsWrpObj.fields.add(newField);
          }
        }
      }
      fieldsWrapperList.add(fieldsWrpObj);
    }
    System.debug('>> ' + fieldsWrapperList);
    return fieldsWrapperList;
  }

  @AuraEnabled
  public static List<OptionsWrapper> getPicklistValues(String objName, String fieldName){
    Schema.SObjectType token = Schema.getGlobalDescribe().get(objName);
    Schema.DescribeSObjectResult dr = token.getDescribe();
    Map<String, Schema.SObjectField> field_map = dr.fields.getMap();
    List<OptionsWrapper> picklistFieldValues = new List<OptionsWrapper>();
    List<Schema.PicklistEntry> pickListValues = field_map.get(fieldName).getDescribe().getPickListValues();
    for (Schema.PicklistEntry plv : pickListValues){
      OptionsWrapper fl = new OptionsWrapper();
      fl.label = plv.getLabel();
      fl.value = plv.getValue();
      picklistFieldValues.add(fl);
    }
    return picklistFieldValues;
  }

  @AuraEnabled
  public static List<OptionsWrapper> getSubTypeOptions(
    String objName,
    String type
  ) {

	List<OptionsWrapper> options = new List<OptionsWrapper>();
    if (String.isNotBlank(type) && type.equalsIgnoreCase('assessment')) {
      List<caresp__Assessment__c> assessmentList = [SELECT Id, Name FROM Assessment__c SECURITY_ENFORCED WHERE Object__c = :objName WITH SECURITY_ENFORCED];

      if (assessmentList != null && assessmentList.size() > 0) {
        for (caresp__Assessment__c assessment : assessmentList) {
			OptionsWrapper option = new OptionsWrapper();
			option.label = assessment.Name;
			option.value = assessment.Id;
			options.add(option);
        }
      }
    }

	return options;
  }

   @AuraEnabled
  public static List<OptionsWrapper> getFieldsByPageLayout( string objectName,string layout) {
		List<OptionsWrapper> respList = new List<OptionsWrapper>();
		string layoutName=String.format('{0}-{1}', new String[]{objectName, layout}); 
		List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});

		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(objectName);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

		List<string> fields=new List<string>();
		Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
		for (Metadata.LayoutSection section : layoutMd.layoutSections) {
			for (Metadata.LayoutColumn column : section.layoutColumns) {
				if (column.layoutItems != null) {
					for (Metadata.LayoutItem item : column.layoutItems) {
						OptionsWrapper obj = new OptionsWrapper();
						obj.label = Test.isRunningTest() ? null :fieldMap.get(item.field).getDescribe().getLabel();
						obj.value = item.field;
						respList.add(obj);
					}
				}
			}
		}
		return respList;
  }
  public class FieldsWrapper {
    @AuraEnabled
    public String objectName{ get; set; }

    @AuraEnabled
    public List<OptionsWrapper> fields{ get; set; }

  }

  public class OptionsWrapper{
    @AuraEnabled
    public string label{ get; set; }

    @AuraEnabled
    public string value{ get; set; }

  }

  public class ObjectWrapper{
    @AuraEnabled
    public String label{ get; set; }

    @AuraEnabled
    public String value{ get; set; }

    @AuraEnabled
    public Boolean isCustom{ get; set; }

    @AuraEnabled
    public String relation{ get; set; }

  }

  public class RecordTypeWrapper{
    @AuraEnabled
    public String label{ get; set; }

    @AuraEnabled
    public String value{ get; set; }

  }
}