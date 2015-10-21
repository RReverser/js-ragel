%%{
machine javascript;

getkey data[p];
access this.;
alphtype u8;

action lookahead { fhold; }
action strict { strict }

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
	LF |
	CR ^LF @lookahead
	LS |
	PS |
	CR LF;

HexEscapeSequence =
	'x' xdigit{2};

UnicodeEscapeSequence =
	'u' xdigit{4}
	'u{' xdigit+ '}';

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
		DecimalIntegerLiteral ('.' digit*)? |
		'.' digit+
	)
	ExponentPart?;

BinaryIntegerLiteral =
	'0' [bB] [01]+;

OctalIntegerLiteral =
	'0' [oO] [0-7]+;

HexIntegerLiteral =
	'0' [xX] xdigit+;

NumericLiteral =
	DecimalLiteral |
	BinaryIntegerLiteral |
	OctalIntegerLiteral |
	HexIntegerLiteral;

LineContinuation = '\\' LineTerminatorSequence;

SingleEscapeCharacter = ['"\\bfnrtv];

EscapeCharacter =
	SingleEscapeCharacter |
	digit |
	[xu];

NonEscapeCharacter = ^(EscapeCharacter | LineTerminator);

CharacterEscapeSequence =
	SingleEscapeCharacter
	NonEscapeCharacter;

EscapeSequence =
	CharacterEscapeSequence |
	'0' ^digit @lookahead |
	HexEscapeSequence |
	UnicodeEscapeSequence;

DoubleStringCharacter =
	^('"' | '\\' | LineTerminator) |
	'\\' EscapeSequence |
	LineContinuation;

SingleStringCharacter =
	^("'" | '\\' | LineTerminator) |
	'\\' EscapeSequence |
	LineContinuation;

StringLiteral =
	'"' DoubleStringCharacter* '"' |
	"'" SingleStringCharacter* "'";

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
	'$' ^'{' @lookahead |
	'\\' EscapeSequence |
	LineContinuation |
	LineTerminatorSequence |
	^([`\\$] | LineTerminator);

Template =
	'`' @{ this.tmplLevel++; } TemplateCharacter* ('`' | '${');

TemplateSubstitutionTail =
	'}' TemplateCharacter* ('${' | '`' @{ this.tmplLevel--; });

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
		this.push({ raw: data.slice(this.ts, p).toString() });
		this.ts = -1;
	}
)**;

write data;
}%%

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
	}

	_exec(data, isLast, callback) {
		let p = this.lastChunk.length;
		const pe = p + data.length;
		const eof = isLast ? pe : -1;
		data = Buffer.concat([ this.lastChunk, data ], pe);
		%%write exec;
		if (this.cs === 0 || isLast && this.ts >= 0) {
			return callback(new Error('Could not parse token starting with ' + JSON.stringify(data.slice(this.ts).toString())));
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
