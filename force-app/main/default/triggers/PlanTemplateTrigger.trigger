// Trigger for Plan Template object that delegates trigger logic to a trigger handler via TriggerDispatcher.
trigger PlanTemplateTrigger on caresp__Plan_Template__c (before insert, before update, before delete, after update, after insert, after delete, after undelete) {
    TriggerDispatcher.Run('caresp__Plan_Template__c');
}