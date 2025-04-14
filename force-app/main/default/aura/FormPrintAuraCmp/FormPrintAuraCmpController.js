({
    handlePrint : function(component, event, helper) {
        var recId = component.get('v.recordId');
        console.log('>> ',event.getParam('data'));
        var wizurl;
        wizurl = '/caresp/FormPrintApp.app?recordId='+recId+'&formId='+event.getParam('data')+'&objectApi='+component.get('v.sObjectName')+'&isApplication='+event.getParam('isApplication');
        window.open(wizurl,'_blank');
        $A.get("e.force:closeQuickAction").fire();
    },

    closeLWC : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})