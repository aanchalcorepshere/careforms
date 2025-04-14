import { LightningElement, api, wire } from 'lwc';
import getFormsList from '@salesforce/apex/FormsController.getFormsList';

export default class FormsRule extends LightningElement {
    @api rule;

    @api fields;
    selectedChild;
    selectedFormName;
    selectedParent;
    fieldValue;
    selectedOperator;
    dependentType;
    required = false;
    @api primaryFieldList;
    @api secondaryFieldList;
    formsList = [];
    typeSelected = false;

    operatorOptions = [
        {label:"Equals",value:"equals"},
        {label:"Contains",value:"contains"},
        {label:"Is Less Than Equal To",value:"islessthanequalto"},
        {label:"Is Greater Than Equal To",value:"isgreaterthanequalto"},
        {label:"Is Less Than",value:"islessthanequalto"},
        {label:"Is Greater Than",value:"isgreaterthanequalto"},
        {label:"Is Not Equal To",value:"isnotequalto"}
    ];

    dependentOptions = [
        {label:"Form",value:"form"},
        {label:"Field",value:"field"},
    ];

    connectedCallback(){
        console.log('this.rule >> '+JSON.stringify(this.rule));
        getFormsList()
        .then(result => {
            let tempData = JSON.parse(JSON.stringify(result));
            if(tempData && tempData.length){
                tempData.forEach(form => {
                    let aForm = {};
                    aForm.label = form.caresp__Form_Name__c;
                    aForm.value = form.caresp__Form_Name__c+'|'+form.Id;
                    this.formsList.push(aForm);
                })
            }
            if(this.rule.dependentType){
                this.typeSelected = true;
            }
        })
        .catch(error => {
            console.log('error > ',JSON.stringify(error));
        })
    }

    /* @wire(getFormsList)
    wiredForms({data,error}){
       if(data){
        let tempData = JSON.parse(JSON.stringify(data));
        if(tempData && tempData.length){
            tempData.forEach(form => {
                let aForm = {};
                aForm.label = form.Form_Name__c;
                aForm.value = form.Id;
                this.formsList.push(aForm);
            })
        }
       }else if(error){
           // perform your logic related to error 
        }
     }; */

    value = 'field';

    get typeForm(){
        return this.rule.dependentType == "form";
    }

    get selectedFormValue(){
        return this.rule.formName+'|'+this.rule.selectedChild;
    }

    handleChange(event){
        let targetName = event.target.name;
        if(targetName == 'parent'){
            this.selectedParent = event.target.value;
        }else if(targetName == 'parentfieldvalue'){
            this.fieldValue = event.target.value;
        }else if(targetName == 'child'){
            this.selectedChild = event.target.value;
            console.log('event.target >> '+event.target.label);
        }else if(targetName == 'childForm'){
            //let tempStr = event.target.value.split('|');
            this.selectedChild = event.target.value;
            //this.selectedFormName = tempStr[0];
            console.log('event.target >> '+event.target.label);
        }else if(targetName == 'operator'){
            this.selectedOperator = event.target.value;
        }else if(targetName == this.rule.ruleIndex){
            this.dependentType = event.target.value;
            this.typeSelected = true;
        }else if(targetName == 'required'){
            this.required = event.target.checked;
        }

        console.log('this.selectedParent >> ',this.selectedParent);
        console.log('this.fieldValue >> ',this.fieldValue);
        console.log('this.selectedChild >> ',this.selectedChild);
        console.log('this.selectedOperator >> ',this.selectedOperator);
        console.log('this.dependentType >> ',this.typeSelected);

        this.dispatchEvent(new CustomEvent('updateruledata',
        {
            detail:
            {
                ruleIndex: this.rule.ruleIndex,
                primaryField: this.selectedParent,
                secondaryField: this.selectedChild,
                operator: this.selectedOperator,
                value: this.fieldValue,
                dependentType: this.dependentType,
                required: this.required,
            }
        }));
    }

    handleRuleDelete(){
        console.log('this.rule.ruleIndex >> ',this.rule.ruleIndex);
        this.dispatchEvent(new CustomEvent('deleterule',
        {
            detail:
            {
                ruleIndex: this.rule.ruleIndex
            }
        }));
    }
}