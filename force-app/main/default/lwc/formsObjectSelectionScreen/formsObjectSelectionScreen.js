import { LightningElement, wire, track } from 'lwc';
import getObjectsList from '@salesforce/apex/ObjectInformationUtil.getObjectsList';
import getRelatedObjectsList from '@salesforce/apex/FormsController.getRelatedObjectsList';

export default class FormsObjectSelectionScreen extends LightningElement {
    @track objectList;
    objectName;
    objectListResult;
    error;
    @track dataStructure = {
        order : 1,
        objectName : "",
        type : 'primary',
        objectList : [],
        level : "level1",
        unique : "primary",
        allowChild : true,
        showRelated : false,
        relatedObjectList : [
            {
                order : 1.1,
                objectName : "",
                type : "",
                objectList : [],                         
                level : "level2",
                allowChild : false,
                showRelated : false,
                unique : ""                         //primary_child_1.1 or primary_parent_1.1
            }
        ]
    };

    @wire(getObjectsList)
    wiredObjects(result){
        this.objectListResult = result;
        if(result.data){
            let objList = JSON.parse(JSON.stringify(result.data));
            objList.sort((a, b) => (a.label > b.label) ? 1 : -1)
            //this.objectList = objList;
            this.dataStructure.objectList = objList;
            this.error = undefined;
        }else if(result.error){
            this.objectList = undefined;
            this.error = JSON.parse(JSON.stringify(result.error));
        }
    }

    get isLoading(){
        return !this.objectListResult.data || this.objectListResult.error;
    }

    handleOnChange(event){
        let picklistValue = event.detail.value;
        let type = event.detail.type;
        let level = event.detail.level;
        let unique = event.detail.unique;
        
        if(type == 'child'){
            let objListNode = this.getObjectListNode(level, unique);
        }
        
        this.dataStructure.objectName = picklistValue;
        getRelatedObjectsList({parentObjectName : this.dataStructure.objectName})
        .then(result => {
            this.dataStructure.relatedObjectList[0].objectList = JSON.parse(JSON.stringify(result));
            console.log("child obj list > ",JSON.stringify(this.dataStructure.relatedObjectList[0].objectList)); 
            this.dataStructure.relatedObjectList[0].showRelated = true;
        })
        .catch(error => {
            this.error = JSON.stringify(error);
            console.log("Error >> "+JSON.stringify(this.error));
        })
        console.log("picklistValue >> ",picklistValue);
    }

    getObjectListNode(level, unique, parent, grandparent){
        if(level == 'level1'){
            let pos = this.dataStructure.relatedObjectList.findIndex(related => related.unique == unique);
            return this.dataStructure.relatedObjectList[pos].objectList;
        }else if(level == 'level2'){
            let parentPos = this.dataStructure.relatedObjectList.findIndex(related => related.unique == parent);
            let pos = this.dataStructure.relatedObjectList[parentPos].findIndex(related => related.unique == parent);
        }
    }
}