import { LightningElement, track, wire, api } from 'lwc';
import getCompatibleFields from '@salesforce/apex/AssessmentWizardController.getCompatibleFields';

const alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

const roman = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx"]

export default class AssessmentWizardSortQuestions extends LightningElement {

    @track quesList;
    @api objectName;

    activeSectionsMessage = '';

    @track fieldList;
    levelForDependent;
    parentQuesForDependent;
    ansOpForDependent;
    parentAnsOpForDependent;
    grandParentQuesForDependent;
    assessmentQuesToBeDeleted=[];
    @api section;
    @api sectionSerial;
    @api isSubmit;
    @api needScoring;

    alphabet = alphabet;
    roman = roman;
    dragSource;
    dropDestination;
    isModalOpen = false;
    error;

    connectedCallback() {
        if(this.objectName){
            /* let objList = [];
            objList.push(this.objectName); */
            getCompatibleFields({ objName: this.objectName })
            .then(result => {
                let tempData = JSON.parse(result);
                tempData.sort(function (a, b) {
                    return a.value.localeCompare(b.value);
                });
                this.fieldList = JSON.parse(JSON.stringify(tempData));
            })
            .catch(error => {
                this.error = error;
                console.error("error >> ", JSON.stringify(error));
            })
        }
    }

    @api
    get quesListFromQuesSelection() {
        return this.quesList;
    }

    set quesListFromQuesSelection(value) {
        //Set personObject property to our new updated person object
        this.quesList = JSON.parse(JSON.stringify(value));
    }

    toggleSections(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    handleDragStart(event) {
        this.dragSource = JSON.parse(JSON.stringify(event.detail));
    }

    handleDrop(event) {
        this.dropDestination = JSON.parse(JSON.stringify(event.detail));
        this.reorder();
    }

    getOldOptions(source) {
        if (source.level == 'level2') {
            let parent_ques_pos = this.quesList.findIndex(j => j.quesId === source.parent);
            let ans_op_pos = this.quesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === source.ansOpId);

            return this.quesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
        } else if (source.level == 'level3') {
            let grand_parent_pos = this.quesList.findIndex(j => j.quesId === source.grandparent);

            let grand_parent_ans_op = this.quesList[grand_parent_pos].dependentQuesData.findIndex(j => j.ansOpId === source.grandParentAnsOpId);

            let parent_ques_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList.findIndex(j => j.quesId === source.parent);

            let ans_op_pos = this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData.findIndex(j => j.ansOpId === source.ansOpId);

            return this.quesList[grand_parent_pos].dependentQuesData[grand_parent_ans_op].dependentQuesList[parent_ques_pos].dependentQuesData[ans_op_pos].dependentQuesList;
        } else {
            return this.quesList;
        }
    }

    sortOptions() {
        this.getOldOptions(this.dragSource).sort(function (a, b) {
            return a.sequence - b.sequence;
        });

        this.handleSubmit();
    }

    resetSequence(item) {
        console.log("resetSequence start");
        let seq = 1;
        if (item.level == 'level1') {
            this.getOldOptions(item).forEach(element => {
                element.sfSeq = seq;
                element.sequence = seq;
                seq++;
            });
        } else if (item.level == 'level2') {
            this.getOldOptions(item).forEach(element => {
                element.sfSeq = this.alphabet[seq - 1];
                element.sequence = seq;
                seq++;
            });
        } else if (item.level == 'level3') {
            this.getOldOptions(item).forEach(element => {
                element.sfSeq = this.roman[seq - 1];
                element.sequence = seq;
                seq++;
            });
        }
        this.quesList = JSON.parse(JSON.stringify(this.quesList));
        this.handleSubmit();
        console.log("resetSequence end");
    }

    reorder() {
        this.getOldOptions(this.dragSource).forEach(element => {
            if (element.quesId === this.dragSource.quesId) {
                element.sequence = parseInt(this.dropDestination.sequence);
                element.sfSeq = this.dropDestination.sfSeq;
            }
            if (element.quesId === this.dropDestination.quesId) {
                element.sequence = parseInt(this.dragSource.sequence);
                element.sfSeq = this.dragSource.sfSeq;
            }
        });
        this.sortOptions();
    }

    handleRemoveItem(event) {
        console.log("handleRemoveItem start");
        let item = event.detail;
        this.getOldOptions(item).splice(item.sequence - 1, 1);
        if(item.aqId && this.assessmentQuesToBeDeleted.findIndex(x => x == item.aqId) == -1){
            this.assessmentQuesToBeDeleted.push(item.aqId);
        }
        if(this.assessmentQuesToBeDeleted.length){
            this.dispatchEvent(new CustomEvent('aqtobedeleted', {
                detail: this.assessmentQuesToBeDeleted
            }));
        }
        this.resetSequence(item);
        console.log("handleRemoveItem end");
    }

    handleAddDependent(event) {
        this.sectionForDependent = '';
        this.levelForDependent = '';
        this.parentQuesForDependent = '';
        this.ansOpForDependent = '';
        this.parentAnsOpForDependent = '';
        this.grandParentQuesForDependent = '';

        this.sectionForDependent = event.currentTarget.dataset.section;
        this.parentQuesForDependent = event.currentTarget.dataset.parentQues;
        this.ansOpForDependent = event.currentTarget.dataset.ans;
        this.levelForDependent = event.currentTarget.dataset.level;
        this.parentAnsOpForDependent = event.currentTarget.dataset.parentAns;
        this.grandParentQuesForDependent = event.currentTarget.dataset.grandParent;
        this.dependentAllowedForDependent = (this.levelForDependent == 'level1' || 'level2') ? true : false;
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    getDependents() {
        let dependentQues = this.template.querySelector('c-assessment-wizard-dependent-question').onSubmit();

        dependentQues.forEach(dependent => {
            //if(this.getOldOptions(dependent).findIndex(x => x.quesId == dependent.quesId) == -1){
                this.getOldOptions(dependent).push(dependent);
                this.resetSequence(dependent);
            /* }else{
                alert("Duplicate Question ! "+dependent.quesText);
            } */
        });

        this.quesList = JSON.parse(JSON.stringify(this.quesList));
        this.isModalOpen = false;

        this.handleSubmit();
    }

    updateQuestionData(event) {
        let ques = event.detail;
        let index = this.getOldOptions(ques).findIndex(option => option.quesId === ques.quesId);
        this.getOldOptions(ques)[index].objectname = ques.objectname;
        this.getOldOptions(ques)[index].required = ques.required;
        this.getOldOptions(ques)[index].fieldname = ques.fieldname;
        this.getOldOptions(ques)[index].fieldlist = ques.fieldlist;
        console.log("this.getOldOptions(ques)[index] >> ",JSON.stringify(this.getOldOptions(ques)[index]));
        this.handleSubmit();
    }

    handleScoring(event) {
        let ques = event.currentTarget.dataset.parentQues;
        let index = this.quesList.findIndex(option => option.quesId === ques);
        let ans = event.currentTarget.dataset.ans;
        let ansPos = this.quesList[index].dependentQuesData.findIndex(s => s.ansOpId == ans);
        this.quesList[index].dependentQuesData[ansPos].score = event.target.value;
        this.handleSubmit();
    }

    handleSubmit() {
        console.log("handleSubmit start");
        this.quesList.forEach(ques => {
            let temp;
            let scoreList = [];

            if (ques.dependentQuesData && ques.dependentQuesData.length) {
                ques.dependentQuesData.forEach(s => {
                    if (s.score) {
                        scoreList.push(s.score);
                        temp = temp ? temp + ';' + s.ansOpId + '|' + s.score : s.ansOpId + '|' + s.score;
                    }   
                })
                ques.scorelist = temp;
                ques.maxScore = Math.max(...scoreList);
            }
            ques.section = this.section;
            //ques.unique = this.section + ques.quesId;
        })
        this.dispatchEvent(new CustomEvent('questions', {
            detail: {
                questions : this.quesList,
                section : this.section
            }
        }));
        console.log("handleSubmit end");
    }
}