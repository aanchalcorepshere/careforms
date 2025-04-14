import { LightningElement, track, wire, api } from 'lwc';
import getAllQuestions from '@salesforce/apex/QuestionsController.getAllQuestions';
import deleteQuestion from '@salesforce/apex/QuestionsController.deleteQuestion';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import QUESTION_OBJECT from "@salesforce/schema/Question__c";
import checkEditable from '@salesforce/apex/CreateNewQuestionCtrl.checkEditable';

import ID_FIELD from "@salesforce/schema/Question__c.Id";
import ACTIVE_FIELD from "@salesforce/schema/Question__c.Active__c";
import { updateRecord } from "lightning/uiRecordApi";

export default class Questions extends LightningElement {

    @track questions;
    unfilteredQuestions;
    wiredQuestionsData;
    error;
    isEditModalOpen=false;
    isNewModalOpen=false;
    isDeleteModalOpen=false;
    deleteRecId;
    editRecId;
    @api active;
    editError = 'This Question Answer Option cannot be edited.';
    showEditError = false;

    connectedCallback(){
        refreshApex(this.wiredQuestionsData);
    }

    @wire(getAllQuestions, {active : '$active'})
    wiredQuestions(result){
        this.wiredQuestionsData = result;
        if(result.data){
            this.questions = result.data;
            this.unfilteredQuestions = result.data;
            this.error = undefined;
            console.log("Questions # ", JSON.stringify(this.questions));
        }else if(result.error){
            this.error = result.error;
            this.questions = undefined;
        }
    }

    handleEditError(){
        console.log("event recieved");
        this.isNewModalOpen = false;
        /* this.showEditError = true;
        setTimeout(() => {this.showEditError = false;}, 3000); */
        const event = new ShowToastEvent({
            title: 'Error',
            message: this.editError,
            variant:'error',
            mode:'dismissible'
        });
        this.dispatchEvent(event);
        
    }

    handleAction(event){
        var action = event.detail.value;
        let quesId = event.target.getAttribute("data-id");
        if(action === 'Delete'){
            this.isDeleteModalOpen = true;
            this.deleteRecId = quesId;
        }else if(action === "Edit"){
            checkEditable({recId : this.editRecId})
            .then(result => {
                let editable = result;
                console.log("editable >> ",editable);
                if(editable){
                    this.isNewModalOpen = true;
                    this.editRecId = quesId;
                }else{
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'This Question Answer Option cannot be edited.',
                        variant:'error',
                        mode:'dismissible'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch(error=>{
                console.error("Error >>> ",error);
                console.error("Error >>> ",JSON.stringify(error));
                this.error = JSON.stringify(error);
            })
        }else if(action === "De-activate"){
            this.editRecId = quesId;
            checkEditable({recId : this.editRecId})
            .then(result => {
                let editable = result;
                if(editable){
                    const fields = {};

                    fields[ID_FIELD.fieldApiName] = this.editRecId;
                    fields[ACTIVE_FIELD.fieldApiName] = false;
                    const recordInput = {
                        fields: fields
                    };
                
                        //6. Invoke the method updateRecord()
                    updateRecord(recordInput).then((record) => {
                        refreshApex(this.wiredQuestionsData);
                    });
                }else{
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'This Question Answer Option cannot be de-activated.',
                        variant:'error',
                        mode:'dismissible'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch(error=>{
                console.error("Error >> ",JSON.stringify(error));
                this.error = JSON.stringify(error);
            })

        }else if(action === "Activate"){
            this.editRecId = quesId;
            const fields = {};

            fields[ID_FIELD.fieldApiName] = this.editRecId;
            fields[ACTIVE_FIELD.fieldApiName] = true;
            const recordInput = {
                fields: fields
            };
          
                  //6. Invoke the method updateRecord()
            updateRecord(recordInput).then((record) => {
                refreshApex(this.wiredQuestionsData);
            });
        }
    }

    get isEdit(){
        return this.editRecId?true:false;
    }

    get activeButton(){
        return this.active=="true"?"De-activate":"Activate";
    }

    @api
    handleNewAction(event){
        this.editRecId = undefined;
        this.isNewModalOpen = true;
    }

    handleDeleteAction(){
        checkEditable({recId : this.deleteRecId})
        .then(result => {
            let editable = result;
            console.log('editable>>> ' + editable);
            if(editable){
                deleteQuestion({questionId : this.deleteRecId})
                .then(result => {
                    this.isDeleteModalOpen = false;
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Question deleted successfully.',
                        variant:'success',
                        mode:'dismissible'
                    });
                    this.dispatchEvent(event);
                    refreshApex(this.wiredQuestionsData);
                })
                .catch(error => {
                    console.error("Error ==> ",JSON.stringify(error));
                    this.error = JSON.stringify(error);
                })
            }else{
                this.isDeleteModalOpen = false;
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'This Question Answer Option cannot be deleted.',
                    variant:'error',
                    mode:'dismissible'
                });
                this.dispatchEvent(event);
            }
        })
        .catch(error => {
            console.error("Error ==> ",JSON.stringify(error));
            this.error = JSON.stringify(error);
        })
    }

    closeModal(){
        this.isDeleteModalOpen = false;
        this.isNewModalOpen = false;
    }

    handleQuestionSave(event){
        this.isNewModalOpen = false;
        refreshApex(this.wiredQuestionsData);
    }

    @api
    handleSearch(searchText){
        var searchTerm = searchText;
        this.questions = this.unfilteredQuestions.filter(function (obj) {
            return obj.caresp__Question_Text__c.toLowerCase().includes(searchTerm.toLowerCase());
        });
    }
}