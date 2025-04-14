public interface iTriggerHandler {
	void BeforeInsert(SObject[] newItems);
  
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
  
    void BeforeDelete(Map<Id, SObject> oldItems);
  
    void AfterInsert(Map<Id, SObject> newItems);
  
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
  
    void AfterDelete(Map<Id, SObject> oldItems);
  
    void AfterUndelete(Map<Id, SObject> oldItems);
}