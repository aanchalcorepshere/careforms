import { LightningElement, api, track } from 'lwc';

const delay = 350;

export default class CustomComboWithCategoryAndSearch extends LightningElement {
    //functional properties
    @api fieldLabel;
    @api disabled = false;
    @track openDropDown = false;
    @track inputValue = "";
    @api placeholder = "";
    //@api options;
    @track optionsToDisplay;

    delaytimeout;

    @api value = "";
    @track label = "";
    @api type;
    @api objId;
    @api level;
    @api parent;
    @api grandParent;
    @api options;

    @api objectsToFilter;

    //constructor
    constructor() {
        super();
    }

    connectedCallback() {
        //console.log('options >> ',JSON.stringify(this.options));
        let newArr = [];
        if(this.objectsToFilter && this.objectsToFilter.length){
            this.options.forEach(option => {
                let tempOutput = option.objectList.filter(obj => !this.objectsToFilter.includes(obj.value));
                let newObj = {};
                newObj.categoryName = option.categoryName;
                newObj.objectList = tempOutput.length ? tempOutput : [];
                newArr.push(newObj);
            })
            //console.log('newArr >> ',JSON.stringify(newArr));
            this.options = JSON.parse(JSON.stringify(newArr));
        }
        console.log('this.value >> ',this.value);
        this.label = this.value?this.value:null;
        this.setOptionsAndValues();
    }

    renderedCallback() {
        if (this.openDropDown) {
            this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                inputElem.focus();
            });
        }
    }

    //Public Method to set options and values
    setOptionsAndValues() {
        this.optionsToDisplay = (this.options && this.options.length > 0 ? this.options : []);
        /* if (this.value && this.value != "") {
            console.log("this.value >> ",this.value);
            let label = this.getLabel(this.value);
            if (label && label != "") {
                this.label = label;
                console.log("this.label >> ",this.label);
            }
        }
        else {
            this.label = "";
        } */
    }

    //Method to get Label for value provided
    /* getLabel(value) {
        this.options.forEach(option => {
            //console.log('option >> ',JSON.stringify(option));
            let selectedObjPos = option.objectList.findIndex(x => x.value == value);

            console.log('selectedObjPos >> ',JSON.stringify(selectedObjPos));
            if (selectedObjPos !== -1) {
                return option.objectList[selectedObjPos].label;
            }
        })
        return null;
    } */

    //Method to open listbox dropdown
   /* openDropDown(event) {
        this.toggleOpenDropDown(true);
    } */

    //Method to close listbox dropdown
    closeDropdown(event) {
	
        if (event.relatedTarget && event.relatedTarget.tagName == "UL" && event.relatedTarget.className.includes('customClass')) {
            if (this.openDropDown) {
                this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                    inputElem.focus();
                });
            }
        }
        else {
            window.setTimeout(() => {
                this.toggleOpenDropDown(false);
            }, 300);
        }
    }

    //Method to handle readonly input click
    handleInputClick(event) {
        this.resetParameters();
        this.toggleOpenDropDown(true);
    }

    //Method to handle key press on text input
    handleKeyPress(event) {
        const searchKey = event.target.value;
        this.setInputValue(searchKey);
        if (this.delaytimeout) {
            window.clearTimeout(this.delaytimeout);
        }

        this.delaytimeout = setTimeout(() => {
            //filter dropdown list based on search key parameter
            this.filterDropdownList(searchKey);
        }, delay);
    }

    //Method to filter dropdown list
    filterDropdownList(key) {
        let tempOptions = [];
        this.options.forEach( option => {
            let temp = {};
            temp.categoryName = option.categoryName;
            let filteredOptions = option.objectList.filter(item => item.label.toLowerCase().includes(key.toLowerCase()));
            temp.objectList = filteredOptions;
            tempOptions.push(temp);
        })
        this.optionsToDisplay = tempOptions;
    }

    //Method to handle selected options in listbox
    optionsClickHandler(event) {
        const value = event.target.closest('li').dataset.value;
        const label = event.target.closest('li').dataset.label;
        const category = event.target.closest('li').dataset.category;
        this.setValues(value, label);
        this.toggleOpenDropDown(false);
        const detail = {};
        console.log("value >> ",value);
        detail.value = value;
        detail.label = label;
        detail.type = category;
        detail.parent = this.parent;
        detail.grandParent = this.grandParent;
        detail.level = this.level;
        detail.id = this.objId;
        this.dispatchEvent(new CustomEvent('change', { detail: detail }));
    }

    //Method to reset necessary properties
    resetParameters() {
        this.setInputValue("");
        this.optionsToDisplay = this.options;
    }

    //Method to set inputValue for search input box
    setInputValue(value) {
        this.inputValue = value;
    }

    //Method to set label and value based on
    //the parameter provided
    setValues(value, label) {
        this.label = label;
        this.value = value;
    }

    //Method to toggle openDropDown state
    toggleOpenDropDown(toggleState) {
        this.openDropDown = toggleState;
    }

    //getter setter for labelClass
    get labelClass() {
        return (this.fieldLabel && this.fieldLabel != "" ? "slds-form-element__label slds-show" : "slds-form-element__label slds-hide")
    }

    //getter setter for dropDownClass
    get dropDownClass() {
        return (this.openDropDown ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click");
    }

    //getter setter for isValueSelected
    get isValueSelected() {
        return (this.label && this.label != "" ? true : false);
    }

    get isDropdownOpen() {
        return (this.openDropDown ? true : false);
    }
}