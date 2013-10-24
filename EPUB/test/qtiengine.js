
function queryParameters(query) {
    var keyValuePairs = query.split(/[&?]/g);
    var params = {
    };
    for (var i = 0, n = keyValuePairs.length; i < n;++ i) {
        var m = keyValuePairs[i].match(/^([^=]+)(?:=([\s\S]*))?/);
        if (m) {
            var key = decodeURIComponent(m[1]);
            (params[key] || (params[key] =[])).push(decodeURIComponent(m[2]));
        }
    }
    return params;
}

// First step; read the parameters from the query string
qs = queryParameters(document.location.search);

// Initialise a basic object to hold the values of the variables
variables = {
};

// and a list to make it easier to iterate over the classes of them
responseVariableList =[];
outcomeVariableList =[];

function QTIVariable(identifier, baseType, cardinality, defaultValue) {
    this.identifier = identifier;
    this.baseType = baseType;
    this.cardinality = cardinality;
    this.SetValue = SetValue;
    this.CompareValue = CompareValue;
    var value = qs[identifier];
    if (value != null && value.length > 0) {
        this.SetValue(value);
    } else {
        this.SetValue(defaultValue);
    }
    variables[identifier] = this;
    
    function SetValue(value) {
        if (value != null) {
            if (this.cardinality == 'single') {
                if (value.length > 1) {
                    alert('Unexpected multiple value for single-valued variable: ' + identifier + ' (' + value.join(',') + ')');
                }
            }
            this.value = value;
        } else {
            this.value =[];
        }
    };
    
    function CompareValue(value) {
        if (this.value.length != value.length) {
            return false;
        } else {
            for (var i = 0; i < value.length; i = i + 1) {
                if (this.value[i] != value[i]) {
                    return false;
                }
            }
            return true;
        }
    };
}

function ResponseVariable(identifier, baseType, cardinality, correctValue, defaultValue) {
    // Lazy inheritance
    this._parent = QTIVariable;
    this._parent(identifier, baseType, cardinality, defaultValue);
    // Response-specific methods
    this.ChoiceSelected = ChoiceSelected;
    this.Correct = Correct;
    this.SetMapping = SetMapping;
    this.MapResponse = MapResponse;
    responseVariableList.push(identifier);
    if (correctValue != null) {
        if (this.cardinality == 'single' && correctValue.length > 1) {
            alert('Unexpected multiple correct value for single-valued response: ' + identifier + ' (' + correctValue.join(',') + ')');
        }
        this.correctValue = correctValue;
    } else {
        this.correctValue =[];
    }
    this.hasMapping = false;
    
    function ChoiceSelected(choice) {
        if (this.value == null) {
            return false;
        } else {
            for (var i = 0; i < this.value.length; i = i + 1) {
                if (this.value[i] == choice) {
                    return true;
                }
            }
            return false;
        }
    }
    
    function Correct() {
        return this.CompareValue(this.correctValue);
    }
    
    function SetMapping(lowerBound, upperBound, scoreMap, defaultScore) {
        this.hasMapping = true;
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        this.scoreMap = scoreMap;
        this.defaultScore = defaultScore;
    }
    
    function MapResponse() {
        if (! this.hasMapping) {
            alert('No mapping available for response ' + this.identifier);
            return 0.0;
        } else {
            var score = 0.0;
            for (var i = 0; i < this.value.length; i = i + 1) {
                var valueScore = this.scoreMap[ this.value[i]];
                score = score + (valueScore == null? this.defaultScore: valueScore);
            }
            if (this.lowerBound != null) {
                score =(score < this.lowerBound)? this.lowerBound: score;
            }
            if (this.upperBound != null) {
                score =(score > this.upperBound)? this.upperBound: score;
            }
            return score;
        }
    }
}

function InitBuiltins() {
    // nothing to do yet
    var numAttempts = new ResponseVariable('numAttempts', 'integer', 'single', null,[ '0']);
    var input = document.getElementById('numAttempts');
    input.value = parseInt(numAttempts.value[0]) + 1;
}


// a list to make it easier to iterate over interactions
interactionList =[];

function ChoiceInteraction(identifier) {
    this.identifier = identifier;
    this.div = document.getElementById(identifier);
    this.choices = this.div.getElementsByTagName('input');
    // Determine the correct value (if we know it)
    var correctValue =[];
    // And build a score map
    var scoreMap = {
    };
    for (var i = 0; i < this.choices.length; i = i + 1) {
        // Each input element is a choice
        var input = this.choices[i];
        if (input.getAttribute('data-correct') == 'true') {
            correctValue.push(input.getAttribute('value'));
        }
        if (input.getAttribute('data-score') != null) {
            scoreMap[input.getAttribute('value')] = parseFloat(input.getAttribute('data-score'));
        }
    }
    this.variable = new ResponseVariable(identifier, this.div.getAttribute('data-baseType'), this.div.getAttribute('data-cardinality'), correctValue, null);
    var upperBound = parseFloat(this.div.getAttribute('data-upperBound'));
    if (upperBound == NaN) {
        upperBound = null
    }
    var lowerBound = parseFloat(this.div.getAttribute('data-lowerBound'));
    if (lowerBound == NaN) {
        lowerBound = null
    }
    var defaultScore = parseFloat(this.div.getAttribute('data-defaultValue'));
    if (defaultScore == NaN) {
        defaultScore = 0.0;
    }
    this.variable.SetMapping(lowerBound, upperBound, scoreMap, defaultScore);
    if (this.div.getAttribute('data-shuffle') == 'true') {
        var input = document.getElementById(identifier + '.seq');
        var sequence =[];
        var dl = this.div.getElementsByTagName('dl')[0];
        var dd = dl.getElementsByTagName('dd');
        if (variables.numAttempts.value[0] == 0) {
            for (var i = 0; i < dd.length; i++) {
                sequence.push(dd[i].getAttribute('data-fixed') != 'true');
            }
            sequence = Shuffle(sequence);
            // We need to submit this with the response so that we have it next time
            input.value = sequence.join('-');
            
            /*  We now transform this into a sequence of dd elements.  We must
            do this because the original array will change dynamically when
            we start changing the DOM below */
            for (var i = 0; i < sequence.length; i++) {
                sequence[i] = dd[sequence[i]];
            }
            //alert('Shuffled sequence: ' + sequence);
        } else {
            // read the sequence from the input parameters
            var value = qs[identifier + '.seq'];
            if (value == null && value.length > 1) {
                alert('Missing sequence for shuffling, ignoring shuffle for ' + identifier);
                for (var i = 0; i < dd.length; i++) {
                    sequence.push(dd[i]);
                }
            } else {
                // make sure we get this sequence next time too
                input.value = value[0];
                /* Now parse the sequence */
                sequence = value[0].split('-');
                for (var i = 0; i < sequence.length; i++) {
                    sequence[i] = dd[parseInt(sequence[i])];
                }
            }
        }
        // Now we can just append each dd in the new order
        for (var i = 0; i < sequence.length; i++) {
            dl.appendChild(sequence[i]);
        }
    }
    for (var i = 0; i < this.choices.length; i = i + 1) {
        var input = this.choices[i];
        input.checked = this.variable.ChoiceSelected(input.getAttribute('value'));
    }
    interactionList.push(this);
    
    
    function Shuffle(list) {
        // input: a boolean array indicating which positions should be shuffled (true)
        // output: an array of integers indicating the shuffled order
        var free =[];
        for (var i = 0; i < list.length; i++) {
            if (list[i]) {
                free.push(i);
            }
        }
        for (var j, x, i = free.length; i;) {
            j = parseInt(Math.random() * i);
            x = free[-- i];
            free[i] = free[j];
            free[j] = x;
        }
        var sequence =[];
        for (var i = 0, j = 0; i < list.length; i++) {
            if (list[i]) {
                sequence.push(free[j++]);
            } else {
                sequence.push(i);
            }
        }
        return sequence;
    }
}


function InitChoiceInteraction(identifier) {
    ci = new ChoiceInteraction(identifier);
}


function OutcomeVariable(identifier) {
    // Lazy inheritance
    this._parent = QTIVariable;
    this.dl = document.getElementById(identifier + '.value');
    var declaration = document.getElementById(identifier).getElementsByTagName('td');
    var dd = this.dl.getElementsByTagName('dd');
    var defaultValue =[];
    if (dd != null) {
        for (var i = 0; i < dd.length; i = i + 1) {
            defaultValue.push(dd[i].textContent);
        }
    }
    this._parent(identifier, declaration[1].textContent, declaration[2].textContent, defaultValue);
    this._SetValue = this.SetValue;
    this.SetValue = SetValue;
    
    function SetValue(value) {
        this._SetValue(value);
        if (this.value.length > 0) {
            this.dl.innerHTML = '<dd>' + this.value.join('</dd><dd>') + '</dd>';
        } else {
            this.dl.innerHTML = '';
        }
    }
}


function InitOutcome(identifier) {
    ov = new OutcomeVariable(identifier);
}


function ResponseProcessingTemplate(templateID) {
    if (templateID == 'http://www.imsglobal.org/question/qti_v2p1/rptemplates/match_correct') {
        MatchCorrect();
    } else if (templateID == 'http://www.imsglobal.org/question/qti_v2p1/rptemplates/map_response') {
        MapResponse();
    } else {
        alert('Unsupported template: ' + templateID);
    }
    
    function MatchCorrect() {
        response = variables.RESPONSE;
        outcome = variables.SCORE;
        if (response.Correct()) {
            outcome.SetValue([1]);
        } else {
            outcome.SetValue([0]);
        }
    }
    
    function MapResponse() {
        response = variables.RESPONSE;
        outcome = variables.SCORE;
        outcome.SetValue([response.MapResponse()]);
    }
}