import { LightningElement, track, api, wire } from 'lwc';

export default class CustomMultiselectPicklist extends LightningElement {
    @api availableOptions;
    @api selectedOptions = [];
    @api showMandatory;
    @api showEditable;
    @api showDefaultVal;
    @api
    getSelectedOptions() {
        return this.selectedOptions;
    }

    handleScroll(event) {
        if(this.showMandatory)
        {
        const container = this.template.querySelector('.selected-options');
        const syncContent = this.template.querySelector('.mark-mandatory');
        syncContent.scrollTop = container.scrollTop;
        }
        if(this.showEditable)
        {
        const container = this.template.querySelector('.selected-options');
        const syncContent = this.template.querySelector('.mark-editable');
        syncContent.scrollTop = container.scrollTop;

        }
    }

    handleCheckboxChange(event) {
        try {
            const optionValue = event.target.dataset.id;
            const optionType = event.target.dataset.name;
            this.updateCheckBoxVal(optionValue, optionType, event.target.checked);

        } catch (error) {
            console.error('Error occured in handleCheckboxChange ::' + this.getErrorMessage(error));
        }
    }


    handleDragStart(event) {
        event.dataTransfer.setData('text', event.target.dataset.value);
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDropAvailable(event) {
        event.preventDefault();
        const value = event.dataTransfer.getData('text');
        const selectedOption = this.selectedOptions.find(option => option.value === value);
        let newSelectedOption = { label: selectedOption.label, 
        value: selectedOption.value, 
        isMandatory: selectedOption.isMandatory, 
        isEditable : selectedOption.isEditable,
        dataType: selectedOption.dataType, 
        isFormulaField : selectedOption.isFormulaField,
        isEditDisabled: selectedOption.isEditDisabled,
        isReqDisabled: selectedOption.isReqDisabled};

        if (newSelectedOption) {
            this.selectedOptions = this.selectedOptions.filter(option => option.value !== value);
            this.availableOptions = [...this.availableOptions, newSelectedOption];
        }
        console.log('Available options handleDropAvailable: ' + JSON.stringify(this.availableOptions));
        console.log('Selected options handleDropAvailable: ' + JSON.stringify(this.selectedOptions));
    }

    handleDropSelected(event) {
        try {
            event.preventDefault();
            const value = event.dataTransfer.getData('text');
            var selectedOption = this.availableOptions.find(option => option.value === value);
            if (selectedOption) {
                this.availableOptions = this.availableOptions.filter(option => option.value !== value);
                this.selectedOptions = [...this.selectedOptions, selectedOption];
            }
          // this.updateCheckBoxVal(value, null ,false);
            console.log('Available options handleDropSelected: ' + JSON.stringify(this.availableOptions));
            console.log('Selected options handleDropSelected: ' + JSON.stringify(this.selectedOptions));
        } catch (error) {
            console.error('Error in handleDropSelected ::' + this.getErrorMessage(error));
        }
    }

    updateCheckBoxVal(optionValue, optionType, isChecked) {
        const index = this.selectedOptions.findIndex(opt => opt.value === optionValue);
        if (index !== -1) {
            let updatedOption = {};
            if(optionType == 'mandatoryCheckbox')
            {
               updatedOption =  { ...this.selectedOptions[index], 
               isMandatory: isChecked, 
               isEditable: true, 
               isEditDisabled : isChecked };

            }
            else if(optionType == 'editCheckbox')
            {
                updatedOption =  { ...this.selectedOptions[index],  isEditable: isChecked };

            }
            else
            {
                updatedOption =  { ...this.selectedOptions[index], isMandatory: isChecked, isEditable: !isChecked, isEditDisabled : this.selectedOptions[index].isEditDisabled, isReqDisabled: this.selectedOptions[index].isReqDisabled }; 

            }
             
            this.selectedOptions = [
                ...this.selectedOptions.slice(0, index),
                updatedOption,
                ...this.selectedOptions.slice(index + 1)
            ];
        }
    }

    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred';
    }
}