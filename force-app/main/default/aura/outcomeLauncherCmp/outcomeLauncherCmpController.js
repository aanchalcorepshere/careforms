({
    doInit : function(component, event, helper) {
        var outcomeObject = component.get("v.OutcomeObject").caresp__Object__c;
        console.log('objectName >>',outcomeObject)
        var outcomeAppUrl = '/caresp/OutcomeApp.app?outcomeId='+component.get("v.recordId")+'&objectName='+outcomeObject;
        window.open(outcomeAppUrl,"_blank");
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})