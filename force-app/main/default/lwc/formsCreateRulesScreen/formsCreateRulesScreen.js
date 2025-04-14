import ContentLocation from '@salesforce/schema/ContentVersion.ContentLocation';
import { LightningElement, track, api } from 'lwc';

export default class FormsCreateRulesScreen extends LightningElement {
    @track rules =[
         {
            ruleIndex : 0,
            ruleName : 'Rule 1',
            primaryField : '',
            secondaryField : '',
            value : '',
            operator: '',
            dependentType:'',
            required:false
         }
    ];

    @api pageData;
    @api existingRules;
    primaryFieldList = [];
    secondaryFieldList = [];

    connectedCallback(){
        let rawPrimaryFieldList = [];
        let rawSecondaryFieldList = [];
        //console.log(" page data from rule screen  >> ",JSON.stringify(this.pageData));
        this.pageData.forEach(page => {
            page.sections.forEach(section => {
                section.fields.forEach(field => {
                    if(field.fieldData.fieldName){
                        if(!field.fieldData.isQuestion){
                            if(!section.isSectionMulti){
                                this.primaryFieldList.push({label:field.fieldData.fieldUniqueName,value:field.fieldData.fieldUniqueName});
                                rawPrimaryFieldList.push(field.fieldData.fieldUniqueName);
                                this.secondaryFieldList.push({label:field.fieldData.fieldUniqueName,value:field.fieldData.fieldUniqueName});
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            }
                            /* if(!field.fieldData.required && !section.isSectionMulti){
                                this.secondaryFieldList.push({label:field.fieldData.fieldUniqueName,value:field.fieldData.fieldUniqueName});
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            } */
                        }else{
                            if(!section.isSectionMulti){
                                this.primaryFieldList.push({label:field.fieldData.fieldName,value:field.fieldData.fieldUniqueName});
                                rawPrimaryFieldList.push(field.fieldData.fieldUniqueName);
                                this.secondaryFieldList.push({label:field.fieldData.fieldName,value:field.fieldData.fieldUniqueName});
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            }
                            /* if(!field.fieldData.required && !section.isSectionMulti){
                                this.secondaryFieldList.push({label:field.fieldData.fieldName,value:field.fieldData.fieldUniqueName});
                                rawSecondaryFieldList.push(field.fieldData.fieldUniqueName);
                            } */
                        }
                    }
                })
            })
        })
        if(this.existingRules){
            //console.log("this.existingRules >> ",JSON.stringify(this.existingRules));
            let tempExisingRules = JSON.parse(JSON.stringify(this.existingRules));
            let filteredRuleList = [];
            if(tempExisingRules && tempExisingRules.length){
                tempExisingRules.forEach(rule => {
                    if(rule.dependentType == 'field'){
                        if(rawPrimaryFieldList.includes(rule.primaryField) && rawSecondaryFieldList.includes(rule.secondaryField)){
                            filteredRuleList.push(rule);
                        }
                    }else{
                        if(rawPrimaryFieldList.includes(rule.primaryField)){
                            filteredRuleList.push(rule);
                        }
                    }
                })
            }

            if(filteredRuleList && filteredRuleList.length){
                this.rules = filteredRuleList;
            }
        }
        //console.log("this.pageData >> ",JSON.stringify(this.pageData));
    }

    addRule(){
        console.log('RULES LENGTH >> '+this.rules.length);
        this.rules.push(
            {
               ruleIndex : this.rules.length,
               ruleName : 'Rule '+parseInt(this.rules.length+1),
               primaryField : '',
               secondaryField : '',
               value : '',
               operator: '',
               dependentType: '',
               required : false
            }
        )
        console.log('RULES >> '+JSON.stringify(this.rules));
    }

    handleDeleteRule(event){
        console.log('delete function called');
        if(this.rules.length != 1){
            let ruleIndex = event.detail.ruleIndex;
            console.log('ruleIndex >> ',ruleIndex);
            this.rules.splice(ruleIndex,1);
        }else{
            this.rules[0].primaryField = undefined;
            this.rules[0].secondaryField = undefined;
            this.rules[0].value = undefined;
            this.rules[0].operator = undefined;
            this.rules[0].dependentType = undefined;
            this.rules[0].required = false;
        }
    }

    updateRuleData(event){
         let ruleIndex = event.detail.ruleIndex;
         let rulePos = this.rules.findIndex(r => r.ruleIndex == ruleIndex);
         if(event.detail.primaryField)
         this.rules[rulePos].primaryField = event.detail.primaryField;
         if(event.detail.secondaryField)
         this.rules[rulePos].secondaryField = event.detail.secondaryField;
         if(event.detail.value)
         this.rules[rulePos].value = event.detail.value;
         if(event.detail.operator)
         this.rules[rulePos].operator = event.detail.operator;
         if(event.detail.dependentType)
         this.rules[rulePos].dependentType = event.detail.dependentType;

         this.rules[rulePos].required = event.detail.required;

         console.log("rules >> ",JSON.stringify(this.rules));

         this.dispatchEvent(new CustomEvent('rulesupdate',{
               detail: this.rules
         }));
    }
}