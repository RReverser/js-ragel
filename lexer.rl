%%{
machine javascript;

getkey data[p];
access this.;
alphtype u8;

action lookahead { fhold; }
action strict { strict }

action startNumber {
	this.number = 0;
}

action startString {
	this.string = '';
	this.decoder.charReceived = this.decoder.charLength = 0;
}

action appendByte {
	this.string += this.decoder.write(fc);
}

action appendCharCode {
	this.string += String.fromCharCode(this.number);
}

action appendCodePoint {
	this.string += String.fromCodePoint(this.number);
}

include "unicode.rl";

TAB = '\t';
VT = '\v';
FF = '\f';
SP = ' ';
LF = '\n';
CR = '\r';

hexDigit =
	[0-9] @{ this.number = (this.number << 4) | (fc - CHR_0) } |
	[A-F] @{ this.number = (this.number << 4) | (fc - CHR_A) } |
	[a-f] @{ this.number = (this.number << 4) | (fc - CHR_a) };

WhiteSpace =
	TAB |
	VT |
	FF |
	SP |
	NBSP |
	ZWNBSP |
	USP;

LineTerminator =
	LF |
	CR |
	LS |
	PS;

LineTerminatorSequence =
	(
		LF |
		CR ^LF @lookahead |
		CR LF
	) @{ this.lineTerminator = '\n'; } |
	LS @{ this.lineTerminator = '\u2028'; } |
	PS @{ this.lineTerminator = '\u2029'; };

HexEscapeSequence =
	'x' hexDigit{2} >startNumber %appendCharCode;

UnicodeEscapeSequence =
	'u' hexDigit{4} >startNumber @appendCharCode |
	'u{' hexDigit+ >startNumber '}' @appendCodePoint;

MultiLineComment = '/*' any* :>> '*/';

SingleLineComment = '//' (^LineTerminator)*;

Comment =
	MultiLineComment |
	SingleLineComment;

IdentifierStart =
	UnicodeIDStart |
	[$_] |
	'\\' UnicodeEscapeSequence;

IdentifierPart =
	UnicodeIDContinue |
	[$_] |
	'\\' UnicodeEscapeSequence |
	ZWNJ |
	ZWJ;

IdentifierName = IdentifierStart IdentifierPart*;

Keyword =
	'break'      | 'do'      | 'in'         | 'typeof' |
	'case'       | 'else'    | 'instanceof' | 'var'    |
	'catch'      | 'export'  | 'new'        | 'void'   |
	'class'      | 'extends' | 'return'     | 'while'  |
	'const'      | 'finally' | 'super'      | 'with'   |
	'continue'   | 'for'     | 'switch'     | 'yield'  |
	'debugger'   | 'function'| 'this'       |
	'default'    | 'if'      | 'throw'      |
	'delete'     | 'import'  | 'try'        ;

FutureReservedWord =
	'enum'       | 'await'   |
	(
	'implements' | 'package' | 'protected'  |
	'interface'  | 'private' | 'public'     
	) when strict;

Punctuator =
	'{'   | '}'    | '('   | ')'   | '['   | ']'   |
	'.'   | ';'    | ','   | '<'   | '>'   | '<='  |
	'>='  | '=='   | '!='  | '===' | '!==' |
	'+'   | '-'    | '*'   | '%'   | '++'  | '--'  |
	'<<'  | '>>'   | '>>>' | '&'   | '|'   | '^'   |
	'!'   | '~'    | '&&'  | '||'  | '?'   | ':'   |
	'='   | '+='   | '-='  | '*='  | '%='  | '<<=' |
	'>>=' | '>>>=' | '&='  | '|='  | '^='  | '=>'  ;

DivPunctuator =
	'/' |
	'/=';

RightBracePunctuator = '}';

NullLiteral = 'null';

BooleanLiteral =
	'true' |
	'false';

ReservedWord =
	Keyword |
	FutureReservedWord |
	NullLiteral |
	BooleanLiteral;

DecimalIntegerLiteral =
	'0' |
	(digit - '0') digit*;

SignedInteger =
	[+\-]? digit+;

ExponentPart =
	[eE] SignedInteger;

DecimalLiteral =
	(
		(
			DecimalIntegerLiteral ('.' digit*)? |
			'.' digit+
		)
		ExponentPart?
	) %{ this.number = parseFloat(data.slice(this.ts, p)); };

BinaryIntegerLiteral =
	'0' [bB] [01]+ >startNumber ${ this.number = (this.number << 1) | (fc - CHR_0); };

OctalIntegerLiteral =
	'0' [oO] [0-7]+ >startNumber ${ this.number = (this.number << 3) | (fc - CHR_0); };

HexIntegerLiteral =
	'0' [xX] hexDigit+ >startNumber;

NumericLiteral =
	(
		DecimalLiteral |
		BinaryIntegerLiteral |
		OctalIntegerLiteral |
		HexIntegerLiteral
	) ^(IdentifierStart | digit) @lookahead;

LineContinuation = '\\' LineTerminatorSequence;

SingleEscapeCharacter =
	["'\\] @appendByte |
	'b' @{ this.string += '\b'; } |
	'f' @{ this.string += '\f'; } |
	'n' @{ this.string += '\n'; } |
	'r' @{ this.string += '\r'; } |
	't' @{ this.string += '\t'; } |
	'v' @{ this.string += '\v'; };

EscapeCharacter =
	SingleEscapeCharacter |
	digit |
	[xu];

NonEscapeCharacter =
	^(EscapeCharacter | LineTerminator) @appendByte;

CharacterEscapeSequence =
	SingleEscapeCharacter |
	NonEscapeCharacter;

EscapeSequence =
	CharacterEscapeSequence |
	'0' ^digit @lookahead @{ this.string += '\0'; } |
	HexEscapeSequence |
	UnicodeEscapeSequence;

DoubleStringCharacter =
	^('"' | '\\' | LineTerminator) @appendByte |
	'\\' EscapeSequence |
	LineContinuation;

SingleStringCharacter =
	^("'" | '\\' | LineTerminator) @appendByte |
	'\\' EscapeSequence |
	LineContinuation;

StringLiteral =
	'"' DoubleStringCharacter* >startString '"' |
	"'" SingleStringCharacter* >startString "'";

RegularExpressionNonTerminator = ^LineTerminator;

RegularExpressionBackslashSequence =
	'\\' RegularExpressionNonTerminator;

RegularExpressionClassChar =
	RegularExpressionNonTerminator - [\]\\] |
	RegularExpressionBackslashSequence;

RegularExpressionClass = '[' RegularExpressionClassChar* ']';

RegularExpressionChar =
	RegularExpressionNonTerminator - [\\/[] |
	RegularExpressionBackslashSequence |
	RegularExpressionClass;

RegularExpressionFirstChar =
	RegularExpressionChar - '*';

RegularExpressionFlags = IdentifierPart*;

RegularExpressionBody =
	RegularExpressionFirstChar RegularExpressionChar*;

RegularExpressionLiteral =
	'/' RegularExpressionBody '/' RegularExpressionFlags;

TemplateCharacter =
	'$' ^'{' @lookahead @appendByte |
	'\\' EscapeSequence |
	LineContinuation |
	LineTerminatorSequence @{ this.string += this.lineTerminator; } |
	^([`\\$] | LineTerminator) @appendByte;

Template =
	'`' @{ this.tmplLevel++; } TemplateCharacter* >startString ('`' | '${');

TemplateSubstitutionTail =
	'}' TemplateCharacter* >startString ('${' | '`' @{ this.tmplLevel--; });

CommonToken =
	IdentifierName |
	Punctuator |
	NumericLiteral |
	StringLiteral |
	Template;

InputElement =
	WhiteSpace |
	LineTerminator |
	Comment |
	CommonToken |
	RegularExpressionLiteral when { this.permitRegexp } |
	DivPunctuator when { !this.permitRegexp } |
	TemplateSubstitutionTail when { this.tmplLevel } |
	RightBracePunctuator when { !this.tmplLevel };

main := (
	InputElement
	>{
		this.ts = p;
	}
	%{
		this.push({
			raw: data.slice(this.ts, p).toString(),
			lastNumber: this.number,
			lastString: this.string
		});
		this.ts = -1;
	}
)**;

write data;
}%%

const CHR_0 = '0'.charCodeAt(0);
const CHR_A = 'A'.charCodeAt(0);
const CHR_a = 'a'.charCodeAt(0);
const BUFFER_ZERO = new Buffer(0);

module.exports = class Lexer extends require('stream').Transform {
	constructor() {
		super({
			allowHalfOpen: false,
			objectMode: true
		});
		%%write init;
		this.ts = -1;
		this.tmplLevel = 0;
		this.permitRegexp = false;
		this.lastChunk = BUFFER_ZERO;
		this.decoder = new StringDecoder();

		this.number = 0;
		this.string = '';
		this.lineTerminator = '';
	}

	_exec(data, isLast, callback) {
		let p = this.lastChunk.length;
		const pe = p + data.length;
		const eof = isLast ? pe : -1;
		data = Buffer.concat([ this.lastChunk, data ], pe);
		%%write exec;
		if (this.cs === javascript_error || isLast && this.ts >= 0) {
			return callback(new Error('Could not parse token starting with ' + JSON.stringify(data.slice(this.ts).toString()) + ' (last pos: ' + (p - this.ts) + ')'));
		}
		this.lastChunk = data.slice(this.ts);
		this.ts = 0;
		callback();
	}

	_transform(data, enc, callback) {
		this._exec(data, false, callback);
	}

	_flush(callback) {
		this._exec(BUFFER_ZERO, true, callback);
	}
};
