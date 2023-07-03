%{
#include "parser.tab.h"

int line = 1;
int indent = 0;
char *indent_literal = "    ";
int indentsize = 4;

int yywrap(void) {}
%}

id      [a-zA-Z_][a-zA-Z_0-9]*
integer [+-]?[0-9]+
double  [+-]?[0-9]+(\.[0-9]*)?([eE][+-]?[0-9]+)?
string  \"(\\.|[^"\\])*\"

%%

[\ ]            { }
[\t]            { printf("\t"); }
[\n]            { line++; printf("\n"); }

"#"             { return HASH; }
"include"       { return PP_INCLUDE; }
"stdio.h"       { return STDIO_H; }

"main"          { return MAIN; }
"return"        { return RETURN; }
"printf"        { return PRINTF; }

"while"         { return WHILE; }
"do"            { return DO; }
"for"           { return FOR; }

"int"           { return INT; }
"void"          { return VOID; }

"("             { return OPP; }
")"             { return CLP; }
"{"             { return OPCB; }
"}"             { return CLCB; }
"["             { return OPB; }
"]"             { return CLB; }
";"             { return ENDS; }

"<="            { return LE; }
">="            { return GE; }
"<"             { return LT; }
">"             { return GT; }
"=="            { return EQ; }
"!="            { return NE; }

{id}            { yylval.str = strdup(yytext); return IDENTIFIER; }
{integer}       { yylval.str = strdup(yytext); return LIT_INT; }
{double}        { yylval.str = strdup(yytext); return LIT_DOUBLE; }
{string}        { yylval.str = strdup(yytext); return LIT_STRING; }

%%