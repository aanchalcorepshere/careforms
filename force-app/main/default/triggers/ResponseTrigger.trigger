// Trigger to handle all DML events on caresp__Response__c object and delegate processing to TriggerDispatcher
trigger ResponseTrigger on caresp__Response__c (before insert, before update, before delete, after update, after insert, after delete, after undelete) 
{
	TriggerDispatcher.Run('caresp__Response__c'); 
}