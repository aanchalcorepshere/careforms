({
    handleSubmitForm : function(component, event, helper) {
        console.log('event from Quick Action');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : "success",
            "title": "Success!",
            "message": "Form submitted."
        });
        toastEvent.fire();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },

    handleSendForm : function(component, event, helper) {
        console.log('event from Quick Action');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : "success",
            "title": "Success!",
            "message": "Form was successfully sent for completion."
        });
        toastEvent.fire();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },

    handleCancel : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})