%%{
machine javascript;

getkey data[p];
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

MultiLineComment = '/*' any* '*/';

SingleLineComment = '//' (^LineTerminator)*;

Comment =
	MultiLineComment |
	SingleLineComment;

IdentifierStart = UnicodeIDStart | [$_] | '\\' UnicodeEscapeSequence;

IdentifierPart = UnicodeIDContinue | [$_] | '\\' UnicodeEscapeSequence | ZWNJ | ZWJ;

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

DivPunctuator = '/' | '/=';

RightBracePunctuator = '}';

NullLiteral = 'null';

BooleanLiteral = 'true' | 'false';

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

NoSubstitutionTemplate = '`' TemplateCharacter* '`';

TemplateHead = '`' TemplateCharacter* '${';

TemplateMiddle =
	'}' TemplateCharacter* '${';

TemplateTail =
	'}' TemplateCharacter* '`';

TemplateSubstitutionTail =
	TemplateMiddle |
	TemplateTail;

Template =
	NoSubstitutionTemplate
	TemplateHead;

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
	RegularExpressionLiteral when { permit & PERMIT_REGEXP } |
	DivPunctuator when { !(permit & PERMIT_REGEXP) }
	TemplateSubstitutionTail when { permit & PERMIT_TMPL_TAIL } |
	RightBracePunctuator when { !(permit & PERMIT_TMPL_TAIL) };

main := |*
	InputElement => { console.log(data.slice(ts, te)); };
*|;

write data;
}%%

var PERMIT_REGEXP = 1 << 0;
var PERMIT_TMPL_TAIL = 1 << 1;

module.exports = function (data) {
	'use strict';
	data = new Buffer(data);
	var cs, p = 0, pe = data.length, eof = pe, ts, te, act;
	var permit = 0;
	%%{
		write init;
		write exec;
	}%%
};

