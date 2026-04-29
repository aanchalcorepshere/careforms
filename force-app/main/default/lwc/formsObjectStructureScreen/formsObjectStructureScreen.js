import { LightningElement, api, track, wire } from 'lwc';
import getRelatedObjectsList from '@salesforce/apex/FormsController.getRelatedObjectsList';
import parenticonres from '@salesforce/resourceUrl/parenticon';
import childiconres from '@salesforce/resourceUrl/childicon';
import childwithmultiiconres from '@salesforce/resourceUrl/childwithmultiicon';
import grandchildiconres from '@salesforce/resourceUrl/grandchildicon';
import getRecordTypes from '@salesforce/apex/ObjectInformationUtil.getRecordTypes';

export default class FormsObjectStructureScreen extends LightningElement {
    //defining variables
    @api primaryObjList;
    @api relatedObjList;
    primaryObject;
    //@track relatedObjList;
    @track relatedObjListResult;
    isLoading = false;
    formName;
    confirmationMessage;
    requiresSignature;
    requiresTextOnSignaturePage;
    openSignaturePageModalBox;
    showSignaturePageTextButton;
    signaturePageText;
    requiresDocUpload;
    showSummary;
    createPDFOnly;
    generatePDF;
    prefillFields; //story UST-00423
    primaryObjectForPrefillFields; //story UST-00423
    formTypeValue;
    objectsToFilterLevel1;
    objectsToFilterLevel2;
    parenticon = parenticonres;
    childicon = childiconres;
    childwithmultiicon = childwithmultiiconres;
    grandchildicon = grandchildiconres;
    @api existingData;
    @api existingFormName;
    @api existingConfirmationMessage;
    @api existingRequiresSignature;
    @api existingRequiresTextOnSignaturePage;
    @api existingSignaturePageText;
    @api existingRequiresDocUpload;
    @api existingShowSummary;
    @api existingCreatePdfOnly;
    @api existingGeneratePdf;
    @api existingPrefillFields;
    isRecordTypeModalOpen = false;
    @track recordTypeOptions;
    currentLevel;
    currentObject;
    currentParent;
    openPrefillFieldsModal = false;
    requiresSignatureSelected = false;

    @track objectStructure;

    @api isEdit = false;

    connectedCallback() {
        if(!this.isEdit && !this.existingData){
            this.openPrefillFieldsModal = true;
        }

        if(this.existingData){
            // If back button is clicked or existed form is being edited the loading the existing structure
            this.objectStructure = JSON.parse(JSON.stringify(this.existingData));
            this.showSummary = this.existingShowSummary;
            this.createPDFOnly = this.existingCreatePdfOnly;
            this.requiresSignature = this.existingRequiresSignature;
            this.prefillFields = this.existingPrefillFields;
            this.requiresTextOnSignaturePage = this.existingRequiresTextOnSignaturePage;
            if(this.requiresTextOnSignaturePage){
                this.showSignaturePageTextButton = true;
            }
            this.signaturePageText = this.existingSignaturePageText;
            this.requiresDocUpload = this.existingRequiresDocUpload;
            this.generatePDF = this.existingGeneratePdf;
        }else{
            // else initiating the base JSON structure
            this.objectStructure = {
                level: 1,
                selectedValue: "",
                placeholder: "Select Primary Object",
                fieldlabel: "Primary Object",
                disabled: false,
                type: "primary",
                isChild:false,
                isMulti:false,
                showAddButton: false,
                allowRelated: false,
                showRelated: false,
                id: "1",
                parent: "",
                grandParent: "",
                objectList: undefined,
                usedObjects:[],
                relatedList: [
        
                ]
            }
        }

        // loading existing form name in case of edit or back
        if(this.existingFormName){
            this.formName = this.existingFormName;
        }
        // loading existing confirmation message in case of edit or back
        if(this.existingConfirmationMessage){
            this.confirmationMessage = this.existingConfirmationMessage;
        }

        
        
        //send initial data to container component
        this.sendDataToContainer();
    }

    get formTypeOptions() {
        return [
            { label: 'Prefill Fields?', value: 'prefillFields' },
            { label: 'Regular', value: 'regularForm' },
        ];
    }

    renderedCallback(){
        //Adjusting margins in case of existing data
        if(this.existingData){
            let relatedButtons = this.template.querySelectorAll('[data-id="relatedButton"]');
            if (relatedButtons && relatedButtons.length) {
                relatedButtons.forEach(element => {
                    if (element.classList.contains("slds-m-vertical_medium")) {
                        element.classList.remove("slds-m-vertical_medium")
                    }
                });
            }
            let parentButtons = this.template.querySelectorAll('[data-id="parentButton"]');
            if (parentButtons && parentButtons.length) {
                parentButtons.forEach(element => {
                    if (element.classList.contains("slds-m-vertical_medium")) {
                        element.classList.remove("slds-m-vertical_medium")
                    }
                });
            }
        }
    }

    //This function runs when the primary object is selected.
    handlePrimaryChange(event) {
        this.primaryObject = event.detail.value;
        this.isLoading = true;

        //getting related objects to the selected primary object
        getRelatedObjectsList({ parentObjectName: this.primaryObject })
            .then(result => {
                this.objectStructure.objectList = JSON.parse(JSON.stringify(result));
                if(this.objectStructure.objectList && this.objectStructure.objectList.length){
                    this.objectStructure.objectList.forEach(objCat => {
                        objCat.objectList.sort(this.sortObjectList);
                    })
                }
                this.objectStructure.showAddButton = true;
                this.objectStructure.relatedList = [];
                this.objectStructure.selectedValue = event.detail.value;
                this.objectStructure.selectedLabel = event.detail.label;
                this.objectStructure.selectedRecordType = undefined;
                this.objectStructure.selectedRecordTypeLabel = undefined;
                let parentButton = this.template.querySelector('[data-id="parentButton"]');
                if (parentButton && !parentButton.classList.contains("slds-m-vertical_medium")) {
                    parentButton.classList.add("slds-m-vertical_medium");
                }
                this.isLoading = false;
                //getting primary object record types for selection
                getRecordTypes({ objectApiName: this.primaryObject })
                .then(result => {
                    console.log('rt >> ',JSON.stringify(result));
                    if(result && result.length){
                        this.recordTypeOptions = JSON.parse(JSON.stringify(result));
                        this.currentLevel = 1;
                        this.currentObject = this.objectStructure.id;
                        this.currentParent = '';
                        this.isRecordTypeModalOpen = true;
                    }
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
            })
            .catch(error => {
                console.error('error >> ', JSON.stringify(error));
                this.isLoading = false;
            })
        this.objectStructure = JSON.parse(JSON.stringify(this.objectStructure));

        //send current data to container
        this.sendDataToContainer();
    }

    /* okClick(){
        this.isRecordTypeModalOpen = false;
    } */

    //This function is used to set record type of the object selected at any level
    setRecordTypeData(event){
        let level = event.detail.level;
        let parent = event.detail.parent;
        let objId = event.detail.objectId;
        let selectedRecordType = event.detail.selectedRecordType;
        let selectedRecordTypeLabel = event.detail.selectedRecordTypeLabel;
        if(level == 1){
            this.objectStructure.selectedRecordType = selectedRecordType;
            this.objectStructure.selectedRecordTypeLabel = selectedRecordTypeLabel;
        }else if(level == 2){
            let pos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
            this.objectStructure.relatedList[pos].selectedRecordType = selectedRecordType;
            this.objectStructure.relatedList[pos].selectedRecordTypeLabel = selectedRecordTypeLabel;
        }else if(level == 3){
            let parentPos = this.objectStructure.relatedList.findIndex(rel => rel.id == parent);
            let objectPos = this.objectStructure.relatedList[parentPos].relatedList.findIndex(rel => rel.id == objId);
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedRecordType = selectedRecordType;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedRecordTypeLabel = selectedRecordTypeLabel;
        }

        this.isRecordTypeModalOpen = false;

        //send current structure to container
        this.sendDataToContainer();
    }

    //get form name from input box
    handleFromName(event) {
        //this.formName = (event.target.value).toUpperCase();
        this.formName = event.target.value;
    }

    //get conformation message from rich-text box
    handleConfirmationMessage(event){
        this.confirmationMessage = event.target.value;
        this.sendDataToContainer();
    }

    handleSignaturePageText(){
        this.signaturePageText = this.template.querySelector(`[data-id="signaturePageText"]`).value;
        console.log('signaturePageText >> '+this.signaturePageText);
        //this.openSignaturePageModalBox = false;
        this.sendDataToContainer();
    }

    closeSignaturePageModal(){
        this.openSignaturePageModalBox = false;
    }

    handleConfiguration(event){
        let targetName = event.target.name;
        let targetChecked = event.target.checked;
        let targetVal = event.target.value;
        if(targetName == 'requiressignature'){
            if(targetChecked){
                this.requiresSignature = targetChecked;
                this.template.querySelector('[data-id="generatepdf"]').checked = true;
                this.requiresSignatureSelected = true;
            }else{
                let confirmation = confirm("By unchecking this checkbox you will loose any information entered for Signature Page text. Are you sure you want to proceed?");
                if(confirmation){
                    this.requiresSignatureSelected = false;
                    this.requiresSignature = targetChecked;
                    this.showSignaturePageTextButton = false;
                    this.signaturePageText = null;
                    this.requiresTextOnSignaturePage = false;
                }else{
                    event.target.checked = true;
                    this.requiresSignature = true;
                    let tempCheckbox = this.template.querySelector('[data-id="requiresSignature"]');
                    tempCheckbox.checked = true;
                    let tempCheckbox2 = this.template.querySelector('[data-id="requiresTextOnSignaturePage"]');
                    if(tempCheckbox2.checked){
                        tempCheckbox2.checked = true;
                        this.requiresTextOnSignaturePage = true;
                    }
                }
            }
        }else if(targetName == 'requirestextonsignaturepage'){
            if(targetChecked){
                this.requiresTextOnSignaturePage = targetChecked;
                this.showSignaturePageTextButton = true;
            }else{
                let confirmation = confirm("By unchecking this checkbox you will loose any information entered for Signature Page text. Are you sure you want to proceed?");
                if(confirmation){
                    this.requiresTextOnSignaturePage = targetChecked;
                    this.showSignaturePageTextButton = false;
                    this.signaturePageText = null;
                }else{
                    event.target.checked = true;
                    this.requiresTextOnSignaturePage = true;
                    let tempCheckbox = this.template.querySelector('[data-id="requiresTextOnSignaturePage"]');
                    tempCheckbox.checked = true;
                }
            }
        }else if(targetName == 'requiresdocupload'){
            this.requiresDocUpload = targetChecked;
        }else if(targetName == 'showsummary'){
            this.showSummary = targetChecked;
        }else if(targetName == 'generatepdf'){
            this.generatePDF = targetChecked;
        }else if (targetName == 'createpdfonly'){
            this.createPDFOnly = targetChecked;
        }else if(targetName == 'formType'){
            this.prefillFields = targetVal == 'prefillFields'?true:false;
            this.openPrefillFieldsModal = false;
            console.log('this.prefillFields >> '+this.prefillFields);
        }
        this.sendDataToContainer();
    }

    openSignaturePageModal(){
        this.openSignaturePageModalBox = true;
    }

    //this is to reset selected record type
    resetRecordType(event){
        let level = event.currentTarget.dataset.level;
        let object = event.currentTarget.dataset.object;
        let parent = event.currentTarget.dataset.parent;
        let objId = event.currentTarget.dataset.id;
        if(level == 1){
            this.currentLevel = 1;
            this.currentObject = this.objectStructure.id;
            this.currentParent = '';
        }else if(level == 2 || level == 3){
            this.currentLevel = level;
            this.currentObject = objId;
            this.currentParent = parent;
            object = object.substr(0,object.indexOf('|'));
        }
        getRecordTypes({ objectApiName: object })
        .then(result => {
            if(result && result.length){
                this.recordTypeOptions = JSON.parse(JSON.stringify(result));
                this.isRecordTypeModalOpen = true;
            }
        })
        .catch(error => {
            this.error = JSON.stringify(error);
        })
    }

    //This function is create a placeholder for related object
    addRelated() {
        this.objectStructure.showRelated = true;
        this.template.querySelector('[data-id="parentButton"]').classList.remove("slds-m-vertical_medium");
        let relLength = this.objectStructure.relatedList.length + 1;
        let rel = {
            id: "1." + relLength,
            level: 2,
            selectedValue: "",
            placeholder: "Select Related Object",
            fieldlabel: "Related Object",
            disabled: false,
            type: "",
            isChild:false,
            isMulti:false,
            showAddButton: false,
            allowRelated: false,
            parent: "1",
            grandParent: "",
            objectList: undefined,
            usedObjects:[],
            relatedList: []
        }
        this.objectStructure.relatedList.push(rel);

        this.sendDataToContainer();
    }

    //This function creates used object array so that those can be excluded from original list.
    handleUsedObjects(level,parentPos){
        let tempUsedObjArray = [];
        if(level == 2){
            if(this.objectStructure.relatedList.length){
                this.objectStructure.relatedList.forEach(related => {
                    tempUsedObjArray.push(related.selectedValue);
                })
                this.objectStructure.usedObjects = tempUsedObjArray;
            }
        }else if(level == 3){
            if(this.objectStructure.relatedList[parentPos].relatedList.length){
                this.objectStructure.relatedList[parentPos].relatedList.forEach(related => {
                    tempUsedObjArray.push(related.selectedValue);
                })
                this.objectStructure.relatedList[parentPos].usedObjects = tempUsedObjArray;
            }
        }
    }

    //This function is run when related object is selected at any level.
    handleRelatedChange(event) {
        let selVal = event.detail.value;
        let selLabel = event.detail.label;
        let level = event.detail.level;
        let type = event.detail.type;
        let parent = event.detail.parent;
        let grandParent = event.detail.grandParent;
        let objId = event.detail.id;
        if (level == 2) {
            if (type == 'Children') {
                this.primaryObject = selVal.substr(0, selVal.indexOf('|'));
                this.isLoading = true;
                //if related object is of type child to primary then get related objects to that object
                getRelatedObjectsList({ parentObjectName: this.primaryObject })
                .then(result => {
                    let pos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
                    this.objectStructure.relatedList[pos].objectList = JSON.parse(JSON.stringify(result));
                    if(this.objectStructure.relatedList[pos].objectList && this.objectStructure.relatedList[pos].objectList.length){
                        this.objectStructure.relatedList[pos].objectList.forEach(objCat => {
                            objCat.objectList.sort(this.sortObjectList);
                        })
                    }
                    this.objectStructure.relatedList[pos].showAddButton = true;
                    //this.objectStructure.relatedList[pos].disabled = true;
                    this.objectStructure.relatedList[pos].type = type;
                    this.objectStructure.relatedList[pos].isChild = true;
                    this.objectStructure.relatedList[pos].isMulti = false;
                    this.objectStructure.relatedList[pos].selectedValue = selVal;
                    this.objectStructure.relatedList[pos].selectedLabel = selLabel;
                    this.objectStructure.relatedList[pos].selectedRecordType = undefined;
                    this.objectStructure.relatedList[pos].selectedRecordTypeLabel = undefined;
                    this.isLoading = false;
                    //once related object is selected get record types.
                    getRecordTypes({ objectApiName: this.primaryObject })
                    .then(result => {
                        if(result && result.length){
                            console.log('rt >> ',JSON.stringify(result));
                            this.recordTypeOptions = JSON.parse(JSON.stringify(result));
                            this.currentLevel = 2;
                            this.currentObject = this.objectStructure.relatedList[pos].id;
                            this.currentParent = parent;
                            this.isRecordTypeModalOpen = true;
                        }
                    })
                    .catch(error => {
                        this.error = JSON.stringify(error);
                    })
                    this.handleUsedObjects(level,1);
                    this.sendDataToContainer();
                    //console.log('obj structure >> ', JSON.stringify(this.objectStructure));
                })
                .catch(error => {
                    this.isLoading = false;
                })
                this.objectStructure = JSON.parse(JSON.stringify(this.objectStructure));
            } else if (type == 'Lookup(Parent)') {
                let pos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
                this.objectStructure.relatedList[pos].type = type;
                this.objectStructure.relatedList[pos].selectedValue = selVal;
                this.objectStructure.relatedList[pos].selectedLabel = selLabel;
                this.objectStructure.relatedList[pos].selectedRecordType = undefined;
                this.objectStructure.relatedList[pos].selectedRecordTypeLabel = undefined;
                let selectedObj = selVal.substr(0, selVal.indexOf('|'));
                //If related object is of Parent type then no need to get related object but get record types straight away
                getRecordTypes({ objectApiName: selectedObj })
                .then(result => {
                    if(result && result.length){
                        this.recordTypeOptions = JSON.parse(JSON.stringify(result));
                        this.currentLevel = level;
                        this.currentObject = this.objectStructure.relatedList[pos].id;
                        this.currentParent = parent;
                        this.isRecordTypeModalOpen = true;
                    }
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                })
                this.handleUsedObjects(level,1);
                this.sendDataToContainer();
                //console.log('obj structure >> ', JSON.stringify(this.objectStructure));
            }
        } else if (level == 3) //handle level 3 (last level allowed) selection
        {
            let parentPos = this.objectStructure.relatedList.findIndex(rel => rel.id == parent);
            let objectPos = this.objectStructure.relatedList[parentPos].relatedList.findIndex(rel => rel.id == objId);
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedValue = selVal;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedLabel = selLabel;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedRecordType = undefined;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].selectedRecordTypeLabel = undefined;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].type = type;
            this.objectStructure.relatedList[parentPos].relatedList[objectPos].isChild = type == 'Lookup(Parent)'?false:true;
            let selectedObj = selVal.substr(0, selVal.indexOf('|'));

            //getting record types for selected object
            getRecordTypes({ objectApiName: selectedObj })
            .then(result => {
                if(result && result.length){
                    this.recordTypeOptions = JSON.parse(JSON.stringify(result));
                    this.currentLevel = level;
                    this.currentObject = this.objectStructure.relatedList[parentPos].relatedList[objectPos].id;
                    this.currentParent = parent;
                    this.isRecordTypeModalOpen = true;
                }
            })
            .catch(error => {
                this.error = JSON.stringify(error);
            })
            this.handleUsedObjects(level,parentPos);
            this.sendDataToContainer();
            //console.log('obj structure >> ', JSON.stringify(this.objectStructure));
        }
    }

    
    //This function is used to create place holder at grandchild level
    addChildRelated(event) {
        let objId = event.currentTarget.dataset.objId;
        let parent = event.currentTarget.dataset.parent;
        let level = event.currentTarget.dataset.level;
        let relatedButtons = this.template.querySelectorAll('[data-id="relatedButton"]');
        if (relatedButtons && relatedButtons.length) {
            relatedButtons.forEach(element => {
                if (element.classList.contains("slds-m-vertical_medium")) {
                    element.classList.remove("slds-m-vertical_medium")
                }
            });
        }
        let parentPos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
        let relLength = this.objectStructure.relatedList[parentPos].relatedList.length + 1;
        let rel = {
            id: objId + "." + relLength,
            level: 3,
            selectedValue: "",
            placeholder: "Select Related Object",
            fieldlabel: "Related Object",
            disabled: false,
            type: "",
            isChild:false,
            isMulti:false,
            showAddButton: false,
            allowRelated: false,
            parent: objId,
            grandParent: "",
            objectList: this.relatedObjList,
        }
        this.objectStructure.relatedList[parentPos].relatedList.push(rel);
        this.objectStructure.relatedList[parentPos].showRelated = true;
        this.sendDataToContainer();
    }

    
    //This function is used to delete any level
    handleDelete(event) {
        let parent = event.currentTarget.dataset.parent;
        let objId = event.currentTarget.dataset.objId;
        let level = event.currentTarget.dataset.level;

        if (level == 2) {
            let objPos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
            if (objPos != -1) {
                this.objectStructure.relatedList.splice(objPos, 1);
                let seq = 1;
                this.objectStructure.relatedList.forEach(rel => {
                    rel.id = "1." + seq;
                    seq++;
                });
            }
        } else if (level == 3) {
            let parentPos = this.objectStructure.relatedList.findIndex(rel => rel.id == parent);
            let objPos = this.objectStructure.relatedList[parentPos].relatedList.findIndex(rel => rel.id == objId);
            if (objPos != -1) {
                this.objectStructure.relatedList[parentPos].relatedList.splice(objPos, 1);
                let seq = 1;
                this.objectStructure.relatedList[parentPos].relatedList.forEach(rel => {
                    rel.id = parent + "." + seq;
                    seq++;
                });
            }
        }
        this.sendDataToContainer();
    }

    //This function captures change in 'multi' checkbox
    handleMultiChange(event){
        let objId = event.currentTarget.dataset.objId;
        let level = event.currentTarget.dataset.level;
        let checkboxVal = event.target.checked;

        if (level == 2) {
            let objPos = this.objectStructure.relatedList.findIndex(rel => rel.id == objId);
            if (objPos != -1) {
                this.objectStructure.relatedList[objPos].showAddButton = !checkboxVal;
                this.objectStructure.relatedList[objPos].isMulti = checkboxVal;
                if(this.objectStructure.relatedList[objPos].showRelated && checkboxVal){
                    this.objectStructure.relatedList[objPos].showRelated = false;
                    this.objectStructure.relatedList[objPos].relatedList = [];
                }else{

                }
            }
        }
    }

    //This is to sort object list label wise alphabetically
    sortObjectList(a, b) {
        if (a.label < b.label) {
            return -1;
        }
        if (a.label > b.label) {
            return 1;
        }
        return 0;
    }

    //This function sends the data to the container component
    sendDataToContainer() {
        this.dispatchEvent(new CustomEvent('objectstructure', 
        { 
            detail: [this.formName, this.objectStructure, this.confirmationMessage, this.requiresSignature, this.requiresTextOnSignaturePage, this.signaturePageText, this.requiresDocUpload, this.showSummary, this.generatePDF, this.prefillFields, this.createPDFOnly]
        }));
    }
}