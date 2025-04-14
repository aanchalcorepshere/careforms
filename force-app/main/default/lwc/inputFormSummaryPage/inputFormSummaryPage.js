import { LightningElement, api } from 'lwc';

export default class InputFormSummaryPage extends LightningElement {
    isSummary = true;
    @api pageData;
    @api uploadedDocuments;

    connectedCallback(){
        console.log('pageData >> ',JSON.stringify(this.pageData));
    }

    handleEdit(event){
        let pageIndex = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('editpage',
        {
            detail: pageIndex
        }));
    }
}