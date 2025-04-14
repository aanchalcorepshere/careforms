({
    doInit: function(component) {
        //var orgUrl = $A.get("$Label.c.Org_URL");
        var action = component.get("c.checkAssessmentInUse");
        action.setParams({ assessmentId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let resp = response.getReturnValue();
                console.log("resp  >> ",resp);
                if(resp == "non-editable"){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        mode: 'dismissible',
                        type : 'error',
                        message: 'This Assessment cannot be edited.'
                    });
                    toastEvent.fire();
                    history.back();
                }else{
                    var editFlag = true;
                    var recId = component.get("v.recordId");
                    var wizurl = '/caresp/AssessmentWizardApp.app?isEdit='+editFlag+'&editAssessmentId='+recId;
                    window.open(wizurl,'_blank');
                    window.open('/'+recId,'_self');
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})