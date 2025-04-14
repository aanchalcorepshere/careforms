import { LightningElement, track, wire, api } from 'lwc';
import getCompatibleFields from '@salesforce/apex/AssessmentWizardController.getCompatibleFields';

const alphabet = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

const roman = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx"]

export default class AssessmentWizardSortQuestions extends LightningElement {
    //@api quesListFromQuesSelection;
    @track quesList;
    @api objectName;
    

    //activeSections = ['tutorialW3web'];
    activeSectionsMessage = '';
    

    @track fieldList;
    levelForDependent;
    parentQuesForDependent;
    ansOpForDependent;
    parentAnsOpForDependent;
    grandParentQuesForDependent;

    alphabet = alphabet;
    roman = roman;
    dragSource;
    dropDestination;
    isModalOpen = false;
    error;

    

    @api
    get quesListFromQuesSelection(){
        return this.quesList;
    }

    set quesListFromQuesSelection(value){
        //Set personObject property to our new updated person object
        this.quesList = JSON.parse(JSON.stringify(value));
    }

    connectedCallback(){
        let objList = [];
        objList.push(this.objectName);
        //console.log("objList > ",JSON.stringify(objList));
        getCompatibleFields({objNames : objList})
        .then(result => {
            let tempData = JSON.parse(result);
            console.log("tempData > ",JSON.stringify(tempData));
            tempData.sort(function (a, b) {
                return a.value.localeCompare(b.value);
            });
            this.fieldList = JSON.parse(JSON.stringify(tempData));
        })
        .catch(error=>{
            this.error = error;
            console.error("error >> ",JSON.stringify(error));
        })
    }

    /* @wire(getCompatibleFields,{objNames : ['Account','Contact']})
    wiredObjects({ error, data }) {
        if(data){
            let tempData = JSON.parse(data);
            tempData.sort(function (a, b) {
                return a.value.localeCompare(b.value);
            });
            this.fieldList = tempData;
        }else if(error){
            this.error = error;
        }
    } */

    /* get isLoading() {
        return !(this.fieldList);
    } */
 
    toggleSections(event) {
        const openSections = event.detail.openSections;
 
        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    /* get optsize() {
        //if(this.quesList)
        return this.quesList.length;
    } */

    /* connectedCallback() {
        //this.sortOptions();
    } */

    handleDragStart(event) {
        this.dragSource = JSON.parse(JSON.stringify(event.detail));
        console.log('this.dragSource => ',JSON.stringify(this.dragSource));
    }

    handleDrop(event) {
        this.dropDestination = JSON.parse(JSON.stringify(event.detail));
        console.log('this.dropDestination => ',JSON.stringify(this.dropDestination));
        this.reorder();
    }

    sortOptions() {
        if(this.dragSource.level == 'level2'){
            let parent_ques_pos = this.quesList.findIndex(j => j.quesId === this.dragSource.parent);
            console.log("parent_ques_pos # ",parent_ques_pos);
            let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.ansOpId);
            console.log("ans_op_pos # ",ans_op_pos);
            this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList.sort(function (a, b) {
                return a.sequence - b.sequence;
            });
        }else if(this.dragSource.level == 'level3'){
            let grand_parent_pos = this.quesList.findIndex(j => j.quesId === this.dragSource.grandparent);

            let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.grandParentAnsOpId);

            let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === this.dragSource.parent);

            let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.ansOpId);

            this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList.sort(function (a, b) {
                return a.sequence - b.sequence;
                /* if(a.sequence < b.sequence) { return -1; }
                if(a.sequence > b.sequence) { return 1; }
                return 0; */
            });
        }else{
            this.quesList.sort(function (a, b) {
                return a.sequence - b.sequence;
            });
        }
    }

    resetSequence(item) {
        if(item.level == 'level2' ){
            let parent_ques_pos = this.quesList.findIndex(j => j.quesId === item.parent);
            let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === item.ansOpId);
            let seq = 1;
            let oldOptions = this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
            oldOptions.forEach(element => {
                element.sfSeq = this.alphabet[seq-1];
                element.sequence = seq++;
                /* element.sequence = this.alphabet[seq];
                seq++; */
            });
            this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = oldOptions;
        }else if(item.level == 'level3'){
            let grand_parent_pos = this.quesList.findIndex(j => j.quesId === item.grandparent);

            let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === item.grandParentAnsOpId);

            let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === item.parent);

            let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === item.ansOpId);

            let oldOptions = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
            let seq = 1;
            oldOptions.forEach(element => {
                element.sfSeq = this.roman[seq-1];
                element.sequence = seq++;
                /* element.sequence = this.roman[seq];
                seq++; */
            });
            
            this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = oldOptions;
        }else{
            let oldOptions = this.quesList;
            let seq = 1;
            oldOptions.forEach(element => {
                element.sfSeq = seq;
                element.sequence = seq++;
            });
            this.quesList = [...oldOptions];    
        }
        // Reset the sequence number for each item starting from 1
        /* let seq = 1;
        let oldOptions = this.quesList;
        oldOptions.forEach(element => {
            element.sequence = seq++;
        });
        this.quesList = [...oldOptions]; */
    }

    reorder() {
        if(this.dragSource.level == 'level2'){
            let parent_ques_pos = this.quesList.findIndex(j => j.quesId === this.dragSource.parent);
            console.log("parent_ques_pos => ",parent_ques_pos);
            let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.ansOpId);
            console.log("ans_op_pos => ",ans_op_pos);
            let oldOptions = this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
            oldOptions.forEach(element => {
                if (element.quesId === this.dragSource.quesId) {
                    element.sequence = parseInt(this.dropDestination.sequence);
                    console.log("element.sequence => ",element.sequence);
                    element.sfSeq = this.dropDestination.sfSeq;
                    //element.sfSeq = this.alphabet[parseInt(element.sequence)-1];
                }
                if (element.quesId === this.dropDestination.quesId) {
                    element.sequence = parseInt(this.dragSource.sequence);
                    console.log("element.sequence => ",element.sequence);
                    element.sfSeq = this.dragSource.sfSeq;
                    //element.sfSeq = this.alphabet[parseInt(element.sequence)-1];
                }
            });
            this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = [...oldOptions];
            this.sortOptions();   
        }else if(this.dragSource.level == 'level3'){
            let grand_parent_pos = this.quesList.findIndex(j => j.quesId === this.dragSource.grandparent);

            let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.grandParentAnsOpId);

            let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === this.dragSource.parent);

            let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === this.dragSource.ansOpId);

            let oldOptions = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;

            oldOptions.forEach(element => {
                if (element.quesId === this.dragSource.quesId) {
                    element.sequence = parseInt(this.dropDestination.sequence);
                    console.log("element.sequence => ",element.sequence);
                    element.sfSeq = this.roman[parseInt(this.dropDestination.sequence)-1];
                }
                if (element.quesId === this.dropDestination.quesId) {
                    element.sequence = parseInt(this.dragSource.sequence);
                    console.log("element.sequence => ",element.sequence);
                    element.sfSeq = this.roman[parseInt(this.dragSource.sequence)-1];
                }
            });
            this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = oldOptions;
            this.sortOptions();
        }else{
            let oldOptions = this.quesList;
            oldOptions.forEach(element => {
                if (element.quesId === this.dragSource.quesId) {
                    element.sequence = parseInt(this.dropDestination.sequence);
                    element.sfSeq = parseInt(this.dropDestination.sequence);
                }
                if (element.quesId === this.dropDestination.quesId) {
                    element.sequence = parseInt(this.dragSource.sequence);
                    element.sfSeq = parseInt(this.dragSource.sequence);
                }
            });
            this.quesList = [...oldOptions];
            this.sortOptions();
        }
    }

    handleRemoveItem(event) {
        let item = event.detail;
        if(item.level == 'level2'){
            let parent_ques_pos = this.quesList.findIndex(j => j.quesId === item.parent);
            console.log("parent_ques_pos => ",parent_ques_pos);
            let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === item.ansOpId);
            console.log("ans_op_pos => ",ans_op_pos);
            let oldOptions = this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
            //let removePos = oldOptions.findIndex(option => option.itemId === item.itemId);
            oldOptions.splice(item.sequence-1, 1);
            this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = oldOptions;
        }else if(item.level == 'level3'){
            console.log("item >>>> ",JSON.stringify(item));
            let grand_parent_pos = this.quesList.findIndex(j => j.quesId === item.grandparent);

            let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === item.grandParentAnsOpId);

            let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === item.parent);

            let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === item.ansOpId);

            let oldOptions = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;

            //let removePos = oldOptions.findIndex(option => option.itemId === item.itemId);
            console.log("removePos >> ",item.sequence-1);
            oldOptions.splice(item.sequence-1, 1);
            
            this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = [...oldOptions];
        }else{
            let removeId = event.detail;
            let index = this.quesList.findIndex(option => option.quesId === removeId);
            let oldOptions = this.quesList;
            oldOptions.splice(index, 1);
            this.quesList = [...oldOptions];
        }
        this.resetSequence(item);
    }

    handleAddDependent(event){
        this.levelForDependent = '';
        this.parentQuesForDependent = '';
        this.ansOpForDependent = '';
        this.parentAnsOpForDependent = '';
        this.grandParentQuesForDependent = '';

        this.parentQuesForDependent = event.currentTarget.dataset.parentQues;
        this.ansOpForDependent = event.currentTarget.dataset.ans;
        this.levelForDependent = event.currentTarget.dataset.level;
        this.parentAnsOpForDependent = event.currentTarget.dataset.parentAns;
        console.log("parentAnsOpForDependent >>>> ",this.parentAnsOpForDependent);
        this.grandParentQuesForDependent = event.currentTarget.dataset.grandParent;
        this.dependentAllowedForDependent = (this.levelForDependent=='level1' || 'level2')?true:false;
        this.isModalOpen = true;
    }

    closeModal(){
        this.isModalOpen = false;
    }

    getDependents(){
        let dependentQues = this.template.querySelector('c-assessment-wizard-dependent-question').onSubmit();
        
        console.log("DEPDENDENTS ==> ",JSON.stringify(dependentQues));

        dependentQues.forEach(dependent => {
            if(dependent.level === 'level2'){
                
                let parent_ques_pos = this.quesList.findIndex(j => j.quesId === dependent.parent);
                let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === dependent.ansOpId);
                
                let oldOptions = this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;

                oldOptions.push(dependent);
                
                this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = [...oldOptions];
                
                this.resetSequence(dependent);
            }else if(dependent.level === 'level3'){
                let grand_parent_pos = this.quesList.findIndex(j => j.quesId === dependent.grandparent);

                let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === dependent.grandParentAnsOpId);

                let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === dependent.parent);

                let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === dependent.ansOpId);

                let oldOptions = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
                console.log('oldOptions ==> ',JSON.stringify(oldOptions));
                oldOptions.push(dependent);
                console.log('level3');
                this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList = oldOptions;
                this.resetSequence(dependent);
            }
        });

        this.quesList = JSON.parse(JSON.stringify(this.quesList));
        console.log("this.quesList =>=> ",JSON.stringify(this.quesList));
        this.isModalOpen = false;
    }

    updateFieldName(event){
        console.log('DETAIL >>>> ',JSON.stringify(event.detail));
        let ques = event.detail;
        let index = this.quesList.findIndex(option => option.quesId === ques.quesId);
        this.quesList[index].fieldname = ques.fieldname;
        console.log("Ques =>> ",JSON.stringify(this.quesList[index]));
    }

    updateRequired(event){
        console.log('DETAIL >>>> ',JSON.stringify(event.detail));
        let ques = event.detail;
        let index = this.quesList.findIndex(option => option.quesId === ques.quesId);
        this.quesList[index].required = ques.required;
        console.log("Ques =>> ",JSON.stringify(this.quesList[index]));
    }

    handleScoring(event){
        //console.log('DETAIL >>>> ',JSON.stringify(event.detail));
        let ques = event.currentTarget.dataset.parentQues;
        let index = this.quesList.findIndex(option => option.quesId === ques);
        let ans = event.currentTarget.dataset.ans;
        let ansPos = this.quesList[index].score.findIndex(s => s.ansOpId == ans);
        if(ansPos === -1){
            this.quesList[index].score.push(
                {
                    ansOpId:ans,
                    score:event.target.value
                }
            );
        }else{
            this.quesList[index].score[ansPos].score = event.target.value;
        }
        console.log("Ques =>> ",JSON.stringify(this.quesList[index]));
    }

    @api
    handleSubmit(){
        var confirmation = confirm("Have you entered all the desired details? Press OK to confirm");
        if(confirmation == true){
            this.quesList.forEach(ques => {
                let temp;
                if(ques.score.length){
                    ques.score.forEach(s => {
                        temp = temp?temp+';'+s.ansOpId+'|'+s.score:s.ansOpId+'|'+s.score;
                    })
                    ques.scorelist = temp;
                }
            })
            return this.quesList;
        }
    }
}