import { LightningElement, track, api } from 'lwc';

export default class AssessmentWizardScoreTranslation extends LightningElement {
    colorOptions = [
        {label:"Red", value:"Red"},
        {label:"Orange", value:"Orange"},
        {label:"Yellow", value:"Yellow"},
        {label:"Light Green", value:"LightGreen"},
        {label:"Green", value:"Green"}
    ];
    @track scoringData = [
        {
            seq : 1,
            minScore : "",
            maxScore : "",
            color : "",
            status : ""
        }
    ];

    @api existingScores;
    @api isSubmit;

    connectedCallback(){
        if(this.existingScores && this.existingScores.length){
            this.scoringData = JSON.parse(JSON.stringify(this.existingScores));
        }
    }

    addRow(){
        this.scoringData.push(
            {
                seq : 1,
                minScore : "",
                maxScore : "",
                color : "",
                status : ""
            }
        );
        this.resetSeq();
    }

    handleChange(event){
        let targetname = event.target.name;
        let seq = event.currentTarget.dataset.scoreSeq;
        let inputvalue = event.target.value;
        if(targetname == 'minscore'){
            this.scoringData[seq-1].minScore = inputvalue;
        }else if(targetname == 'maxscore'){
            this.scoringData[seq-1].maxScore = inputvalue;
        }else if(targetname == 'color'){
            this.scoringData[seq-1].color = inputvalue;
        }else if(targetname == 'status'){
            this.scoringData[seq-1].status = inputvalue;
        }
        
        this.dispatchEvent(new CustomEvent('scoringdata', {
            detail: this.scoringData
        }));
    }

    deleteRow(event){
        if(this.scoringData.length !== 1){
            let removeId = event.currentTarget.dataset.id;
            this.scoringData.splice(removeId-1,1);
            this.resetSeq();
        }
    }

    resetSeq(){
        let seq = 1;
        this.scoringData.forEach(score => {
            score.seq = seq;
            seq++;
        });
    }
}