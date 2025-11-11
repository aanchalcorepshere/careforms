// Trigger to handle all DML events on caresp__Question_Answer_Option__c object and delegate processing to TriggerDispatcher
trigger QuestionAnswerOptionTrigger on caresp__Question_Answer_Option__c (before insert, before update, before delete, after update, after insert, after delete, after undelete) {
	TriggerDispatcher.Run('caresp__Question_Answer_Option__c'); 
}