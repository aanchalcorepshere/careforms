import { LightningElement, track, api } from 'lwc';

export default class TaskDetail extends LightningElement {
    gotData = false;
    @api task;

    renderedCallback(){
        if(this.task.taskIndex%2 == 0){
            this.template.querySelector('.taskarea').classList.add('slds-theme_shade');
        }
    }

    get hideDeleteIcon(){
        return this.task.taskIndex == 1;
    }

    get hideParentField(){
        return this.task.controllingTask.options.length == 0;
    }

    get disableSubType(){
        return this.task.taskSubType.options.length == 0;
    }

    handleChange(event){
        let targetName = event.target.name;
        let targetValue = event.target.value;
        if(targetName == 'parenttask' && targetValue == this.task.subject.value){
            alert('Can\'t be parent of self.');
            let element = this.template.querySelector('lightning-combobox');
            element.value = null;
        }else{
            let taskInfo = {};
            taskInfo.taskIndex = this.task.taskIndex;
            taskInfo.type = targetName;
            taskInfo.value = targetValue;
            console.log('taskInfo.taskIndex >> ',taskInfo.taskIndex);
            this.dispatchEvent(new CustomEvent('taskupdate',{
                detail: taskInfo
            }));
        }
    }

    handleDelete(){
        let confirmation = confirm('Are you sure you want to delete this task?');
        if(confirmation){
            this.dispatchEvent(new CustomEvent('taskdelete',{
                detail: this.task.taskIndex
            }));
        }
    }
}