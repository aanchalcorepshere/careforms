trigger QuestionAnswerOptionTrigger on Question_Answer_Option__c (before insert, before update, before delete, after update, after insert,after delete, after undelete) {
	 TriggerDispatcher.Run('Question_Answer_Option__c'); 
}