({
    doInit : function(component, event, helper) {
        var parsedUrl = new URL(window.location.href);
        component.set("v.recId",parsedUrl.searchParams.get("recordId"));
        component.set("v.objName",parsedUrl.searchParams.get("objectApiName"));
    }
})