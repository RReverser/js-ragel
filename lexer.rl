%%{
machine javascript;

getkey data[p];
access this.;
variable eof this.eof;
variable pe data.length;
alphtype u8;

action lookahead { fhold; }
action strict { strict }

action startNumber {
	this.token.number = 0;
}

action startHexNumber {
	this.hexNumber = 0;
}

action appendByte {
	this.decoder.writeBuffer(data.slice(p, p + 1));
}

action appendHexCharCode {
	this.decoder.writeString(String.fromCharCode(this.hexNumber));
}

action appendHexCodePoint {
	this.decoder.writeString(String.fromCodePoint(this.hexNumber));
}

action endString {
	this.token.string = this.decoder.end(true);
}

action startToken {
	ts = p;
}

action finishToken {
	this.token.raw = this.rawDecoder.end(true);
	this.push(this.token);
	this.token = {};
}

action readRaw {
	this.rawDecoder.writeBuffer(data.slice(rs, rs = p));
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
	) %readRaw %{
		this.token.number = parseFloat(this.rawDecoder.end(false));
	};

BinaryIntegerLiteral =
	'0' [bB] [01]+ >startNumber ${ this.token.number = (this.token.number << 1) | (fc - CHR_0); };

OctalIntegerLiteral =
	'0' [oO] [0-7]+ >startNumber ${ this.token.number = (this.token.number << 3) | (fc - CHR_0); };

HexIntegerLiteral =
	'0' [xX] hexDigit+ >startHexNumber %{ this.token.number = this.hexNumber; };

NumericLiteral =
	DecimalLiteral |
	BinaryIntegerLiteral |
	OctalIntegerLiteral |
	HexIntegerLiteral;

LineContinuation = '\\' LineTerminatorSequence;

SingleEscapeCharacter =
	["'\\] @appendByte |
	'b' @{ this.decoder.writeString('\b'); } |
	'f' @{ this.decoder.writeString('\f'); } |
	'n' @{ this.decoder.writeString('\n'); } |
	'r' @{ this.decoder.writeString('\r'); } |
	't' @{ this.decoder.writeString('\t'); } |
	'v' @{ this.decoder.writeString('\v'); };

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
	'0' ^digit @lookahead @{ this.decoder.writeString('\0'); } |
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
	'"' DoubleStringCharacter* %endString '"' |
	"'" SingleStringCharacter* %endString "'";

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
				this.decoder.writeString('\u2028');
				break;

			case 0xA9: // last byte of PS
				this.decoder.writeString('\u2029');
				break;

			default: // LF | CR LF | CR
				this.decoder.writeString('\n');
				break;
		}
	} |
	^([`\\$] | LineTerminator) @appendByte;

Template =
	'`' @{ this.tmplLevel++; } TemplateCharacter* %endString ('`' | '${');

TemplateSubstitutionTail =
	'}' TemplateCharacter* %endString ('${' | '`' @{ this.tmplLevel--; });

CommonToken =
	IdentifierName |
	Punctuator |
	NumericLiteral |
	StringLiteral |
	Template;

InputElement =
	WhiteSpace |
	LineTerminator |
	(
		Comment |
		CommonToken |
		RegularExpressionLiteral when { this.permitRegexp } |
		DivPunctuator when { !this.permitRegexp } |
		TemplateSubstitutionTail when { this.tmplLevel } |
		RightBracePunctuator when { !this.tmplLevel }
	) %readRaw %finishToken;

main := (
	InputElement >startToken
)** $!readRaw $!{
	return callback(new Error('Could not parse token ' + JSON.stringify(this.rawDecoder.end(false))));
};

write data;
}%%

const InternalStringDecoder = require('string_decoder').StringDecoder;

class StringDecoder {
	constructor() {
		this.buffer = '';
		this.internal = new InternalStringDecoder();
	}

	writeBuffer(chunk) {
		return this.buffer += this.internal.write(chunk);
	}

	end(reset) {
		let buffer = this.buffer += this.internal.end();
		this.internal.charReceived = this.internal.charLength = 0;
		if (reset) {
			this.buffer = '';
		}
		return buffer;
	}

	writeString(str) {
		return this.buffer = this.end(false) + str;
	}
}

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
		this.token = {};
		this.tmplLevel = 0;
		this.permitRegexp = false;
		this.decoder = new StringDecoder();
		this.rawDecoder = new StringDecoder();
		this.hexNumber = 0;
	}

	exec(data, callback) {
		let p = 0, ts = 0, rs = 0;
		%%write exec;
		this.rawDecoder.writeBuffer(data.slice(rs));
		callback();
	}

	_transform(data, enc, callback) {
		this.exec(data, callback);
	}

	_flush(callback) {
		this.eof = 0;
		this.exec(BUFFER_ZERO, callback);
	}
};
