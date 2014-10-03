/*
BSD License

Copyright (c) 2014, Marco Mastropaolo
Copyright (c) 2013, Kazunori Sakamoto


All rights reserved.   

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
 
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the NAME of Rainer Schuster nor the NAMEs of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This grammar file derived from:

    Lua 5.2 Reference Manual
    http://www.lua.org/manual/5.2/manual.html

    Lua 5.1 grammar written by Nicolai Mainiero
    http://www.antlr3.org/grammar/1178608849736/Lua.g

I tested my grammar with Test suite for Lua 5.2 (http://www.lua.org/tests/5.2/)
*/

grammar Lua; 

chunk
    : block EOF
    ;

block 
    : stat* retstat?
    ;

stat
    : ';'																			#stat_nulstatement
    | varlist '=' explist															#stat_assignment
    | varOrExp nameAndArgs+															#stat_functioncall
    | label																			#stat_label
    | 'break'																		#stat_break
    | 'goto' NAME																	#stat_goto
    | 'do' block 'end'																#stat_doblock
    | 'while' exp 'do' block 'end'													#stat_whiledoloop
    | 'repeat' block 'until' exp													#stat_repeatuntilloop
    | 'if' exp 'then' block ('elseif' exp 'then' block)* ('else' block)? 'end'		#stat_ifblock
    | 'for' NAME '=' exp ',' exp (',' exp)? 'do' block 'end'						#stat_forloop
    | 'for' namelist 'in' explist 'do' block 'end'									#stat_foreachloop
    | 'function' funcname funcbody													#stat_funcdef
    | 'local' 'function' NAME funcbody												#stat_localfuncdef
    | 'local' namelist ('=' explist)?												#stat_localassignment
    ;


retstat
    : 'return' explist? ';'?
    ;

label
    : '::' NAME '::'
    ;

// this is an addition
funcnametableaccessor 
	: ('.' NAME);

funcname
    : fnname=NAME funcnametableaccessor* (':' methodaccessor=NAME)?
    ;

varlist
    : var (',' var)*
    ;

namelist
    : NAME (',' NAME)*
    ;

explist
    : exp (',' exp)*
    ;

expterm 
	: 'nil' | 'false' | 'true' | number | string		
	| vararg
	| anonfunctiondef								
    | prefixexp										 
	| tableconstructor
	;
	
powerExp 
	: expterm 													#exp_powerfallback
	| expterm operatorPower powerExp							#exp_power
	;
unaryExp 
	: powerExp 													#exp_unaryfallback
	| operatorUnary unaryExp									#exp_unary
	;
muldivExp 
	: unaryExp 													#exp_muldivfallback
	| unaryExp operatorMulDivMod muldivExp						#exp_muldiv
	;
addsubExp 
	: muldivExp 												#exp_addsubfallback
	| muldivExp operatorAddSub addsubExp						#exp_addsub
	;
strcatExp 	
	: addsubExp 												#exp_strcastfallback
	| addsubExp operatorStrcat strcatExp						#exp_strcat
	;
compareExp 
	: strcatExp 												#exp_comparefallback
	| strcatExp operatorComparison compareExp                   #exp_compare
	;
logicAndExp 
	: compareExp 												#exp_logicAndfallback
	| compareExp operatorAnd logicAndExp                        #exp_logicAnd
	;
exp 
	: logicAndExp 												#exp_logicOrfallback
	| logicAndExp operatorOr exp								#exp_logicOr
	;


var
    : (NAME | '(' exp ')' varSuffix) varSuffix*
    ;

prefixexp
    : varOrExp nameAndArgs*
    ;

// 
varOrExp
    : var | '(' exp ')'
    ;

nameAndArgs
    : (':' NAME)? args
    ;

// Suffix to variable - array/table indexing
varSuffix
    : nameAndArgs* ('[' exp ']' | '.' NAME)
    ;


// Possible args to func call : list of expressions, table ctor, string literal
args
    : '(' explist? ')' | tableconstructor | string
    ;


// Definition of func. Note: there is NO function name!
anonfunctiondef
    : 'function' funcbody
    ;

//lambdaexp
//	: '[' parlist ':' exp ']'
//	;

//lambdastat
//	: '[' parlist ':' 'do' block 'end' ']'
//	;

// A func body from the parlist to end. 
funcbody
    : '(' parlist? ')' block 'end'
    ;

// The list of params in a function def
parlist
    : namelist (',' vararg)? | vararg
    ;


// A table ctor
tableconstructor
    : '{' fieldlist? '}'
    ;


// The inside of a table ctor
fieldlist
    : field (fieldsep field)* fieldsep?
    ;


// field declaration in table ctor
field
    : '[' keyexp=exp ']' '=' keyedexp=exp | NAME '=' namedexp=exp | positionalexp=exp
    ;


// separators for fields in a table ctor
fieldsep
    : ',' | ';'
    ;

operatorOr 
	: 'or';

operatorAnd 
	: 'and';

operatorComparison 
	: '<' | '>' | '<=' | '>=' | '~=' | '==';

operatorStrcat
	: '..';

operatorAddSub
	: '+' | '-';

operatorMulDivMod
	: '*' | '/' | '%';

operatorUnary
    : 'not' | '#' | '-';

operatorPower
    : '^';

number
    : INT | HEX | FLOAT | HEX_FLOAT
    ;

string
    : NORMALSTRING | CHARSTRING | LONGSTRING
    ;

vararg
	: '...'
	;

// LEXER

NAME
    : [a-zA-Z_][a-zA-Z_0-9]*
    ;

NORMALSTRING
    : '"' ( EscapeSequence | ~('\\'|'"') )* '"' 
    ;

CHARSTRING
    : '\'' ( EscapeSequence | ~('\''|'\\') )* '\''
    ;

LONGSTRING
    : '[' NESTED_STR ']'
    ;

fragment
NESTED_STR
    : '=' NESTED_STR '='
    | '[' .*? ']'
    ;

INT
    : Digit+
    ;

HEX
    : '0' [xX] HexDigit+
    ;

FLOAT
    : Digit+ '.' Digit* ExponentPart?
    | '.' Digit+ ExponentPart?
    | Digit+ ExponentPart
    ;

HEX_FLOAT
    : '0' [xX] HexDigit+ '.' HexDigit* HexExponentPart?
    | '0' [xX] '.' HexDigit+ HexExponentPart?
    | '0' [xX] HexDigit+ HexExponentPart
    ;

fragment
ExponentPart
    : [eE] [+-]? Digit+
    ;

fragment
HexExponentPart
    : [pP] [+-]? Digit+
    ;

fragment
EscapeSequence
    : '\\' [abfnrtvz"'\\]
    | '\\' '\r'? '\n'
    | DecimalEscape
    | HexEscape
    ;
    
fragment
DecimalEscape
    : '\\' Digit
    | '\\' Digit Digit
    | '\\' [0-2] Digit Digit
    ;
    
fragment
HexEscape
    : '\\' 'x' HexDigit HexDigit
    ;

fragment
Digit
    : [0-9]
    ;

fragment
HexDigit
    : [0-9a-fA-F]
    ;

COMMENT
    : '--[' NESTED_STR ']' -> channel(HIDDEN)
    ;
    
LINE_COMMENT
    : '--'
    (                                               // --
    | '[' '='*                                      // --[==
    | '[' '='* ~('='|'['|'\r'|'\n') ~('\r'|'\n')*   // --[==AA
    | ~('['|'\r'|'\n') ~('\r'|'\n')*                // --AAA
    ) ('\r\n'|'\r'|'\n'|EOF)
    -> channel(HIDDEN)
    ;
    
WS  
    : [ \t\u000C\r\n]+ -> skip
    ;

SHEBANG
    : '#' '!' ~('\n'|'\r')* -> channel(HIDDEN)
    ;
