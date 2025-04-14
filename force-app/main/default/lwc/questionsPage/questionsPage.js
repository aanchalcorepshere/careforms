import { LightningElement } from 'lwc';

export default class QuestionsPage extends LightningElement {

    refreshTab = true;

    handleNewAction(){
        this.template.querySelector('[data-id="activeQuestions"]').handleNewAction();
    }

    handleSearch(event){
        var searchText = event.target.value;
        var quesListAll = this.template.querySelectorAll('c-questions');
        quesListAll.forEach(quesList =>{
            quesList.handleSearch(searchText);
        });
    }

    handleClick(){
        console.log("tab clicked");
        this.refreshTab = false;
        setTimeout(() => {this.refreshTab = true;}, 500);
    }
}