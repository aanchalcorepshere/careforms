import { LightningElement, api, track } from 'lwc';

export default class FormsSectionModule extends LightningElement {
    @track localsection;
    @track value;
    @track size = 12;

    @api section;
    @api pageIndex;
    isSectionDragFromPageModule = false;
    isFieldDrag = true;

    @track columnOptions = [
        {label:"1", value:12, selected:true},
        {label:"2", value:6, selected:false},
        {label:"3", value:4, selected:false},
        {label:"4", value:3, selected:false},
        {label:"6", value:2, selected:false}
    ]

    //@api isSectionDrag = false;

    get options() {
        return columnOptions;
    }

    /* @api
    callGetOptions(){
        let fields = this.template.querySelectorAll('c-forms-field-module');
        if(fields){
            fields.forEach(field => {
                field.getQuestionOptions();
            })
        }
    } */

    connectedCallback(){
        this.size = this.section.columns;
        console.log('this.size >> ',this.size);
        console.log('type of >> ',typeof this.size);
        this.columnOptions.forEach(option => {
            if(option.value == parseInt(this.size)){
                option.selected = true;
            }else{
                option.selected = false;
            }
        })
        /* if(this.section.columns == 1){
            this.size = 12;
            this.value = false;
        }else{
            this.size = 6;
            this.value = true;
        } */
    }
    
    renderedCallback(){
        if(this.section.isLabelEdit){
            let inputs = this.template.querySelectorAll('input');
            if(inputs && inputs.length){
                inputs.forEach(input => {
                    input.select();
                })
            }
        }
    }
    
    @api
    get isSectionDrag() {
        return this.isSectionDragFromPageModule;
    }

    set isSectionDrag(value) {
       this.isSectionDragFromPageModule = value;
       if(this.isSectionDragFromPageModule){
        this.isFieldDrag = false;
       }
    }

    handleColumns(event) {
        this.size = event.target.value;
        /* if (event.target.checked) {
            this.size = 6;
            this.value = true;
        } else {
            this.size = 12;
            this.value = false;
        } */

        this.dispatchEvent(new CustomEvent('columnchange',
            {
                bubbles: true, composed: true, detail:
                {
                    sectionIndex: this.section.sectionIndex,
                    pageIndex: this.pageIndex,
                    columns: this.size
                }
            }));
    }

    addCell(event) {
        this.dispatchEvent(new CustomEvent('addrow',
        {
            bubbles: true, composed: true, detail:
            {
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
                columns: this.size
            }
        }));
    }

    /**
     * Drag drop events start
     */

    handleDragOver(event) {
        //console.log("this.isSectionDrag >> ",this.isSectionDrag);
        //if(this.isFieldDrag){
            this.cancel(event);
            let currentElement = event.currentTarget.dataset.id;
            if (!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains("drop-zone")) {
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add("drop-zone");
            }
        //}
    }

    handleDragEnter(event) {
        //if(this.isFieldDrag){
            this.cancel(event);
        //}
    }

    handleFieldMouseDown(event){
        console.log('mouse down on field');
        this.dispatchEvent(new CustomEvent('fielddragstarted'));
        event.stopPropagation();
    }

    handleDragLeave(event) {
        //if(this.isFieldDrag){
            this.cancel(event);
            let currentElement = event.currentTarget.dataset.id;
            if (this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains("drop-zone")) {
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.remove("drop-zone");
            }
        //}
    }

    handleDrop(event) {
        //if(this.isFieldDrag){
            let currentElement = event.currentTarget.dataset.id;
            this.dispatchEvent(new CustomEvent('currentdropzone',
                {
                    bubbles: true, composed: true, detail:
                    {
                        sectionIndex: this.section.sectionIndex,
                        pageIndex: this.pageIndex,
                        fieldIndex: currentElement
                    }
                }));

            this.template.querySelector(`[data-id="${currentElement}"]`).classList.remove("drop-zone");
        //}
    }

    cancel(event) {
        if (event.stopPropagation) event.stopPropagation();
        if (event.preventDefault) event.preventDefault();
        return false;
    };

    handleDragStart(event){
        this.isFieldDrag = true;
        this.isSectionDragFromPageModule = false;
        let draggedElement = event.currentTarget.dataset.id;
        console.log("field draggedElement >>> ",draggedElement);
        this.dispatchEvent(new CustomEvent('localdragstart',
        {
            bubbles: true, composed: true, detail: {
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
                fieldIndex: draggedElement,
                sectionDrag:false
            }
        }));
    }

    /**
     * Drag drop events end
     */

    handleFieldLabelEdit(event) {
        let currentElement = event.currentTarget.dataset.id;
        console.log('currentElement >> ',currentElement);
        this.dispatchEvent(new CustomEvent('fieldlabeledit',
        {
            bubbles: true, composed: true, detail: {
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
                fieldIndex: currentElement
            }
        }));
    }

    handleSectionLabelEdit() {
        console.log("1");
        this.dispatchEvent(new CustomEvent('sectionlabeledit',
            {
                bubbles: true, composed: true, detail:
                {
                    sectionIndex: this.section.sectionIndex,
                    pageIndex : this.pageIndex,
                    eventName: 'sectionlabeledit'
                }
            }));
    }

    handleSectionLabelEditDone(event) {
        let label = event.target.value;
        this.dispatchEvent(new CustomEvent('sectionlabeleditdone',
            {
                bubbles: true, composed: true, detail:
                {
                    newLabel: label,
                    sectionIndex: this.section.sectionIndex,
                    pageIndex : this.pageIndex,
                    eventName: 'sectionlabeleditdone'
                }
            }));
    }

    handleClear(event) {
        console.log("data id >> ", event.currentTarget.dataset.id);
        this.dispatchEvent(new CustomEvent('clearfield',
            {
                bubbles: true, composed: true, detail:
                {
                    fieldIndex: event.currentTarget.dataset.id,
                    sectionIndex: this.section.sectionIndex,
                    pageIndex: this.pageIndex,
                    eventName: 'clearfield'
                }
            }));
    }

    handleDelete(event) {
        this.dispatchEvent(new CustomEvent('deletefield',{
            bubbles: true, composed: true, detail:
            {
                fieldIndex: event.currentTarget.dataset.id,
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
                eventName: 'deletefield'
            }
        }));
    }

    handleRichTextContent(event){
        this.dispatchEvent(new CustomEvent('richtextcontent',{
            bubbles: true, composed: true, detail:
            {
                fieldIndex: event.currentTarget.dataset.id,
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
                content: event.target.value,
                eventName: 'richtextcontent'
            }
        }));
    }

    handleSectionDelete(){
        this.dispatchEvent(new CustomEvent('deletesection',{
            bubbles: true, composed: true, detail:
            {
                sectionIndex: this.section.sectionIndex,
                pageIndex: this.pageIndex,
            }
        }));
    }
}