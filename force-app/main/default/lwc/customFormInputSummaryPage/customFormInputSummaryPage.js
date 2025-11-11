import { LightningElement, api } from 'lwc';

export default class CustomFormInputSummaryPage extends LightningElement {
    isSummary = true;
    @api pageData;
    @api uploadedDocuments;
    @api forPrint = false;
    sectionWidth;
    @api recordId;
    @api isPrefillFieldsForm;
    @api forSignature;
    @api signatureFieldApi;
    @api signatureFieldIndex;
    @api signaturePageIndex;
    @api signatureSectionIndex;
    @api additionalFields;

    connectedCallback(){
        console.log('uploadedDocuments >> '+JSON.stringify(this.uploadedDocuments));
        if(this.forPrint){
            this.sectionWidth = 'slds-col slds-size_12-of-12';
        }else{
            this.sectionWidth = 'slds-col slds-size_11-of-12';
        }
    }

    handleEdit(event){
        let pageIndex = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('editpage',
        {
            detail: pageIndex
        }));
    }
}