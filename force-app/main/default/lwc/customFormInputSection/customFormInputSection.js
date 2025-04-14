import { LightningElement, api, wire } from 'lwc';

export default class CustomFormInputSection extends LightningElement {
    @api section;
    @api pageIndex;
    initialFieldCount = 0;

    @api isSummary = false;

    @api recordId;
    @api isPrefillFieldsForm;

    connectedCallback(){
        
    }

    get size(){
        //return this.section.columns == 2?6:12;
        return this.section.columns;
    }

    get showSectionHeader(){
        return (this.section.sectionName.length > 0);
    }

    /* get showAddAnother(){
        return (this.isApplicationForm || this.isCopyApplication);
    } */

    get hideSection(){
        let hide = true;
        //console.log('section >> ',JSON.stringify(this.section));
        if(this.section && !this.section.isSectionMulti){
            if(this.section.fields && this.section.fields.length){
                this.section.fields.forEach(field => {
                    if(field.isRichTextBox){
                        hide =  false;
                    }else if(field.isField){
                        //console.log('field.fieldData.hide >> ',field.fieldData.hide);
                        if(!field.fieldData.hide){
                            hide = false;
                        }
                    }
                })
            }
            return hide;
        }else{
            return false;
        }
    }

    handleAddRecord(){

        this.dispatchEvent(new CustomEvent('addrow',
        {
            detail: {
                pageIndex:this.pageIndex,
                sectionIndex:this.section.sectionIndex
            }
        }));

        //console.log('section >> '+JSON.stringify(this.section));
    }

    handleDeleteRecord(event){
        this.currentRecordIndex = event.currentTarget.dataset.id;

        this.dispatchEvent(new CustomEvent('deleterow',
        {
            detail: {
                pageIndex:this.pageIndex,
                sectionIndex:this.section.sectionIndex,
                recordIndex : this.currentRecordIndex
            }
        }));
    }
}