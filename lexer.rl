%%{
machine javascript;

getkey data[p];
access this.;
variable eof this.eof;
alphtype u8;

action lookahead { fhold; }
action strict { strict }

action startNumber {
	this.token.number = 0;
}

action startHexNumber {
	this.hexNumber = 0;
}

action startString {
	this.token.string = '';
	this.decoder.charReceived = this.decoder.charLength = 0;
}

action appendByte {
	this.token.string += this.decoder.write(data.slice(p, p + 1));
}

action appendHexCharCode {
	this.token.string += String.fromCharCode(this.hexNumber);
}

action appendHexCodePoint {
	this.token.string += String.fromCodePoint(this.hexNumber);
}

action startToken {
	this.ts = p;
}

action finishToken {
	this.token.raw = data.slice(this.ts, p).toString();
	this.push(this.token);
	this.token = {};
}

include "unicode.rl";

TAB = '\t';
VT = '\v';
FF = '\f';
SP = ' ';
LF = '\n';
CR = '\r';

hexDigit =
	[0-9] @{ this.hexNumber = (this.hexNumber << 4) | (fc - CHR_0) } |
	[A-F] @{ this.hexNumber = (this.hexNumber << 4) | (fc - CHR_A) } |
	[a-f] @{ this.hexNumber = (this.hexNumber << 4) | (fc - CHR_a) };

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
	LF |
	CR ^LF @lookahead |
	CR LF |
	LS |
	PS;

HexEscapeSequence =
	'x' hexDigit{2} >startHexNumber @appendHexCharCode;

UnicodeEscapeSequence =
	'u' hexDigit{4} >startHexNumber @appendHexCharCode |
	'u{' hexDigit+ >startHexNumber '}' @appendHexCodePoint;

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
	) %{ this.token.number = parseFloat(data.slice(this.ts, p)); };

BinaryIntegerLiteral =
	'0' [bB] [01]+ >startNumber ${ this.token.number = (this.token.number << 1) | (fc - CHR_0); };

OctalIntegerLiteral =
	'0' [oO] [0-7]+ >startNumber ${ this.token.number = (this.token.number << 3) | (fc - CHR_0); };

HexIntegerLiteral =
	'0' [xX] hexDigit+ >startHexNumber %{ this.token.number = this.hexNumber; };

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
	'b' @{ this.token.string += '\b'; } |
	'f' @{ this.token.string += '\f'; } |
	'n' @{ this.token.string += '\n'; } |
	'r' @{ this.token.string += '\r'; } |
	't' @{ this.token.string += '\t'; } |
	'v' @{ this.token.string += '\v'; };

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
	'0' ^digit @lookahead @{ this.token.string += '\0'; } |
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
	LineTerminatorSequence @{
		switch (fc) {
			case 0xA8: // last byte of LS
				this.token.string += '\u2028';
				break;

			case 0xA9: // last byte of PS
				this.token.string += '\u2029';
				break;

			default: // LF | CR LF | CR
				this.token.string += '\n';
				break;
		}
	} |
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
	0x04 @{ process.stdin.setRawMode(false); process.stdin.end(); } |
	WhiteSpace |
	LineTerminator |
	(
		Comment |
		CommonToken |
		RegularExpressionLiteral when { this.permitRegexp } |
		DivPunctuator when { !this.permitRegexp } |
		TemplateSubstitutionTail when { this.tmplLevel } |
		RightBracePunctuator when { !this.tmplLevel }
	) %finishToken;

main := (
	InputElement >startToken
)** $!{
	return callback(new Error('Could not parse token starting with ' + JSON.stringify(data.slice(this.ts).toString()) + ' (last pos: ' + (p - this.ts) + ')'));
};

write data;
}%%

const StringDecoder = require('string_decoder').StringDecoder;

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
		this.eof = -1;
		this.ts = 0;
		this.token = {};
		this.tmplLevel = 0;
		this.permitRegexp = false;
		this.lastChunk = BUFFER_ZERO;
		this.decoder = new StringDecoder();
		this.hexNumber = 0;
	}

	_exec(data, callback) {
		let p = this.lastChunk.length;
		const pe = p + data.length;
		data = Buffer.concat([ this.lastChunk, data ], pe);
		%%write exec;
		this.lastChunk = data.slice(this.ts);
		this.ts = 0;
		callback();
	}

	_transform(data, enc, callback) {
		this._exec(data, callback);
	}

	_flush(callback) {
		this.eof = this.lastChunk.length;
		this._exec(BUFFER_ZERO, callback);
	}
};
