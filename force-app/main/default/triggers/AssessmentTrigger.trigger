// Trigger for Assessment object to route events to TriggerDispatcher
trigger AssessmentTrigger on caresp__Assessment__c (
    before insert, before update, before delete, 
    after update, after insert, after delete, after undelete
) {
    TriggerDispatcher.Run('caresp__Assessment__c');
}