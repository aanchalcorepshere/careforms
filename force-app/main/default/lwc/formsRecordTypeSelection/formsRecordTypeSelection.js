import { LightningElement, api } from 'lwc';

export default class FormsRecordTypeSelection extends LightningElement {
    @api recordTypeOptions;
    @api level;
    @api sourceObject;
    @api parent;
    selectedRecordType;
    selectedRecordTypeLabel;

    //Once the record type is selected below function will send the data to 'formsObjectStructureScreen' component with information about object selected.
    handleRecordTypeChange(event){
        this.selectedRecordType = event.target.value;
        this.selectedRecordTypeLabel = event.target.options.find(opt => opt.value === event.detail.value).label;

        this.dispatchEvent(new CustomEvent('selectrecordtype',
        {
            detail: {
                selectedRecordType:this.selectedRecordType,
                selectedRecordTypeLabel : this.selectedRecordTypeLabel,
                level : this.level,
                parent : this.parent,
                objectId : this.sourceObject
            }
        }));
    }
}