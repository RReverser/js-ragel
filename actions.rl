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
    onToken({
        type: 'LineTerminatorSequence'
    });
}

action onMultiLineComment {
    onToken({
        type: 'MultiLineComment',
        value: data.slice(this.ts + 2, this.te)
    });
}

action onSingleLineComment {
    onToken({
        type: 'SingleLineComment',
        value: data.slice(this.ts + 2, this.te - 2)
    });
}

action onIdentifierName {
    onToken({
        type: 'IdentifierName',
        value: this.string
    });
}

action onPunctuator {
    onToken({
        type: 'Punctuator'
    });
}

action onNumericLiteral {
    onToken({
        type: 'NumericLiteral',
        value: this.number
    });
}

action onStringLiteral {
    onToken({
        type: 'StringLiteral',
        value: this.string
    });
}

action onNoSubstitutionTemplate {
    onToken({
        type: 'NoSubstitutionTemplate',
        value: this.string
    });
}

action onTemplateHead {
    onToken({
        type: 'TemplateHead',
        value: this.string
    });
}

action onTemplateMiddle {
    onToken({
        type: 'TemplateMiddle',
        value: this.string
    });
}

action onTemplateTail {
    onToken({
        type: 'TemplateTail',
        value: this.string
    });
}

action onRegularExpressionLiteral {
    onToken({
        type: 'RegularExpressionLiteral',
        body: data.slice(this.ts + 1, this.te - this.string.length - 1),
        flags: this.string
    });
}
}%%