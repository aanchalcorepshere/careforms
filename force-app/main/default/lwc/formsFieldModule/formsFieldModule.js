import { LightningElement, api, track } from 'lwc';

export default class FormsFieldModule extends LightningElement {
    @api field;
    @api fieldIndex;
    @api sectionIndex;
    @api pageIndex;
    @api object;
    openHelpTextModal = false;
    helpText;
    //@track options=[];

    disabled = true;

    renderedCallback(){
        if(this.field.isLabelEdit){
            let input = this.template.querySelector('input');
            input.select();
        }
    }

    get fieldString(){
        return JSON.stringify(this.field);
    }

    get options() {
        return [
            { label: 'New', value: 'new' },
            { label: 'In Progress', value: 'inProgress' },
            { label: 'Finished', value: 'finished' },
        ];
    }

    get checkboxOptions() {
        return [
            { label: 'True', value: 'true' },
            { label: 'False', value: 'false' }
        ];
    }

    get fieldSequence(){
        return this.field.fieldIndex+1;
    }

    get isText() {
        return (this.field.dataType == "STRING" || this.field.dataType == "PHONE" || this.field.dataType == "CURRENCY" || this.field.dataType == "EMAIL" || this.field.dataType == "URL" || this.field.dataType == "REFERENCE");
    }

    get isTextarea() {
        return this.field.dataType == "TEXTAREA";
    }

    get isNumber() {
        return (this.field.dataType == "DOUBLE" || this.field.dataType == "INTEGER");
    }

    get isPicklist() {
        return this.field.dataType == "PICKLIST";
    }

    get isMultiPicklist(){
        return this.field.dataType == "MULTIPICKLIST";
    }

    get isDate() {
        return (this.field.dataType == "DATE" || this.field.dataType == "DATETIME");
    }

    get isBoolean() {
        return this.field.dataType == "BOOLEAN";
    }

    get isCheckbox() {
        return this.field.dataType == "CHECKBOX";
    }

    get isRadiobox() {
        return this.field.dataType == "RADIOBOX";
    }

    get label() {
        if (this.field.objectName == 'Question') {
            return this.field.fieldName + ' (Question)';
        } else {
            //return this.field.customlabel == "" ? this.field.fieldName + " (" + this.field.fieldApi + ":" + this.field.objectName + ") " : this.field.customlabel;
            return this.field.customlabel == "" ? this.field.fieldName : this.field.customlabel;
        }
    }

    get helptext(){
        return " (" + this.field.fieldApi + ":" + this.field.objectName + ") ";
    }

    handleLabelChange(event) {
        let newLabel = event.target.value;
        this.dispatchEvent(new CustomEvent('fieldlabelchange',
        {
            bubbles: true, composed: true, detail: {
                fieldIndex: this.fieldIndex,
                sectionIndex:this.sectionIndex,
                pageIndex:this.pageIndex,
                newLabel: newLabel
            }
        }));
    }

    handleRequired(event) {
        let isRequired = event.target.checked;
        this.dispatchEvent(new CustomEvent('fieldrequired',
        {
            bubbles: true, composed: true, detail: {
                fieldIndex: this.fieldIndex,
                sectionIndex:this.sectionIndex,
                pageIndex:this.pageIndex,
                isRequired: isRequired
            }
        }));
    }

    handleHelpTextModal(){
        this.openHelpTextModal = true;
    }

    handleHelpText(event){
        this.helpText = event.target.value;
    }

    closeModal(){
        this.openHelpTextModal = false;
    }

    saveHelpText(){
        this.dispatchEvent(new CustomEvent('updatehelptext',
        {
            bubbles: true, composed: true, detail: {
                fieldIndex: this.fieldIndex,
                sectionIndex:this.sectionIndex,
                pageIndex:this.pageIndex,
                helpText: this.helpText
            }
        }));
        this.openHelpTextModal = false;
    }

    handleLabelClick(event){
        event.target.select();
    }

}