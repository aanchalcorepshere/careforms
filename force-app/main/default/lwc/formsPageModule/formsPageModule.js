import { LightningElement, track, api } from 'lwc';

export default class FormsPageModule extends LightningElement {
    @track localpage;

    @api page;

    @api isSectionDrag = false;
    @track isFieldDrag = false;

    /* @api
    callGetOptions(){
        let sections = this.template.querySelectorAll('c-forms-section-module');
        if(sections){
            sections.forEach(section => {
                section.callGetOptions();
            })
        }
    } */

    renderedCallback(){
        if(this.page.isLabelEdit){
            let inputs = this.template.querySelectorAll('input');
            if(inputs && inputs.length){
                inputs.forEach(input => {
                    input.select();
                })
            }
        }
    }

    addSection() {
        this.dispatchEvent(new CustomEvent('addsection',
        {
            detail:
            {
                pageIndex: this.page.pageIndex
            }
        }));
    }

    handlePageLabelEdit() {
        this.dispatchEvent(new CustomEvent('pagelabeledit',
        {
            detail:
            {
                pageIndex: this.page.pageIndex
            }
        }));
    }

    handlePageLabelDone(event) {
        let label = event.target.value;
        console.log("label >> ", label);
        this.dispatchEvent(new CustomEvent('pagelabeleditdone',
            {
                detail:
                {
                    newLabel: label,
                    pageIndex: this.page.pageIndex
                }
            }));
    }

    handlePageDelete(){
        this.dispatchEvent(new CustomEvent('pagedelete',{
            detail:
            {
                pageIndex: this.page.pageIndex
            }
        }));
    }

    handleSectionMouseDown(){
        console.log('section mouse down called');
        this.isSectionDrag = true;
        this.isFieldDrag = false;
    }

    handleFieldDragStarted(){
        this.isFieldDrag = true;
    }

    /** Drag start */
    handleSectionDragStart(event){
       if(!this.isFieldDrag){
            let sectionIndex = event.currentTarget.dataset.id;
            this.dispatchEvent(new CustomEvent('sectiondrag',{
                detail:{
                    sectionIndex: sectionIndex,
                    pageIndex: this.page.pageIndex,
                    isSectionDrag : true

                }
            }));
        }
    }

    handleSectionDragOver(event) {
        //if(this.isSectionDrag){
            this.cancel(event);
            let currentElement = event.currentTarget.dataset.id;
            if (!this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains("sectiondropzone")) {
                this.template.querySelector(`[data-id="${currentElement}"]`).classList.add("sectiondropzone");
            }
        //}
    }

    handleSectionDragEnter(event) {
        this.cancel(event);
    }

    handleSectionDragLeave(event) {
        this.cancel(event);
        let currentElement = event.currentTarget.dataset.id;
        if (this.template.querySelector(`[data-id="${currentElement}"]`).classList.contains("sectiondropzone")) {
            this.template.querySelector(`[data-id="${currentElement}"]`).classList.remove("sectiondropzone");
        }
    }

    handleSectionDrop(event) {
        let currentDropZone = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('sectiondropzone',
            {
                detail:
                {
                    sectionIndex: currentDropZone,
                    pageIndex: this.page.pageIndex
                }
            }))

        this.template.querySelector(`[data-id="${currentDropZone}"]`).classList.remove("sectiondropzone");
    }

    cancel(event) {
        if (event.stopPropagation) event.stopPropagation();
        if (event.preventDefault) event.preventDefault();
        return false;
    };
}