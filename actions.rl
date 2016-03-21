%%{
machine javascript;

access this.;
variable pe data.length;
alphtype u16;

action lookahead { fhold; }
action strict { strict }
action permitRegexp { this.permitRegexp }
action forbidRegexp { !this.permitRegexp }
action permitTmplTail { this.tmplLevel }
action forbidTmplTail { !this.tmplLevel }

action hexNumberStart {
    this.hexNumber = 0;
}

action hexNumberEscapeEnd {
    this.string += String.fromCharCode(this.hexNumber);
}

action hexNumberEnd {
    this.number = this.hexNumber;
}

action numberStart {
    this.number = 0;
}

action hexNumber_09 {
    this.hexNumber = (this.hexNumber << 4) | (fc - CHR_0);
}

action hexNumber_AF {
    this.hexNumber = (this.hexNumber << 4) | (fc - CHR_A + 0xA);
}

action hexNumber_af {
    this.hexNumber = (this.hexNumber << 4) | (fc - CHR_a + 0xa);
}

action binNumberDigit {
    this.number = (this.number << 1) | (fc - CHR_0);
}

action octNumberDigit {
    this.number = (this.number << 3) | (fc - CHR_0);
}

action rawSliceStart {
    this.rawSliceStart = p;
}

action rawSliceEnd {
    this.string += data.slice(this.rawSliceStart, p);
    console.log('Added "%s" slice', data.slice(this.rawSliceStart, p));
}

action rawSliceFloatEnd {
    this.number = parseFloat(data.slice(this.rawSliceStart, p));
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