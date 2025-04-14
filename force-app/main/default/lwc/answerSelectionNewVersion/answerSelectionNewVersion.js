import { LightningElement, track, api, wire } from 'lwc';
import getActiveAnswers from '@salesforce/apex/AnswerSelectionController.getActiveAnswers';
import {refreshApex} from '@salesforce/apex';
import ContactMobile from '@salesforce/schema/Case.ContactMobile';

export default class AnswerSelectionNewVersion extends LightningElement {
    
    
    @track indexNo;
    @api existingAnswers=[];
    unfilteredAnswers;
    searchText;
    @api isEdit = false;
    error;
    wiredAnswersData;
    @track savedAnswer;
    answerError;
    flagForAnsText = true;

    dropZone;
    draggedElementId;
    selectedAnsForSort;
    @track selectedAnswers = [];
    @track answerList;
    
    @wire(getActiveAnswers, { searchTerm: '' })
    wiredAnswers(result) {    
        
        this.wiredAnswersData = result 
        if (result.data) {
            this.answerList = JSON.parse(JSON.stringify(result.data));
            this.error = undefined;
            if(this.answerList && this.answerList.length){
                this.answerList.forEach(ans => {
                    ans.unique = 'source_'+ans.Id;
                });
                this.unfilteredAnswers = JSON.parse(JSON.stringify(this.answerList));
            }
            if(this.isEdit){
                this.selectedAnswers = this.proxyToObj(this.existingAnswers);
                if(this.selectedAnswers && this.selectedAnswers.length){
                    this.selectedAnswers.forEach(ans => {
                        ans.unique = 'destination_'+ans.Id;
                    });
                }
            }
            if(this.selectedAnswers && this.selectedAnswers.length){
                this.selectedAnswers.forEach(ans => {
                    this.unfilteredAnswers = this.unfilteredAnswers.filter(function (obj) {
                        return obj.Id !== ans.Id;
                    });
                    this.answerList = this.answerList.filter(function (obj) {
                        return obj.Id !== ans.Id;
                    });
                });
            }
        } else if (result.error) {
            this.error = result.error;
            this.answerList = undefined;
        }
        console.log("this.selectedAnswers >> ",JSON.stringify(this.selectedAnswers));
    }

    proxyToObj(obj){
        return JSON.parse(JSON.stringify(obj));
    }

    swapArrayElements = function (arr, indexA, indexB) {
        let cutOut = arr.splice(indexA, 1)[0];
        arr.splice(indexB, 0, cutOut);
        for (var i = 0; i < arr.length; i++) {
            arr[i].order = i + 1;
        }
    };

    handleDragStart(event){
        this.draggedElementId = event.currentTarget.dataset.id;
        console.log("draggedElementId >> ",this.draggedElementId);
    }

    handleDragEnd(event){
        event.preventDefault();   
    }

    handleDragLeave(event){
        event.preventDefault();
        let currentElement = event.currentTarget.dataset.id;
        console.log("currentElement >> ",JSON.stringify(currentElement));
        if(currentElement){
            if(this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('over')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.remove('over');
            }
            if(this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('slds-drop-zone')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.remove('slds-drop-zone');
            }
        }
    }

    handleDragEnter(event){
        event.preventDefault();
        let currentElement = event.currentTarget.dataset.id;
        console.log("currentElement >> ",JSON.stringify(currentElement));
        if(currentElement){
            if(!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('over')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add('over');
            }
            if(!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('slds-drop-zone')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add('slds-drop-zone');
            }
        }
    }

    handleDragOver(event){
        event.preventDefault();
        let currentElement = event.currentTarget.dataset.id;
        console.log("currentElement >> ",JSON.stringify(currentElement));
        if(currentElement){
            if(!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('over')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add('over');
            }
            if(!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains('slds-drop-zone')){
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add('slds-drop-zone');
            }
        }
    }

    handleDrop(event){
        event.preventDefault();
        event.stopPropagation();
        this.dropZone = event.currentTarget.dataset.id;
        console.log("dropZone >> ",this.dropZone);
        console.log("draggedElementId >> ",this.draggedElementId);

        if(this.draggedElementId.indexOf("source") > -1 && this.dropZone == "selectedAnswers"){
            let draggedPos = this.answerList.findIndex(ans => ans.unique == this.draggedElementId);
            if(this.selectedAnswers.findIndex(selAns => selAns.Id == this.answerList[draggedPos].Id) == -1){
                let temp = {};
                temp.Id = this.answerList[draggedPos].Id;
                temp.caresp__Answer_Text__c = this.answerList[draggedPos].caresp__Answer_Text__c;
                temp.unique = this.answerList[draggedPos].unique.replace("source","destination");
                temp.order = this.selectedAnswers.length+1;
                this.selectedAnswers.push(temp);
                this.answerList.splice(draggedPos,1);
                this.unfilteredAnswers.splice(this.unfilteredAnswers.findIndex(ans => ans.unique == this.draggedElementId),1);
            }
        }else if(this.draggedElementId.indexOf("destination") > -1 && this.dropZone == "ansList"){
            let draggedPos = this.selectedAnswers.findIndex(ans => ans.unique == this.draggedElementId);
            if(this.answerList.findIndex(selAns => selAns.Id == this.selectedAnswers[draggedPos].Id) == -1){
                let temp = {};
                temp.Id = this.selectedAnswers[draggedPos].Id;
                temp.caresp__Answer_Text__c = this.selectedAnswers[draggedPos].caresp__Answer_Text__c;
                temp.unique = this.selectedAnswers[draggedPos].unique.replace("destination","source");
                //temp.order = this.answerList.length+1;
                this.answerList.push(temp);
                this.unfilteredAnswers = JSON.parse(JSON.stringify(this.answerList));
                this.selectedAnswers.splice(draggedPos,1);
                if(this.selectedAnswers.length){
                    let newOrder = 1;
                    this.selectedAnswers.forEach(ans => {
                        ans.order = newOrder;
                        newOrder++;
                    })
                }
            }
        }

        console.log("this.dropZone >> ",JSON.stringify(this.dropZone));

        if(this.dropZone && this.template.querySelector(`[data-id="${this.dropZone}"]`).classList.contains('over')){
            this.template.querySelector(`[data-id="${this.dropZone}"]`).classList.remove('over');
        }
        if(this.dropZone && this.template.querySelector(`[data-id="${this.dropZone}"]`).classList.contains('slds-drop-zone')){
            this.template.querySelector(`[data-id="${this.dropZone}"]`).classList.remove('slds-drop-zone');
        }

        this.dispatchEvent(new CustomEvent('answerselected', {detail:this.selectedAnswers}));
    }

    toggleSelection(event){
        this.selectedAnsForSort = event.currentTarget.dataset.id;
        let selectedAns = this.template.querySelector(`[data-id="${this.selectedAnsForSort}"]`);
        if(!selectedAns.classList.contains("sortselect")){
            selectedAns.classList.add("sortselect");
            let elements = this.template.querySelectorAll(".sortselect");
            if(elements && elements.length){
                elements.forEach(elem => {
                    console.log(elem.dataset.id);
                    if(elem.dataset.id != this.selectedAnsForSort){
                        elem.classList.remove("sortselect");
                    }
                })
            }
        }else{
            selectedAns.classList.remove("sortselect");
            this.selectedAnsForSort = undefined;
        }
    }

    handleSort(event){
        if(this.selectedAnsForSort){
            let buttonName = event.target.name;
            let pos = this.selectedAnswers.findIndex(ans => ans.unique == this.selectedAnsForSort);
            if(buttonName == "up"){
                if(pos > 0){
                    [this.selectedAnswers[pos-1], this.selectedAnswers[pos]] = [this.selectedAnswers[pos], this.selectedAnswers[pos-1]];
                    if(this.selectedAnswers.length){
                        let newOrder = 1;
                        this.selectedAnswers.forEach(ans => {
                            ans.order = newOrder;
                            newOrder++;
                        })
                    }
                }
            }else{
                if(pos < this.selectedAnswers.length-1){
                    [this.selectedAnswers[pos], this.selectedAnswers[pos+1]] = [this.selectedAnswers[pos+1], this.selectedAnswers[pos]];
                    if(this.selectedAnswers.length){
                        let newOrder = 1;
                        this.selectedAnswers.forEach(ans => {
                            ans.order = newOrder;
                            newOrder++;
                        })
                    }
                }
            }
        }

        this.dispatchEvent(new CustomEvent('answerselected', {detail:this.selectedAnswers}));
    }

    handleChange(event){
        this.searchText = event.target.value;
        var s = this.searchText;
        this.answerList = this.unfilteredAnswers.filter(function (obj) {
            return obj.caresp__Answer_Text__c.toLowerCase().startsWith(s.toLowerCase());
        });
    }
    // code to add additional answer options in case of picklist - START
    @track ansText;
    @api selectedDataType;
    
    get isPicklist(){
        if((this.selectedDataType == 'Picklist') || (this.selectedDataType == 'Radio Box') || (this.selectedDataType == 'Checkbox')){
            return true;
        }
        else{
            return false;
        }
    }
    
    handleAnswerSubmit(event){
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        if(!fields.caresp__Answer_Text__c){
            this.answerError = 'Answer Text cannot be blank.';
        }else{
            if(!fields.caresp__Answer_Text__c.replace(/\s/g, '').length){
                this.answerError = 'Answer Text cannot be blank.';
            }else{
                this.template.querySelector('lightning-record-edit-form').submit(fields);
            }
        }
    }

    handleAnswerSuccess(event){
        if(event.detail.id){
            this.savedAnswer = "";
            this.flagForAnsText = false;
            setTimeout(() => {this.flagForAnsText = true}, 100);
            this.answerError = undefined;
            refreshApex(this.wiredAnswersData);
        }
    }

    handleAnswerError(event){
        if(event.detail){
            this.answerError = JSON.stringify(event.detail.detail);
            this.answerError = this.answerError.replaceAll('"','');
        }else{
            this.answerError = undefined;
        }
    }
}