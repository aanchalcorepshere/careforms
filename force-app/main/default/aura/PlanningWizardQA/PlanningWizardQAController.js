({
	closeLWC : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();		
	}
})