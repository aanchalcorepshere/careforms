import { LightningElement, track, api } from 'lwc';
import getFieldsData from '@salesforce/apex/FormsController.getFieldsData';
import RICH_TEXT_BOX from '@salesforce/resourceUrl/richtextbox';
// Example :- import TRAILHEAD_LOGO from '@salesforce/resourceUrl/trailhead_logo';'

export default class FormsCreateFormScreen extends LightningElement {
    richTextBoxImage = RICH_TEXT_BOX;
    isLoading = false;
    @api formName;
    draggedField;
    openEditLabelModal = false;
    currentPagePos;
    currentSectionPos;
    currentFieldPos;
    @track objectList = [];
    @track fieldList;
    @track unfilteredFieldList;
    searchText;
    isLocalDrag = false;
    /* sectionDrag = false;
    fieldDrag = false; */
    @api existingData;
    @api existingFields;
    fieldsToFilterFromFieldList = [];
    draggedSectionPageIndex;
    draggedSectionSectionIndex;
    isSectionDrag = false;
    sectionTypeOptions = [
        {label:"Regular Section",value:"regularSection"},
        {label:"Multi-records Questions Section",value:"multiQuesSection"}
    ];
    isSectionTypeModalOpen = false;

    @api objectStructure;

    @track pages;
    @api prefillFields;

    constructor() {
        super();
        this.addEventListener('currentdropzone', this.handleCurrentDropPage.bind(this));
        this.addEventListener('addrow', this.handleAddRow.bind(this));
        this.addEventListener('columnchange', this.handleColumnChange.bind(this));
        this.addEventListener('fieldrequired', this.handleRequired.bind(this));
        this.addEventListener('fieldlabelchange', this.handleFieldLabelChange.bind(this));
        this.addEventListener('fieldlabeledit', this.handleFieldLabelEdit.bind(this));
        this.addEventListener('sectionlabeledit', this.handleSectionLabelEdit.bind(this));
        this.addEventListener('sectionlabeleditdone', this.handleSectionLabelEditDone.bind(this));
        this.addEventListener('clearfield', this.handleClear.bind(this));
        this.addEventListener('deletefield', this.handleDelete.bind(this));
        this.addEventListener('localdragstart', this.handleLocalDragStart.bind(this));
        this.addEventListener('deletesection', this.handleSectionDelete.bind(this));
        this.addEventListener('richtextcontent', this.handleRichTextContent.bind(this));
        this.addEventListener('updatehelptext', this.handleFieldHelpText.bind(this));
        
    }

    connectedCallback() {
        this.isLoading = true;
        if(this.existingData){
            this.pages = JSON.parse(JSON.stringify(this.existingData));
            if(this.pages.length){
                this.pages.forEach(page => {
                    if(page.sections.length){
                        page.sections.forEach(section => {
                            if(section.fields.length){
                                section.fields.forEach(field => {
                                    this.fieldsToFilterFromFieldList.push(field.fieldData.objectName+'#'+field.fieldData.fieldApi);
                                })
                            }
                        })
                    }
                })
            }
        }else{
            this.pages = this.initializePages();
        }

        //console.log("pages >> ",JSON.stringify(this.pages));

        this.objectList.push(this.objectStructure.selectedValue + "#" + this.objectStructure.isChild + "#" + this.objectStructure.isMulti);
        if (this.objectStructure.relatedList) {
            this.objectStructure.relatedList.forEach(relLevel1 => {
                this.objectList.push(relLevel1.selectedValue + "#" + relLevel1.isChild + "#" + relLevel1.isMulti);
                if (relLevel1.relatedList) {
                    relLevel1.relatedList.forEach(relLevel2 => {
                        this.objectList.push(relLevel2.selectedValue + "#" + relLevel2.isChild + "#" + relLevel2.isMulti);
                    })
                }
            })
        }

        if (this.objectList) {
            this.isLoading = true;
            console.log('objectList >> ', JSON.stringify(this.objectList));
            getFieldsData({ objectList: this.objectList, prefillFields:this.prefillFields })
                .then(result => {
                    this.fieldList = JSON.parse(JSON.stringify(result));
                    //console.log('fieldlist >> ', JSON.stringify(this.fieldList));
                    if(this.existingData){
                        this.fieldList.forEach(obj => {
                            this.fieldsToFilterFromFieldList.forEach(removeField => {
                                obj.fields = obj.fields.filter(function (el) {
                                    return (el.objectName+"#"+el.fieldApi) != removeField;
                                });
                            })
                            obj.fields.sort(this.sortFieldList);
                        })
                    }else{
                        let i = 0;
                        let fieldsToBeRemoved = [];
                        this.fieldList.forEach(obj => {
                            if (!obj.isMulti) {
                                obj.fields.forEach(field => {
                                    if (field.required && obj.objectName != 'Question') {
                                        this.pages[0].sections[0].fields[i].isField = true;
                                        this.pages[0].sections[0].fields[i].isRichTextBox = false;
                                        this.pages[0].sections[0].fields[i].fieldData = JSON.parse(JSON.stringify(field));
                                        this.pages[0].sections[0].fields.push(
                                            {
                                                fieldIndex: (i+1),
                                                isLabelEdit: false,
                                                fieldClass:"field"+(i+1),
                                                customlabel: "",
                                                isField:true,
                                                isRichTextBox:false,
                                                fieldData: {}
                                            }
                                        )
                                        i++;
                                        fieldsToBeRemoved.push(field.fieldUniqueName);
                                    }
                                })
                            } else {
                                let tempSection = {
                                    sectionIndex: this.pages[0].sections.length,
                                    sectionName: "New Section",
                                    sectionClass: "section"+this.pages[0].sections.length,
                                    isLabelEdit: false,
                                    isSectionMulti:true,
                                    columns: 12,
                                    isFieldsSection:true,
                                    isRichTextSection:false,
                                    fields: [
                                        {
                                            fieldIndex: 0,
                                            isLabelEdit: false,
                                            fieldClass:"field"+0,
                                            customlabel: "",
                                            isField:true,
                                            isRichTextBox:false,
                                            fieldData: {}
                                        },
                                    ]
                                };
                                this.pages[0].sections.push(tempSection);
                                let j = 0;
                                obj.fields.forEach(field => {
                                    if (field.required) {
                                        this.pages[0].sections[this.pages[0].sections.length - 1].multiObjUniqueName = obj.objectUniqueName;
                                        this.pages[0].sections[this.pages[0].sections.length - 1].fields[j].fieldData = JSON.parse(JSON.stringify(field));
                                        this.pages[0].sections[this.pages[0].sections.length - 1].fields.push(
                                            {
                                                fieldIndex: (j+1),
                                                isLabelEdit: false,
                                                fieldClass:"field"+(j+1),
                                                customlabel: "",
                                                fieldData: {}
                                            }
                                        )
                                        fieldsToBeRemoved.push(field.fieldUniqueName);
                                        j++;
                                    }
                                })
                            }
                        });

                        this.fieldList.forEach(obj => {
                            fieldsToBeRemoved.forEach(removeField => {
                                obj.fields = obj.fields.filter(function (el) {
                                    return el.fieldUniqueName != removeField;
                                });
                            })
                            obj.fields.sort(this.sortFieldList);
                        })
                    }
                    this.isLoading = false;
                    this.unfilteredFieldList = JSON.parse(JSON.stringify(this.fieldList));
                    /* this.unfilteredFieldList.forEach(type => {
                        console.log(' <<data>>',type.objectName,'<<length>>',type.fields.length);
                    })
                    console.log('page data >>> ',JSON.stringify(this.pages)); */
                    this.sendPagesDataToContainer();
                })
                .catch(error => {
                    this.error = JSON.stringify(error);
                    console.error('ERROR >> ',JSON.stringify(error));
                })
        }
    }

    initializePages(){
        return [
            {
                pageIndex: 0,
                pageName: "New Page",
                isLabelEdit: false,
                sections: [
                    {
                        sectionIndex: 0,
                        sectionName: "New Section",
                        sectionClass:"section"+0,
                        isLabelEdit: false,
                        isSectionMulti:false,
                        columns: 12,
                        fields: [
                            {
                                fieldIndex: 0,
                                isLabelEdit: false,
                                fieldClass:"field"+0,
                                customlabel: "",
                                isField:true,
                                isRichTextBox:false,
                                fieldData: {}
                            },
                        ]
                    }
                ]
            }
        ];
    }

    /* get isLoading() {
        return !this.fieldList.length;
    } */

    addPage(event) {
        let addIndex = parseInt(event.currentTarget.dataset.id);
        console.log('addIndex >> ',addIndex);
        console.log('addIndex >> ',addIndex+1);
        let thePage = {
            pageIndex: addIndex+1,
            pageName: "New Page",
            isLabelEdit: false,
            sections: [
                {
                    sectionIndex: 0,
                    sectionName: "New Section",
                    sectionClass:"section"+0,
                    isLabelEdit: false,
                    isSectionMulti:false,
                    columns: 12,
                    fields: [
                        {
                            fieldIndex: 0,
                            isLabelEdit: false,
                            fieldClass:"field"+0,
                            customlabel: "",
                            isField:true,
                            isRichTextBox:false,
                            fieldData: {}
                        },
                    ]
                }
            ]
        };
        this.pages.splice(addIndex+1,0,thePage);
        this.refreshIndexes();
    }

    captureDraggedSectionSource(event){
        //console.log('dragged section >> ',event.detail.pageIndex,' >> ',event.detail.sectionIndex,' >> ',event.detail.isSectionDrag);
        [this.draggedSectionPageIndex,this.draggedSectionSectionIndex, this.isSectionDrag] = [event.detail.pageIndex, event.detail.sectionIndex, event.detail.isSectionDrag];
    }

    captureDestinationSection(event){
        //console.log('section destination >> ',event.detail.pageIndex,' >> ',event.detail.sectionIndex);
        //console.log('isSectionDrag >> ',this.isSectionDrag);
        if(this.isSectionDrag){
            //console.log('here');
            let sourcePageIndex = event.detail.pageIndex;
            let sourceSectionIndex = event.detail.sectionIndex;

            let tempSection = this.pages[this.draggedSectionPageIndex].sections[this.draggedSectionSectionIndex];
            this.pages[this.draggedSectionPageIndex].sections[this.draggedSectionSectionIndex] = this.pages[sourcePageIndex].sections[sourceSectionIndex];
            this.pages[sourcePageIndex].sections[sourceSectionIndex] = tempSection;
            this.refreshIndexes();
        }
        this.draggedSectionPageIndex = undefined;
        this.draggedSectionSectionIndex = undefined;
        this.isSectionDrag = false;
    }

    handleDragStart(event) {
        this.isLocalDrag = false;
        this.draggedField = event.currentTarget.dataset.id;
        //console.log('this.draggedField >> ',this.draggedField);
    }

    handleLocalDragStart(event) {
        this.draggedField = event.detail.fieldIndex;
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;
        this.sectionDrag = false;
        this.fieldDrag = true;
        this.isLocalDrag = true;
    }

    handleCurrentDropPage(event) {
        let pagePos = event.detail.pageIndex;
        let sectionPos = event.detail.sectionIndex;
        let fieldPos = event.detail.fieldIndex;
        let isSourceMulti;
        let isDestinationMulti;
        let sourceObjUniqueName;
        let destinationObjUniqueName;
        let objName;
        let objectLabel;
        let fieldName;
        let fieldListObjName;
        let sectionObjName;
        let objPosFromFieldList;
        let fieldPosFromFieldList;
        let objPosFromUnfilteredFieldList;
        let fieldPosFromUnfilteredFieldList;
        let isSectionQuestionsOnly;
        let isDraggedFieldQuestion;

        if (this.isLocalDrag) { // case where field is being dragged from within the page area
            isSourceMulti = this.pages[this.currentPagePos].sections[this.currentSectionPos].isSectionMulti;
            isDestinationMulti = this.pages[pagePos].sections[sectionPos].isSectionMulti;
            sourceObjUniqueName = this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].objectName;
            destinationObjUniqueName = this.pages[pagePos].sections[sectionPos].fields[fieldPos].objectName;

            if(isSourceMulti && isDestinationMulti){ // if source is multi and destination is also multi
                if((sourceObjUniqueName === destinationObjUniqueName) && (this.currentPagePos === pagePos) && (this.currentSectionPos === sectionPos)){
                    [this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos], this.pages[pagePos].sections[sectionPos].fields[fieldPos]] = [this.pages[pagePos].sections[sectionPos].fields[fieldPos], this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos]];
                }else{ // if section object and field object are not same in case both source and destination are multi then dropping is not allowed
                    alert('not allowed');
                }
            }else if(!isSourceMulti && !isDestinationMulti){ //if source is not multi and destination is also not multi
                [this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos], this.pages[pagePos].sections[sectionPos].fields[fieldPos]] = [this.pages[pagePos].sections[sectionPos].fields[fieldPos], this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos]];
            }else if((!isSourceMulti && isDestinationMulti) || (isSourceMulti && !isDestinationMulti)){ // if source is multi but destination is not multi and vice-versa
                alert('not allowed');
            }
        } else { // if field or rich text box is dragged to the page from left panel
            if(this.draggedField == 'richtextbox'){
                isDestinationMulti = this.pages[pagePos].sections[sectionPos].isSectionMulti;
                if(!isDestinationMulti){
                    if(this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.fieldName){
                        let tempfield = {
                            fieldIndex: 0,
                            isLabelEdit: false,
                            fieldClass:"field"+0,
                            customlabel: "",
                            isField:false,
                            isRichTextBox:true,
                            fieldData: {}
                        }
                        this.pages[pagePos].sections[sectionPos].fields.splice(fieldPos,0,tempfield);
                    }else{
                        this.pages[pagePos].sections[sectionPos].fields[fieldPos].isField = false;
                        this.pages[pagePos].sections[sectionPos].fields[fieldPos].isRichTextBox = true;
                        this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData = {}
                    }
                }else{
                    alert('not allowed');
                }
            }else{//dragged field is regular field
                objName = this.draggedField.substr(0, this.draggedField.indexOf('::'));
                fieldName = this.draggedField.substr(this.draggedField.indexOf('::') + 2, this.draggedField.length);
                objPosFromFieldList = this.fieldList.findIndex(object => object.objectName == objName); // position of object from field list
                fieldPosFromFieldList = this.fieldList[objPosFromFieldList].fields.findIndex(x => x.fieldApi == fieldName); //position of the field from object within field list
                objPosFromUnfilteredFieldList = this.unfilteredFieldList.findIndex(object => object.objectName == objName);// position of object from original(unfiltered) field list
                fieldPosFromUnfilteredFieldList = this.unfilteredFieldList[objPosFromUnfilteredFieldList].fields.findIndex(x => x.fieldApi == fieldName);//position of the field from object within original(unfiltered) field list
                fieldListObjName = this.fieldList[objPosFromFieldList].objectUniqueName;
                sectionObjName = this.pages[pagePos].sections[sectionPos].multiObjUniqueName;
                isDestinationMulti = this.pages[pagePos].sections[sectionPos].isSectionMulti;
                isSourceMulti = this.fieldList[objPosFromFieldList].isMulti;
                objectLabel = this.fieldList[objPosFromFieldList].objectLabel;
                isSectionQuestionsOnly = this.pages[pagePos].sections[sectionPos].isQuestionsOnly;
                isDraggedFieldQuestion = this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList].isQuestion;

                if(isSectionQuestionsOnly){
                    if(isDraggedFieldQuestion){
                        if(this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.fieldName){
                            let tempfield = {
                                fieldIndex: 0,
                                isLabelEdit: false,
                                fieldClass:"field"+0,
                                customlabel: "",
                                isField:true,
                                isRichTextBox:false,
                                fieldData: JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]))
                            }
                            this.pages[pagePos].sections[sectionPos].fields.splice(fieldPos,0,tempfield);
                        }else{
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].isField = true;
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].isRichTextBox = false;
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData = JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]));
                        }
                        //this.fieldList[objPosFromFieldList].fields.splice(fieldPosFromFieldList, 1);
                        //this.unfilteredFieldList[objPosFromFieldList].fields.splice(fieldPosFromUnfilteredFieldList, 1);
                    }else{
                        alert('not allowed');
                    }
                }else{
                    if(isDestinationMulti && isSourceMulti){
                        if((fieldListObjName === sectionObjName) || !sectionObjName){
                            //console.log("here >>> ");
                            if(this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.fieldName){
                                let tempfield = {
                                    fieldIndex: 0,
                                    isLabelEdit: false,
                                    fieldClass:"field"+0,
                                    customlabel: "",
                                    isField:true,
                                    isRichTextBox:false,
                                    fieldData: JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]))
                                }
                                this.pages[pagePos].sections[sectionPos].fields.splice(fieldPos,0,tempfield);
                            }else{
                                this.pages[pagePos].sections[sectionPos].fields[fieldPos].isField = true;
                                this.pages[pagePos].sections[sectionPos].fields[fieldPos].isRichTextBox = false;
                                this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData = JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]));
                            }
    
                            if(!sectionObjName){
                                this.pages[pagePos].sections[sectionPos].multiObjUniqueName = fieldListObjName;
                                this.pages[pagePos].sections[sectionPos].objectLabel = objectLabel;
                                console.log('objectLabel >> '+JSON.stringify(this.pages[pagePos].sections[sectionPos]));
                            }
    
                            this.fieldList[objPosFromFieldList].fields.splice(fieldPosFromFieldList, 1);
                            this.unfilteredFieldList[objPosFromFieldList].fields.splice(fieldPosFromUnfilteredFieldList, 1);
                        }else{
                            alert('not allowed');
                        }
                    }else if(!isDestinationMulti && !isSourceMulti){
                        if(this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.fieldName){
                            let tempfield = {
                                fieldIndex: 0,
                                isLabelEdit: false,
                                fieldClass:"field"+0,
                                customlabel: "",
                                isField:true,
                                isRichTextBox:false,
                                fieldData: JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]))
                            }
                            this.pages[pagePos].sections[sectionPos].fields.splice(fieldPos,0,tempfield);
                        }else{
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].isField = true;
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].isRichTextBox = false;
                            this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData = JSON.parse(JSON.stringify(this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList]));
                        }
                        if(!this.fieldList[objPosFromFieldList].fields[fieldPosFromFieldList].isQuestion){
                            this.fieldList[objPosFromFieldList].fields.splice(fieldPosFromFieldList, 1);
                            this.unfilteredFieldList[objPosFromFieldList].fields.splice(fieldPosFromUnfilteredFieldList, 1);
                        }
                    }else{
                        alert('not allowed');
                    }
                }
            }
        }
        this.refreshIndexes();
        this.sendPagesDataToContainer();
    }

    refreshIndexes() {
        let i = 0;
        this.pages.forEach(page => {
            page.pageIndex = i++;
            if (page.sections) {
                let j = 0;
                page.sections.forEach(section => {
                    section.sectionIndex = j;
                    section.sectionClass = "section" + j++;
                    if (section.fields) {
                        let k = 0;
                        section.fields.forEach(field => {
                            field.fieldIndex = k;
                            field.fieldClass = "field" + k++;
                        })
                    }
                })
            }
        })
    }

    handleAddSection(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.isSectionTypeModalOpen = true;
        /* let pagePos = event.detail.pageIndex;
        this.pages[pagePos].sections.push(
            {
                sectionIndex: this.pages[pagePos].sections.length,
                sectionName: "New Section",
                sectionClass : "section"+this.pages[pagePos].sections.length,
                isLabelEdit: false,
                columns : 1,
                fields: [
                    {
                        fieldIndex: 0,
                        isLabelEdit: false,
                        fieldClass: "field"+0,
                        customlabel: "",
                        fieldData: {}
                    },
                ]
            }
        );
        this.sendPagesDataToContainer(); */
    }

    handleSectionTypeSelection(event){
        let sectionType = event.target.value;
        switch(sectionType){
            case "regularSection":
                //let pagePos = event.detail.pageIndex;
                this.pages[this.currentPagePos].sections.push(
                    {
                        sectionIndex: this.pages[this.currentPagePos].sections.length,
                        sectionName: "New Section",
                        sectionClass : "section"+this.pages[this.currentPagePos].sections.length,
                        isLabelEdit: false,
                        columns : 12,
                        fields: [
                            {
                                fieldIndex: 0,
                                isLabelEdit: false,
                                fieldClass: "field"+0,
                                customlabel: "",
                                isField:true,
                                isRichTextBox:false,
                                fieldData: {}
                            },
                        ]
                    }
                );
                break;
            case "multiQuesSection":
                this.pages[this.currentPagePos].sections.push(
                    {
                        sectionIndex: this.pages[this.currentPagePos].sections.length,
                        sectionName: "New Multi Question Section",
                        sectionClass : "section"+this.pages[this.currentPagePos].sections.length,
                        isLabelEdit: false,
                        isSectionMulti:true,
                        isQuestionsOnly:true,
                        columns : 12,
                        fields: [
                            {
                                fieldIndex: 0,
                                isLabelEdit: false,
                                fieldClass: "field"+0,
                                customlabel: "",
                                isField:true,
                                isRichTextBox:false,
                                fieldData: {}
                            },
                        ]
                    }
                );
                break;
            /* case "richTextBox":
                console.log('>>> '+this.pages[this.currentPagePos].sections.length);
                this.pages[this.currentPagePos].sections.push(
                    {
                        sectionIndex: this.pages[this.currentPagePos].sections.length,
                        sectionName: "New Section",
                        sectionClass : "section"+this.pages[this.currentPagePos].sections.length,
                        isLabelEdit: false,
                        columns : 1,
                        isFieldsSection:false,
                        isRichTextSection:true
                    }
                );
                break; */
        }

        this.isSectionTypeModalOpen = false;
        this.sendPagesDataToContainer();
    }

    handleColumnChange(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        let cols = event.detail.columns;
        this.pages[this.currentPagePos].sections[this.currentSectionPos].columns = cols;
        this.sendPagesDataToContainer();
    }

    handleAddRow(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;

        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.push(
            {
                fieldIndex: this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.length,
                isLabelEdit: false,
                fieldClass:"field"+this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.length,
                customlabel: "",
                isField:true,
                isRichTextBox:false,
                fieldData: {}
            }
        )
        this.sendPagesDataToContainer();
    }

    handlePageLabelEdit(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.pages[this.currentPagePos].isLabelEdit = true;
        this.sendPagesDataToContainer();
    }

    handlePageLabelEditDone(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.pages[this.currentPagePos].pageName = event.detail.newLabel;
        this.pages[this.currentPagePos].isLabelEdit = false;
        this.sendPagesDataToContainer();
    }

    handleSectionLabelEdit(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.pages[this.currentPagePos].sections[this.currentSectionPos].isLabelEdit = true;
        this.sendPagesDataToContainer();
    }

    handleSectionLabelEditDone(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;

        this.pages[this.currentPagePos].sections[this.currentSectionPos].sectionName = event.detail.newLabel;
        this.pages[this.currentPagePos].sections[this.currentSectionPos].isLabelEdit = false;
        this.sendPagesDataToContainer();
    }

    handleSectionDelete(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        console.log('del section >> '+JSON.stringify(this.pages[this.currentPagePos].sections[this.currentSectionPos]));
        if(!this.pages[this.currentPagePos].sections[this.currentSectionPos].isSectionMulti){
            if (this.pages[this.currentPagePos].sections.length > 1) {
                if (this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.findIndex(field => field.fieldData.fieldName) !== -1) {
                    alert("This section cannot be deleted as it has fields, please delete/clear all the fields before deleting the section.");
                } else {
                    var confirmation = confirm("Are you sure you want to delete this Section?\nPress OK to delete.");
                    if (confirmation == true) {
                        this.pages[this.currentPagePos].sections.splice(this.currentSectionPos, 1);
                        this.refreshIndexes();
                        this.sendPagesDataToContainer();
                    }
                }
            }
        }else{
            if(this.pages[this.currentPagePos].sections[this.currentSectionPos].isQuestionsOnly){
                if (this.pages[this.currentPagePos].sections.length > 1) {
                    if (this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.findIndex(field => field.fieldData.fieldName) !== -1) {
                        alert("This section cannot be deleted as it has fields, please delete/clear all the fields before deleting the section.");
                    } else {
                        var confirmation = confirm("Are you sure you want to delete this Section?\nPress OK to delete.");
                        if (confirmation == true) {
                            this.pages[this.currentPagePos].sections.splice(this.currentSectionPos, 1);
                            this.refreshIndexes();
                            this.sendPagesDataToContainer();
                        }
                    }
                }
            }else{
                alert("Multi-records selctions cannot be deleted.");
            }
        }
    }

    handlePageDelete(event) {
        this.currentPagePos = event.detail.pageIndex;
        if (this.pages.length > 1) {
            let hasReq = false;
            if (this.pages[this.currentPagePos].sections) {
                this.pages[this.currentPagePos].sections.forEach(section => {
                    if (section.fields) {
                        if (section.fields.findIndex(field => field.fieldData.fieldName) !== -1) hasReq = true;
                    }
                })
            }
            if (hasReq) {
                alert("This page cannot be deleted as it has fields, please delete/clear all the fields before deleting the page.");
            } else {
                var confirmation = confirm("Are you sure you want to delete this Page?\nPress OK to delete.");
                if (confirmation == true) {
                    this.pages.splice(this.currentPagePos, 1);
                    this.refreshIndexes();
                    this.sendPagesDataToContainer();
                }
            }
        }
    }

    handleFieldLabelEdit(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = parseInt(event.detail.fieldIndex);

        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.isLabelEdit = true;

        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.customlabel = this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.customlabel == "" ? this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.fieldName : this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.customlabel;

        this.pages = JSON.parse(JSON.stringify(this.pages));
        this.sendPagesDataToContainer();
    }

    handleFieldLabelChange(event) {
        if(event.detail.newLabel === this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.fieldName){
            this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.customlabel = "";
        }else{
            this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.customlabel = event.detail.newLabel;
        }
        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.isLabelEdit = false;
        this.sendPagesDataToContainer();
    }

    handleRichTextContent(event){
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;
        let content = event.detail.content;
        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].content = content;
    }

    closeModal() {
        this.openEditLabelModal = false;
    }

    handleClear(event) {
        console.log("here");
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;
        

        this.replaceFieldInFieldList(this.currentPagePos,this.currentSectionPos,this.currentFieldPos);
        console.log("here >> ",JSON.stringify(this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos]));
        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData = [];
        if(this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].isRichTextBox){
            this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].isRichTextBox = false;
        }

        this.refreshIndexes();
        this.sendPagesDataToContainer();
    }

    handleDelete(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;
        //console.log('here >> '+this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.length);

        if(this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.length == 1 && this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData){
            this.handleClear(event);
        }else{
            if(this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos] && this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData){
                this.replaceFieldInFieldList(this.currentPagePos,this.currentSectionPos,this.currentFieldPos);
            }
    
            if (this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.length > 1) {
                this.pages[this.currentPagePos].sections[this.currentSectionPos].fields.splice(this.currentFieldPos, 1);
            }
            this.refreshIndexes();
            this.sendPagesDataToContainer();
        }
    }

    replaceFieldInFieldList(pagePos, sectionPos, fieldPos){
        let fieldieldObjName = this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.objectName;
        let fieldUniqueName = this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData.fieldUniqueName;

        this.fieldList.forEach(obj => {
            if (obj.objectUniqueName && (fieldieldObjName == obj.objectUniqueName)) {
                if (obj.fields.findIndex(j => j.fieldUniqueName == fieldUniqueName) == -1) {
                    obj.fields.push(this.pages[pagePos].sections[sectionPos].fields[fieldPos].fieldData);
                }
            }
            obj.fields.sort(this.sortFieldList);
        })
    }

    handleRequired(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;

        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.required = event.detail.isRequired;
        this.sendPagesDataToContainer();
    }

    handleFieldHelpText(event) {
        this.currentPagePos = event.detail.pageIndex;
        this.currentSectionPos = event.detail.sectionIndex;
        this.currentFieldPos = event.detail.fieldIndex;

        this.pages[this.currentPagePos].sections[this.currentSectionPos].fields[this.currentFieldPos].fieldData.helpText = event.detail.helpText;
        this.sendPagesDataToContainer();
    }

    handleFieldSearch(event) {
        this.searchText = event.target.value;
        let newArr = [];

        this.unfilteredFieldList.forEach(unfilteredObj => {
            let tempOutput = unfilteredObj.fields.filter(field => field.fieldName.toLowerCase().includes(this.searchText.toLowerCase()));
            let newObj = {};
            newObj.objectName = unfilteredObj.objectName;
            newObj.isChild = unfilteredObj.isChild;
            newObj.isMulti = unfilteredObj.isMulti;
            newObj.objectUniqueName = unfilteredObj.objectUniqueName;
            newObj.fields = tempOutput.length ? tempOutput : [];
            newArr.push(newObj);
        })
        this.fieldList = newArr;
    }

    sortFieldList(a, b) {
        if (a.fieldName < b.fieldName) {
            return -1;
        }
        if (a.fieldName > b.fieldName) {
            return 1;
        }
        return 0;
    }

    swap(a,b){
        [a,b] = [b,a];
    }

    sendPagesDataToContainer() {
        this.dispatchEvent(new CustomEvent('pagesdata',
        {
            detail: [this.pages,this.fieldList]
        }));

        console.log('pagesdata  >> '+JSON.stringify(this.pages));
    }
}