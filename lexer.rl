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
}

action appendChar {
	this.string += String.fromCharCode(fc);
}

action startLocalHex {
	var hexNumber = 0;
}

action parseLocalHex {
	hexNumber <<= 4;
	var c = fc;
	if (c >= CHR_a) {
		hexNumber |= c - CHR_a;
	} else if (c >= CHR_A) {
		hexNumber |= c - CHR_A;
	} else {
		hexNumber |= c - CHR_0;
	}
}

include "unicode.rl";

TAB = '\t';
VT = '\v';
FF = '\f';
SP = ' ';
LF = '\n';
CR = '\r';

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
	) %{ this.string += '\n'; } |
	LS %{ this.string += '\u2028'; } |
	PS %{ this.string += '\u2029'; };

HexEscapeSequence =
	'x' xdigit{2} >startLocalHex $parseLocalHex %{
		this.string += String.fromCharCode(hexNumber);
	};

UnicodeEscapeSequence =
	'u' xdigit{4} >startLocalHex $parseLocalHex %{
		this.string += String.fromCharCode(hexNumber);
	} |
	'u{' xdigit+ >startLocalHex $parseLocalHex %{
		this.string += String.fromCodePoint(hexNumber);
	} '}';

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
	'0' [xX] xdigit+ >startLocalHex $parseLocalHex %{ this.number = hexNumber; };

NumericLiteral =
	DecimalLiteral |
	BinaryIntegerLiteral |
	OctalIntegerLiteral |
	HexIntegerLiteral;

LineContinuation = '\\' LineTerminatorSequence;

SingleEscapeCharacter =
	["'\\] @appendChar |
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
	^(EscapeCharacter | LineTerminator) @appendChar;

CharacterEscapeSequence =
	SingleEscapeCharacter |
	NonEscapeCharacter;

EscapeSequence =
	CharacterEscapeSequence |
	'0' ^digit @lookahead %{ this.string += '\0'; } |
	HexEscapeSequence |
	UnicodeEscapeSequence;

DoubleStringCharacter =
	^('"' | '\\' | LineTerminator) @appendChar |
	'\\' EscapeSequence |
	LineContinuation;

SingleStringCharacter =
	^("'" | '\\' | LineTerminator) @appendChar |
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
	'$' ^'{' @lookahead @appendChar |
	'\\' EscapeSequence |
	LineContinuation |
	LineTerminatorSequence |
	^([`\\$] | LineTerminator) @appendChar;

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

		this.number = 0;
		this.string = '';
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
