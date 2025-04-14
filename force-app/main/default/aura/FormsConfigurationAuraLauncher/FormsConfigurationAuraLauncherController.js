({
    doInit: function(component) {
        console.log(' >> ',window.location.pathname);
        console.log(' >>>> ',document.referrer);
        var wizurl;
        var currentPath = (window.location.pathname).split("/");
        if(currentPath[4] == 'new'){
            wizurl = '/caresp/FormsConfigurationApp.app';
        }else{
            var editFlag = true;
            var recId = currentPath[4];
            wizurl = '/caresp/FormsConfigurationApp.app?isEdit='+editFlag+'&editFormId='+recId;
        }
        window.open(wizurl,'_blank');
        history.back();
    }
})