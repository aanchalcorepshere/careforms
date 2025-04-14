import { LightningElement, api } from 'lwc';

export default class FormsSignaturePage extends LightningElement {

    @api existingSignature;
    //signatureData;
    @api requiresTextOnSignaturePage;
    @api signaturePageText;
    theSignature;

    handleSignature(event){
        this.dispatchEvent(new CustomEvent('uploadsignature',{
            detail: event.detail
        }));
    }

    connectedCallback(){
        //console.log('from signature page >> '+JSON.stringify(this.signatureData));
    }
}