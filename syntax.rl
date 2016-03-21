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
	'x' xdigit{2} >rawSliceStart %rawSliceHexEnd %hexEscapeEnd;

UnicodeEscapeSequence =
	'u' xdigit{4} >rawSliceStart %rawSliceHexEnd %hexEscapeEnd |
	'u{' xdigit+ >rawSliceStart %rawSliceHexEnd %hexEscapeEnd '}';

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
	'enum'       | 'await' when inModule |
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

RightBracePunctuator = '}' when forbidTmplTail;

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
	'0' [bB] [01]+ >rawSliceStart %rawSliceBinEnd;

OctalIntegerLiteral =
	'0' [oO] [0-7]+ >rawSliceStart %rawSliceOctEnd;

HexIntegerLiteral =
	'0' [xX] xdigit+ >rawSliceStart %rawSliceHexEnd;

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
    TemplateCharacter** >stringStart;
    
NoSubstitutionTemplate =
    '`' TemplateChunk '`';
    
TemplateHead =
    '`' @templateStart TemplateChunk '${';
    
TemplateMiddle =
    '}' when permitTmplTail TemplateChunk '${';

TemplateTail =
    '}' when permitTmplTail TemplateChunk '`' @templateEnd;

main := |*
    WhiteSpace => onWhiteSpace;
    LineTerminatorSequence => onLineTerminatorSequence;

    MultiLineComment => onMultiLineComment;
    SingleLineComment => onSingleLineComment;

    IdentifierName => onIdentifierName;
    Punctuator => onPunctuator;
    NumericLiteral => onNumericLiteral;
    StringLiteral => onStringLiteral;
    
    NoSubstitutionTemplate => onNoSubstitutionTemplate;
    TemplateHead => onTemplateHead;
    TemplateMiddle => onTemplateMiddle;
    TemplateTail => onTemplateTail;

    RegularExpressionLiteral => onRegularExpressionLiteral;
    DivPunctuator => onPunctuator;
    RightBracePunctuator => onPunctuator;
*|;

write data;
}%%