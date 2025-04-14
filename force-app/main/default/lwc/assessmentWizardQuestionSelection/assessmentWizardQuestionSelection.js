import { LightningElement, track, api, wire } from 'lwc';
import getQuestionsForSelection from '@salesforce/apex/AssessmentWizardController.getQuestionsForSelection';

const columns = [
    { label: 'Question Text', fieldName: 'quesText', type:'text', wrapText: true, fixedWidth:700 },
    { label: 'Data Type', fieldName: 'dataType', type: 'text' },
    { label: 'Answer Options', fieldName: 'ansOps', type: 'text', wrapText: true, fixedWidth:500 }
];

export default class AssessmentWizardQuestionSelection extends LightningElement {
    columns = columns;
    preSelectedRows=[];
    preservSelectedRow=[];
    
    @track quesList;
    unfilteredData;

    @wire(getQuestionsForSelection,{isDependent:false})
    wiredObjects({ error, data }) {
        if(data){
            let tempData = JSON.parse(data);
            //console.log("Ques data > > ",JSON.stringify(tempData));
            this.quesList = tempData;
            this.unfilteredData = this.quesList;
        }else if(error){
            this.error = error;
        }
    }

    handleSearch(event){
        var searchTerm = event.target.value;
        console.log('searchTerm '+searchTerm);
        //this.unfilteredData = this.quesList;
        this.quesList = this.unfilteredData.filter(function (obj) {
            return obj.quesText.toLowerCase().includes(searchTerm.toLowerCase());
        });
        console.log('filtered data '+JSON.stringify(this.quesList));
        this.quesList = JSON.parse(JSON.stringify(this.quesList));
    }

    handleRowSelection(event){

    }

    @api
    onSubmit(){
        let selQues = this.template.querySelector('lightning-datatable').getSelectedRows();
        return JSON.parse(JSON.stringify(selQues));
    }
}