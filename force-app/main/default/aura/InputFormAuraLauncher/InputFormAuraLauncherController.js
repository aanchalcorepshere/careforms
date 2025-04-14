({
    doInit: function(component) {
        var recordId = component.get("v.recordId");
        var objName = component.get("v.sObjectName");
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        var wizurl;
        if(objName == 'caresp_Application_Staging__c'){
            var action = component.get("c.getStagingApplicationConversionStatus");
            action.setParams({ recordId : recordId });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS') {
                    var resp = response.getReturnValue();
                    console.log('resp >> ',JSON.stringify(resp));
                    let conversionStatus = resp.Conversion_Status__c;
                    if(conversionStatus == 'Converted'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "This pending application is already converted."
                        });
                        toastEvent.fire();
                        dismissActionPanel.fire();
                    }else{
                        wizurl = '/caresp/InputFormApp.app?formId='+resp.Form_Id__c+'&recordId='+recordId+'&isCreateApplication=true&isApplicationForm=false';
                        window.open(wizurl,'_blank');
                        dismissActionPanel.fire();
                    }
                }
            });
            $A.enqueueAction(action);
        }else if(objName == 'caresp__Form__c'){
            wizurl = '/caresp/InputFormApp.app?formId='+recordId+'&recordId=null&isCreateApplication=false&isApplicationForm=true';
            window.open(wizurl,'_blank');
            dismissActionPanel.fire();
        }
    }
})