import { LightningElement, track, api } from 'lwc';

export default class CreateSections extends LightningElement {

    @api isSubmit;
    keyIndex = 0;
    order = 1;
    localEditData;
    //@api existingSections;
    @track sectionList = [
        {
            id: 0,
            serial : 1,
            secName : '',
            showDelete : false
        }
    ];

    /* connectedCallback(){
        if(this.existingSections && this.existingSections.length){
            this.sectionList = JSON.parse(JSON.stringify(this.existingSections));
        }
    } */

    @api
    get existingSections() {
        return this.sectionList;
    }

    set existingSections(value) {
        if(value){
            //console.log("this.previousData >> ",JSON.stringify(value));
            this.sectionList = JSON.parse(JSON.stringify(value));
        }
    }

    addRow() {
        ++this.keyIndex;
        this.order = this.sectionList.length+1;
        var newItem = [{ id: this.keyIndex, serial : this.order, secName : '', showDelete : true }];
        this.sectionList = this.sectionList.concat(newItem);
        this.dispatchEvent(new CustomEvent('sectiondetails', {
            detail: this.sectionList
        }));
    }

    

    removeRow(event) {
        let remPos = event.target.accessKey;
        if (remPos > -1 && remPos!=0) {
            this.sectionList.splice(remPos, 1);
            this.resetSeq();
        }
        this.dispatchEvent(new CustomEvent('sectiondetails', {
            detail: this.sectionList
        }));
    }

    resetSeq(){
        let count = 0;
        this.sectionList.forEach(section => {
            section.id = count;
            section.serial = count+1;
            count++;
        })
    }

    handleInput(event){
        let serial = event.target.dataset.secSerial;
        this.sectionList[serial-1].secName = event.target.value;
        this.dispatchEvent(new CustomEvent('sectiondetails', {
            detail: this.sectionList
        }));
    }
}