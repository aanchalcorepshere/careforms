import { LightningElement, track, api, wire } from 'lwc';
import getQuestionsForSelection from '@salesforce/apex/AssessmentWizardController.getQuestionsForSelection';

const columns = [
    { label: 'Question Text', fieldName: 'quesText', type:'text', wrapText: true, fixedWidth:700 },
    { label: 'Data Type', fieldName: 'dataType', type: 'text' },
    { label: 'Answer Options', fieldName: 'ansOps', type: 'text', wrapText: true, fixedWidth:500 }
];

const alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

const roman = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx"]

export default class AssessmentWizardDependentQuestion extends LightningElement {
    @api section;
    @api parent;
    @api level;
    @api grandparent;
    @api dependentAllowed;
    @api ansOpId;
    @api grandParentAnsOpId;
    @track quesList;
    columns = columns;
    alphabet = alphabet;
    roman = roman;
    unfilteredData;
    preSelectedRows=[];
    preservSelectedRow=[];

    @wire(getQuestionsForSelection,{isDependent:true})
    wiredObjects({ error, data }) {
        if(data){
            let tempData = JSON.parse(data);
            //console.log("data > > ",JSON.stringify(tempData));
            this.quesList = [...tempData];
            this.unfilteredData=this.quesList;
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
        this.preSelectedRows=this.preservSelectedRow;
        this.quesList = JSON.parse(JSON.stringify(this.quesList));
    }
    @api
    onSubmit(){
        let finalList = [];
        let selQues = this.template.querySelector('lightning-datatable').getSelectedRows();
        //let rowId=event.detail.selectedRows;
        this.preSelectedRows=[];
        selQues.forEach(rw=>{
            this.preSelectedRows.push(rw.quesId)
            this.preservSelectedRow.push(rw.quesId)
        })
        let seq = 1;
        selQues.forEach(ques => {
            let updatedQues = {};
            updatedQues.level= (this.level == 'level1')?'level2':(this.level == 'level2')?'level3':'level1';
            updatedQues.parent = this.parent;
            updatedQues.grandparent = this.grandparent;
            updatedQues.sequence = seq;
            updatedQues.sfSeq = (this.level == 'level1')?this.alphabet[parseInt(seq)-1]:(this.level == 'level2')?this.roman[parseInt(seq)-1]:seq;
            updatedQues.dependentAllowed = this.dependentAllowed;
            updatedQues.ansOpId = this.ansOpId;
            updatedQues.grandParentAnsOpId = this.grandParentAnsOpId;
            updatedQues.quesId = ques.quesId;
            updatedQues.quesText = ques.quesText;
            updatedQues.dataType = ques.dataType;
            updatedQues.quesAnsOptions = ques.ansOps;
            //updatedQues.unique = this.section+'_'+updatedQues.level+'_'+ques.quesId+'_'+updatedQues.sfSeq;
            updatedQues.unique = this.section+'_'+updatedQues.level+'_'+ques.quesId+'_'+this.ansOpId+'_'+updatedQues.sfSeq;
            //updatedQues.unique = 
            if(ques.quesAnsOpList){
                updatedQues.dependentQuesData = [];
                ques.quesAnsOpList.forEach(depData=> {
                    let dep = {};
                    dep.ansOpText = depData.caresp__Answer_Text__c;
                    dep.ansOpId = depData.Id;
                    dep.dependentQuesList = [];
                    updatedQues.dependentQuesData.push(dep);
                });
            }
            console.log("updatedQues >>>> ",JSON.stringify(updatedQues));
            finalList.push(updatedQues);
            seq++;
        });
        
        
        return finalList;
    }
}