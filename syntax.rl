%%{
machine javascript;

include "actions.rl";

include "unicode.rl";

TAB = '\t';
VT = '\v';
FF = '\f';
SP = ' ';
LF = '\n';
CR = '\r';

hexDigit =
	[0-9] @hexNumber_09 |
	[A-F] @hexNumber_AF |
	[a-f] @hexNumber_af;

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
	'x' hexDigit{2} >hexNumberStart %hexNumberEscapeEnd;

UnicodeEscapeSequence =
	'u' hexDigit{4} >hexNumberStart %hexNumberEscapeEnd |
	'u{' hexDigit+ >hexNumberStart %hexNumberEscapeEnd '}';

MultiLineComment = '/*' any* :>> '*/';

SingleLineComment = '//' (^LineTerminator)*;

IdentifierStart =
	(
        UnicodeIDStart |
	    [$_]
    )+ >rawSliceStart %rawSliceEnd |
	'\\' UnicodeEscapeSequence;

UnescapedIdentifierPart =
    (
        UnicodeIDContinue |
        [$_] |
        ZWNJ |
        ZWJ
    )+ >rawSliceStart %rawSliceEnd;

IdentifierPart =
    UnescapedIdentifierPart |
	'\\' UnicodeEscapeSequence;

IdentifierName = ((IdentifierStart $1 %0)+ IdentifierPart**) >stringStart;

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
	'{'   | '('    | ')'   | '['   | ']'   |
	'.'   | ';'    | ','   | '<'   | '>'   | '<='  |
	'>='  | '=='   | '!='  | '===' | '!==' |
	'+'   | '-'    | '*'   | '%'   | '++'  | '--'  |
	'<<'  | '>>'   | '>>>' | '&'   | '|'   | '^'   |
	'!'   | '~'    | '&&'  | '||'  | '?'   | ':'   |
	'='   | '+='   | '-='  | '*='  | '%='  | '<<=' |
	'>>=' | '>>>=' | '&='  | '|='  | '^='  | '=>'  ;

DivPunctuator = '/' when forbidRegexp '='?;

RightBracePunctuator = '}' when forbidTmpl;

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
    ) >rawSliceStart %rawSliceFloatEnd;

BinaryIntegerLiteral =
	'0' [bB] [01]+ >numberStart $binNumberDigit;

OctalIntegerLiteral =
	'0' [oO] [0-7]+ >numberStart $octNumberDigit;

HexIntegerLiteral =
	'0' [xX] hexDigit+ >hexNumberStart %hexNumberEnd;

NumericLiteral =
	DecimalLiteral |
	BinaryIntegerLiteral |
	OctalIntegerLiteral |
	HexIntegerLiteral;

LineContinuation = '\\' LineTerminatorSequence;

SingleEscapeCharacter =
	["'\\bfnrtv] @escapedChar;

EscapeCharacter =
	SingleEscapeCharacter |
	digit |
	[xu];

NonEscapeCharacter =
	^(EscapeCharacter | LineTerminator) @lookahead;

CharacterEscapeSequence =
	SingleEscapeCharacter |
	NonEscapeCharacter;

EscapeSequence =
	CharacterEscapeSequence |
	'0' ^digit @lookahead @escapedChar |
	HexEscapeSequence |
	UnicodeEscapeSequence;

DoubleStringCharacter =
	^('"' | '\\' | LineTerminator)+ >rawSliceStart %rawSliceEnd |
	'\\' EscapeSequence |
	LineContinuation;

SingleStringCharacter =
	^("'" | '\\' | LineTerminator)+ >rawSliceStart %rawSliceEnd |
	'\\' EscapeSequence |
	LineContinuation;

StringLiteral =
	'"' DoubleStringCharacter** >stringStart '"' |
	"'" SingleStringCharacter** >stringStart "'";

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

RegularExpressionFlags = UnescapedIdentifierPart**;

RegularExpressionBody =
	RegularExpressionFirstChar RegularExpressionChar**;

RegularExpressionLiteral =
	'/' when permitRegexp RegularExpressionBody '/' @stringStart RegularExpressionFlags;

TemplateCharacter =
    (
        LF |
        LS |
        PS |
        ^([`\\$] | LineTerminator)
    )+ >rawSliceStart %rawSliceEnd |
    '$' ^'{' @lookahead >rawSliceStart %rawSliceEnd | # needs to be handled separately as ** gives inner + higher priority than '${' and it can't leave
    CR ^LF @lookahead @stringLF |
    CR LF @lookahead | # just skipping CR so that LF could be consumed as part of a slice
	'\\' EscapeSequence |
	LineContinuation;

TemplateChunk =
    TemplateCharacter** >stringStart ('`' @templateEnd | '${');

Template =
	'`' @templateStart TemplateChunk;

TemplateSubstitutionTail =
	'}' when permitTmpl TemplateChunk;

main := |*
    WhiteSpace => onWhiteSpace;
    LineTerminatorSequence => onLineTerminatorSequence;

    MultiLineComment => onMultiLineComment;
    SingleLineComment => onSingleLineComment;

    IdentifierName => onIdentifierName;
    Punctuator => onPunctuator;
    NumericLiteral => onNumericLiteral;
    StringLiteral => onStringLiteral;
    Template => onTemplate;

    RegularExpressionLiteral => onRegularExpressionLiteral;
    DivPunctuator => onPunctuator;
    TemplateSubstitutionTail => onTemplate;
    RightBracePunctuator => onPunctuator;
*|;

write data;
}%%