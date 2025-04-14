import { LightningElement, api, wire, track } from 'lwc';
import getAssignedWorker from '@salesforce/apex/PlanWizController.getAssignedWorker';
//import saveStep from '@salesforce/apex/ServicePlanWizController.saveStep';

export default class PlanWizAddSteps extends LightningElement {
    @api stepId = ''; @api recordId; @api clientName; @api goalId; @api stepRecord;@api objectApiName;
    message; error;
    allGood = true; allFieldsEmpty = true;
    @track assignedToOptions = [];
    deleteStep = false;
    @api stepType;
    descVal; @api startDateVal; targetDateVal; @api assignedToVal; statusVal; @api numVal;asseVal;serVal;docVal;typeaction;
    /* ------------------------------------ */
    stepType;
    
    // Added by Anubhav
    @track actionableoptions = [
        { label: 'Actionable Task', value: 'Actionable Task' },
        { label: 'Step', value: 'Step' },
    ];

    stepSelectedType;
    stepSelectedTypeNormal;
    normalSelected=false;
    actionableSelected=false;
    referralSelected=false;
    serviceSelected=false;
    documentSelected=false;
    assessmentSelected=false;
    selectActionRadio=true;
   //End
   connectedCallback(){
    //console.log('selectActionRadio =>'+selectActionRadio);
    //console.log('actionableSelected =>'+actionableSelected);
   }
    @wire(getAssignedWorker, {asId: '$recordId' , objectApiName: '$objectApiName'})
    wiredGetAssignedWorker (result)
    {
        if (result.data)
        {
            if (this.clientName != null)
            {
                this.assignedToOptions = [...this.assignedToOptions, {label: this.clientName, value: this.clientName}];
            }
            this.assignedToOptions = [...this.assignedToOptions, {label: result.data, value: result.data}];

            if (this.assignedToOptions.find(ele => ele.label == this.assignedToVal) == undefined && (this.assignedToVal != null && this.assignedToVal != '' && this.assignedToVal != undefined))
            {
                this.assignedToOptions = [...this.assignedToOptions, {label: this.assignedToVal, value: this.assignedToVal}];
            }
        }
        else if (result.error)
        {
            this.assignedToOptions = [...this.assignedToOptions, {label: this.clientName, value: this.clientName}];
            this.error = result.error;
            console.log('## wiredGetAssignedWorker error: ' + JSON.stringify(result.error));
        }
    }

    @api submitFromParent (listGoalIds) {
        var returnArray = {"Message" : "Good"};
        this.allFieldsEmpty = true;

        //check if any field is non-empty
        for (let i = 0; i < this.template.querySelectorAll('lightning-input-field').length; i++)
        {
            if (this.template.querySelectorAll('lightning-input-field')[i].value != null && 
                this.template.querySelectorAll('lightning-input-field')[i].value != '' &&
                this.template.querySelectorAll('lightning-input-field')[i].name != 'stepNum') 
            {
                console.log('## not empty');
                console.log('## val: ' + this.template.querySelectorAll('lightning-input-field')[i].value);
                this.allFieldsEmpty = false;
                break;
            }
        }
        if (this.assignedToVal != null && this.assignedToVal != undefined && this.assignedToVal != 'undefined') this.allFieldsEmpty = false;
        console.log('#### allFieldsEmpty: ' + this.allFieldsEmpty);

        if (!this.allFieldsEmpty)   //atleast 1 field was non-empty
        {
            //check if required fields are empty
            for (let i = 0; i < this.template.querySelectorAll('lightning-input-field').length; i++)
            {
                if (this.template.querySelectorAll('lightning-input-field')[i].name === "description" ||
                    this.template.querySelectorAll('lightning-input-field')[i].name === "status")
                {
                    if (this.template.querySelectorAll('lightning-input-field')[i].value == null ||
                        this.template.querySelectorAll('lightning-input-field')[i].value == '') //required field is empty
                    {
                        console.log('## ng: ' + this.template.querySelectorAll('lightning-input-field')[i].value);
                        this.allGood = false;
                        this.message = 'Please enter all the required fields.';
                        break;
                    }
                    else this.allGood = true;
                }

                //get values of fields
                if (this.template.querySelectorAll('lightning-input-field')[i].name === "description") this.descVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "startDate") this.startDateVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "targetDate") this.targetDateVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "status") this.statusVal = this.template.querySelectorAll('lightning-input-field')[i].value;
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "Assessment") this.asseVal = this.template.querySelectorAll('lightning-input-field')[i].value; // Added By Anubhav
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "Document") this.docVal = this.template.querySelectorAll('lightning-input-field')[i].value;    // Added By Anubhav
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "Service") this.serVal = this.template.querySelectorAll('lightning-input-field')[i].value;     // Added By Anubhav
                else if (this.template.querySelectorAll('lightning-input-field')[i].name === "action") this.typeaction = this.template.querySelectorAll('lightning-input-field')[i].value;  // Added By Anubhav
            }
            
            //check if 'Assigned To' is empty
            if ((this.assignedToVal == null || this.assignedToVal == undefined || this.assignedToVal == 'undefined') && this.stepSelectedTypeNormal=='undefined')
            {
                console.log('stepSelectedTypeNormal =>'+this.stepSelectedTypeNormal);
                this.allGood = false;
                this.message = 'Please enter all the required fields.';
            }

            //Target Date Validations
            if (this.targetDateVal != null && this.targetDateVal != undefined)
            {
                let todayDate = new Date();
                if (new Date(this.targetDateVal) <= todayDate)
                {
                    this.allGood = false;
                    this.message = 'Target Date must be greater than today\'s date.';
                }
                else if ((this.startDateVal != null && this.startDateVal != undefined) && this.targetDateVal < this.startDateVal)
                {
                    this.allGood = false;
                    this.message = 'Target Date must be greater than the Start Date.';
                }
            }

            console.log('## allGood: ' + this.allGood);

            // if all required fields are filled
            if (this.allGood)
            {
                let fields = {
                    "caresp__Description__c": this.descVal,
                    "caresp__Start_Date__c": this.startDateVal,
                    "caresp__Target_Date__c": this.targetDateVal,
                    "caresp__Assigned_To__c": this.assignedToVal,
                    "caresp__Status__c": this.statusVal,
                    "caresp__Step_Num__c": this.numVal,
                    "caresp__Assessment__c": this.asseVal, // Added By Anubhav
                    "caresp__Type_of_Action__c":this.typeaction, // Added By Anubhav
                   // "Service__c":this.serVal, // Added By Anubhav
                    "caresp__Document_Type__c":this.docVal, // Added By Anubhav
                    "caresp__Step_Type__c":this.stepSelectedTypeNormal 
                }
                if (this.stepId != '' && this.stepId != null)
                {
                    fields.Id = this.stepId;
                }else if (this.typeaction === null || this.typeaction === "") {
                    fields["caresp__Type_of_Action__c"] = "Step";
                } else {
                    fields["caresp__Type_of_Action__c"] = this.typeaction;
                }

                returnArray = {
                    "Message" : "Good",
                    "fields" : fields
                };
            }
            else    // required fields are not filled
            {
                //returnString = 'Not Good';
                returnArray = {"Message" : "Not Good"};
            }
        }
        else    //whole form is empty
        {
            //returnString = 'Good';
            returnArray = {"Message" : "Empty"};
        }

        //return returnString;
        return returnArray;
    }

    handleStepLoad (event) {
        if (this.stepId != '' && this.stepId != null)
        {
            console.log('## step: ' + JSON.stringify(this.stepRecord));
            this.descVal = this.stepRecord.caresp__Description__c;

            this.startDateVal = this.stepRecord.caresp__Start_Date__c;
            this.targetDateVal = this.stepRecord.caresp__Target_Date__c;
            this.statusVal = this.stepRecord.caresp__Status__c;
            this.docVal = this.stepRecord.caresp__Document_Type__c;
           // this.serVal = this.stepRecord.Service__c;
            this.typeaction= this.stepRecord.caresp__Type_of_Action__c;
            this.stepType = this.stepRecord.caresp__Step_Type__c;
            this.asseVal = this.stepRecord.caresp__Assessment__c;
            this.stepSelectedTypeNormal= this.stepRecord.caresp__Step_Type__c;
            
            this.normalSelected=false;
            this.actionableSelected=false;
            this.referralSelected = false;
            this.serviceSelected = false;
            this.selectActionRadio=false;
            this.documentSelected=false;
            this.assessmentSelected=false;
            this.stepSelectedType=this.typeaction;
            if( this.stepType != 'Step')
            {
            if(this.typeaction == 'Create Referral'){
                this.referralSelected = true;
            }
            else if (this.typeaction === 'Enroll in Service') {
                this.serviceSelected = true;
            }
            else if (this.typeaction === 'Upload Document') {
                this.documentSelected=true;
            }
            else if (this.typeaction === 'Conduct Assessment') {
                this.assessmentSelected=true;
            }
            else if ((this.typeaction === null || this.typeaction=== undefined)) {
                this.stepSelectedTypeNormal='Step';
                this.normalSelected=true;
            }
            }
            else{
                this.stepSelectedTypeNormal='Step';
                this.normalSelected=true;
            }
        }
    }

    handleAssignedToChange (event) {
        this.assignedToVal = event.detail.value;
    }

    handleDeleteStep () {
        this.deleteStep = true;
    }

    handleDeleteStepNo () {
        this.deleteStep = false;
    }
//Added By Anubhav
    handleActionableSelection (event){
        //this.actionablevalue = event.detail.value;
        this.stepSelectedTypeNormal=event.target.value;
        console.log('stepSelectedTypeNormal = >'+this.stepSelectedTypeNormal);
        if(event.target.value==='Step'){
            this.normalSelected=true;
            this.actionableSelected=false;
            this.referralSelected = false;
            this.serviceSelected = false;
            this.selectActionRadio=false;
            this.documentSelected=false;
            this.assessmentSelected=false;
        } else if (event.target.value === 'Actionable Task') {
            this.normalSelected=false;
            this.actionableSelected=true;
            this.referralSelected = false;
            this.serviceSelected = false;
            this.selectActionRadio=false;
            this.documentSelected=false;
            this.assessmentSelected=false;
            console.log('actionableSelected>>' +  this.actionableSelected);
        }
    }

    handelTypeSelected (event){
        this.stepSelectedType=event.detail.value;
        this.typeaction=event.detail.value;
        if (event.detail.value === 'Create Referral') {
            this.referralSelected = true;
            this.serviceSelected = false;
            this.documentSelected=false;
            this.assessmentSelected=false;
            this.actionableSelected=false;             
        }else if (event.detail.value === 'Enroll in Service') {
            this.referralSelected = false;
            this.serviceSelected = true;
            this.documentSelected=false;
            this.assessmentSelected=false;
            this.actionableSelected=false;             
        }else if (event.detail.value === 'Upload Document') {
            this.referralSelected = false;
            this.serviceSelected = false;
            this.documentSelected=true;
            this.assessmentSelected=false;
            this.actionableSelected=false;                          
        }else if (event.detail.value === 'Conduct Assessment') {
            this.referralSelected = false;
            this.serviceSelected = false; 
            this.documentSelected = false;
            this.assessmentSelected=true;
            this.actionableSelected=false;                            
        }
    }

    handleBack(){
    this.normalSelected=false;
    this.actionableSelected=false;
    this.referralSelected=false;
    this.serviceSelected=false;
    this.documentSelected=false;
    this.assessmentSelected=false;
    this.selectActionRadio=true; 
    }
  //End
}