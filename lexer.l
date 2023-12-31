%{
#include "parser.tab.h"
#include <string.h>
#include <stdio.h>

int line = 1;
extern FILE *outfd;

int yywrap(void) {}
int yyerror(char *msg);
%}

id      [a-zA-Z_][a-zA-Z_0-9]*
integer [+-]?[0-9]+
double  [+-]?[0-9]+(\.[0-9]*)?([eE][+-]?[0-9]+)?
string  \"(\\.|[^"\\])*\"
char    '(\\.|[^'])'

%state IN_COMMENT

%%

"//"[^\n]*      { fprintf(outfd, yytext); }
"/*"            { BEGIN(IN_COMMENT); fprintf(outfd, yytext); }
<IN_COMMENT>{
"*/"      BEGIN(INITIAL); fprintf(outfd, yytext);
[^*\n]+   fprintf(outfd, yytext);
"*"       fprintf(outfd, yytext);
\n        line++; fprintf(outfd, yytext);
}

\t|("    ")     { fprintf(outfd, yytext); }
[ ]             // ignore spaces that are not 4 wide
[\n]            { line++; fprintf(outfd, "\n"); }

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
"break"         { return BREAK; }
"continue"      { return CONTINUE; }

"if"            { return IF; }
"else"          { return ELSE; }

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
"typedef"       { return TYPEDEF; }

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
"."             { return DOT; }

"<="            { return LE; }
">="            { return GE; }
"<"             { return LT; }
">"             { return GT; }
"=="            { return EQ; }
"!="            { return NE; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return ASTERISK; }
"/"             { return SLASH; }
"%"             { return PERCENT; }
"++"            { return INCREMENT; }
"--"            { return DECREMENT; }
"&"             { return AMPERSAND; }
"|"             { return PIPE; }
"^"             { return CARET; }
"~"             { return NEGATION; }
"<<"            { return SHIFT_LEFT; }
">>"            { return SHIFT_RIGHT; }

"="             { return ASSIGN; }
"+="            { return PLUS_ASSIGN; }
"-="            { return MINUS_ASSIGN; }
"*="            { return ASTERISK_ASSIGN; }
"/="            { return SLASH_ASSIGN; }
"%="            { return PERCENT_ASSIGN; }
"&="            { return AMPERSAND_ASSIGN; }
"|="            { return PIPE_ASSIGN; }
"^="            { return CARET_ASSIGN; }
"~="            { return NEGATION_ASSIGN; }
"<<="           { return SHIFT_LEFT_ASSIGN; }
">>="           { return SHIFT_RIGHT_ASSIGN; }

"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }

"?"             { return QUESTION; }
":"             { return COLON; }


"switch"|"case"|"default"   { yyerror("\"switch\", \"case\" y \"default\" no son admitidos"); }

"signed"|"static"|"volatile"|"extern"|"auto"|"register" { char msg[BUFSIZ]; sprintf(msg, "\"%s\" no es un calificador de variable admitido", yytext); yyerror(msg); }

"goto"          { yyerror("\"goto\" no es admitido"); }

"enum"|"union"  { char msg[BUFSIZ]; sprintf(msg, "\"%s\" no es un tipo de estructura admitida", yytext); yyerror(msg); }

"sizeof"        { yyerror("\"sizeof\" no es un operador admitido"); }

{id}            { yylval.str = strdup(yytext); return IDENTIFIER; }
{integer}       { yylval.str = strdup(yytext); return LIT_INT; }
{double}        { yylval.str = strdup(yytext); return LIT_DOUBLE; }
{string}        { yylval.str = strdup(yytext); return LIT_STRING; }
{char}          { yylval.str = strdup(yytext); return LIT_CHAR; }

%%