({
    doInit: function(component) {
        //var orgUrl = $A.get("$Label.c.Org_URL");
        var editFlag = true;
        var recId = component.get("v.recordId");
        var wizurl = '/caresp/AssessmentWizardApp.app';
        window.open(wizurl,'_blank');
        history.back();
        
        /* var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
        "url": 'https://careshare-dev-ed.lightning.force.com/c/AssessmentWizardApp.app'
        });
        urlEvent.fire(); */
    }
})