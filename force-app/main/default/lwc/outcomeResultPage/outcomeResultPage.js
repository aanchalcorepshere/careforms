import { LightningElement, api } from 'lwc';

export default class OutcomeResultPage extends LightningElement {

    @api outcomeId;
    @api objectName;

    seeContent(){
        /* let outcomehtml = this.template.querySelector('.resultpage');
        console.log("outcomehtml >> ",JSON.stringify(outcomehtml.outerHTML)); */
        window.print();
    }
}