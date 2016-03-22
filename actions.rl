%%{
machine javascript;

access this.;
variable pe data.length;
alphtype u16;

action inModule { this.goal === 'module' }
action inScript { this.goal === 'script' }
action lookahead { fhold; }
action strict { this.strict }
action permitRegexp { this.permitRegexp }
action forbidRegexp { !this.permitRegexp }
action permitTmplTail { this.tmplLevel }
action forbidTmplTail { !this.tmplLevel }

action rawSliceStart {
    this.rawSliceStart = p;
}

action rawSliceEnd {
    this.string += data.slice(this.rawSliceStart, p);
}

action rawSliceBinEnd {
    this.number = parseInt(data.slice(this.rawSliceStart, p), 2);
}

action rawSliceOctEnd {
    this.number = parseInt(data.slice(this.rawSliceStart, p), 8);
}

action rawSliceHexEnd {
    this.number = parseInt(data.slice(this.rawSliceStart, p), 16);
}

action rawSliceFloatEnd {
    this.number = parseFloat(data.slice(this.rawSliceStart, p));
}

action hexEscapeEnd {
    this.string += String.fromCharCode(this.number);
}

action regexpDelimiter {
    this.regexpDelimiterPos = p;
}

action stringStart {
    this.string = '';
}

action escapedChar {
    this.string += (0, eval)('"\\' + String.fromCharCode(fc) + '"');
}

action stringLF {
    this.string += '\n';
}

action templateStart {
    this.tmplLevel++;
}

action templateEnd {
    this.tmplLevel--;
}

action onWhiteSpace {

}

action onLineTerminatorSequence {
    this.pushToken(data, {
        type: 'LineTerminatorSequence'
    });
}

action onMultiLineComment {
    this.pushToken(data, {
        type: 'MultiLineComment',
        value: data.slice(this.ts + 2, this.te)
    });
}

action onSingleLineComment {
    this.pushToken(data, {
        type: 'SingleLineComment',
        value: data.slice(this.ts + 2, this.te - 2)
    });
}

action onIdentifierName {
    this.pushToken(data, {
        type: 'IdentifierName',
        value: this.string
    });
}

action onPunctuator {
    this.pushToken(data, {
        type: 'Punctuator'
    });
}

action onNumericLiteral {
    this.pushToken(data, {
        type: 'NumericLiteral',
        value: this.number
    });
}

action onStringLiteral {
    this.pushToken(data, {
        type: 'StringLiteral',
        value: this.string
    });
}

action onNoSubstitutionTemplate {
    this.pushToken(data, {
        type: 'NoSubstitutionTemplate',
        value: this.string
    });
}

action onTemplateHead {
    this.pushToken(data, {
        type: 'TemplateHead',
        value: this.string
    });
}

action onTemplateMiddle {
    this.pushToken(data, {
        type: 'TemplateMiddle',
        value: this.string
    });
}

action onTemplateTail {
    this.pushToken(data, {
        type: 'TemplateTail',
        value: this.string
    });
}

action onRegularExpressionLiteral {
    this.pushToken(data, {
        type: 'RegularExpressionLiteral',
        body: data.slice(this.ts + 1, this.te - this.string.length - 1),
        flags: this.string
    });
}
}%%