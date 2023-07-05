%{
#include "parser.tab.h"

int line = 1;

int yywrap(void) {}
%}

id      [a-zA-Z_][a-zA-Z_0-9]*
integer [+-]?[0-9]+
double  [+-]?[0-9]+(\.[0-9]*)?([eE][+-]?[0-9]+)?
string  \"(\\.|[^"\\])*\"
char    '(\\.|[^'])'

%state IN_COMMENT

%%

"//"[^\n]*      // eat line comment
"/*"            { BEGIN(IN_COMMENT); }
<IN_COMMENT>{
"*/"      BEGIN(INITIAL);
[^*\n]+   // eat comment in chunks
"*"       // eat the lone star
\n        line++;
}

[\ ]            { }
[\t]            { printf("\t"); }
[\n]            { line++; printf("\n"); }

"#"             { return HASH; }
"include"       { return PP_INCLUDE; }
"stdio.h"       { return STDIO_H; }
"stdbool.h"     { return STDBOOL_H; }

"main"          { return MAIN; }
"return"        { return RETURN; }
"printf"        { return PRINTF; }

"while"         { return WHILE; }
"do"            { return DO; }
"for"           { return FOR; }

"int"           { return INT; }
"void"          { return VOID; }
"char"          { return CHAR; }
"const"         { return CONST; }
"float"         { return FLOAT; }
"long"          { return LONG; }
"short"         { return SHORT; }
"static"        { return STATIC; }
"struct"        { return STRUCT; }
"unsigned"      { return UNSIGNED; }
"double"        { return DOUBLE; }
"volatile"      { return VOLATILE; }
"extern"        { return EXTERN; }
"bool"          { return BOOL; }

"true"          { return BOOL_TRUE; }
"false"         { return BOOL_FALSE; }

"("             { return OPP; }
")"             { return CLP; }
"{"             { return OPCB; }
"}"             { return CLCB; }
"["             { return OPB; }
"]"             { return CLB; }
";"             { return ENDS; }
","             { return COMMA; }

"<="            { yylval.str = strdup(yytext); return LE; }
">="            { yylval.str = strdup(yytext); return GE; }
"<"             { yylval.str = strdup(yytext); return LT; }
">"             { yylval.str = strdup(yytext); return GT; }
"=="            { yylval.str = strdup(yytext); return EQ; }
"!="            { yylval.str = strdup(yytext); return NE; }

"+"             { yylval.str = strdup(yytext); return PLUS; }
"-"             { yylval.str = strdup(yytext); return MINUS; }
"*"             { yylval.str = strdup(yytext); return ASTERISK; }
"/"             { yylval.str = strdup(yytext); return SLASH; }
"%"             { yylval.str = strdup(yytext); return PERCENT; }
"++"            { yylval.str = strdup(yytext); return INCREMENT; }
"--"            { yylval.str = strdup(yytext); return DECREMENT; }
"&"             { yylval.str = strdup(yytext); return AMPERSAND; }
"|"             { yylval.str = strdup(yytext); return PIPE; }
"^"             { yylval.str = strdup(yytext); return CARET; }
"~"             { yylval.str = strdup(yytext); return NEGATION; }
"<<"            { yylval.str = strdup(yytext); return SHIFT_LEFT; }
">>"            { yylval.str = strdup(yytext); return SHIFT_RIGHT; }

"="             { yylval.str = strdup(yytext); return ASSIGN; }
"+="            { yylval.str = strdup(yytext); return PLUS_ASSIGN; }
"-="            { yylval.str = strdup(yytext); return MINUS_ASSIGN; }
"*="            { yylval.str = strdup(yytext); return ASTERISK_ASSIGN; }
"/="            { yylval.str = strdup(yytext); return SLASH_ASSIGN; }
"%="            { yylval.str = strdup(yytext); return PERCENT_ASSIGN; }
"&="            { yylval.str = strdup(yytext); return AMPERSAND_ASSIGN; }
"|="            { yylval.str = strdup(yytext); return PIPE_ASSIGN; }
"^="            { yylval.str = strdup(yytext); return CARET_ASSIGN; }
"~="            { yylval.str = strdup(yytext); return NEGATION_ASSIGN; }
"<<="           { yylval.str = strdup(yytext); return SHIFT_LEFT_ASSIGN; }
">>="           { yylval.str = strdup(yytext); return SHIFT_RIGHT_ASSIGN; }

"&&"            { yylval.str = strdup(yytext); return AND; }
"||"            { yylval.str = strdup(yytext); return OR; }
"!"             { yylval.str = strdup(yytext); return NOT; }

"?"             { yylval.str = strdup(yytext); return QUESTION; }
":"             { yylval.str = strdup(yytext); return COLON; }

{id}            { yylval.str = strdup(yytext); return IDENTIFIER; }
{integer}       { yylval.str = strdup(yytext); return LIT_INT; }
{double}        { yylval.str = strdup(yytext); return LIT_DOUBLE; }
{string}        { yylval.str = strdup(yytext); return LIT_STRING; }
{char}          { yylval.str = strdup(yytext); return LIT_CHAR; }

%%