%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
int yyparse();
int yyerror(char *s);

extern int line;
extern int indent;
extern char *indent_literal;
extern int indentsize;
%}

%union {
    char *str;
}

%token<str> IDENTIFIER LIT_INT LIT_DOUBLE LIT_STRING

%token HASH PP_INCLUDE STDIO_H
%token PRINTF 

%token INT DOUBLE CHAR VOID CONST LONG SHORT SIGNED UNSIGNED STATIC VOLATILE FLOAT EXTERN
%token RETURN MAIN
%token IF ELSE GOTO SWITCH CASE DEFAULT BREAK
%token FOR DO WHILE CONTINUE

%token ENUM SIZEOF STRUCT TYPEDEF UNION
%token AUTO REGISTER

%token OPP CLP OPCB CLCB OPB CLB
%token ENDS

%token LE GE LT GT EQ NE

%%

entrypoint
:   preprocessor global_scope { return 0; }
|   global_scope { return 0; }
;

preprocessor
:   pp_directive preprocessor
|   pp_directive
;

pp_directive
:   HASH PP_INCLUDE LT STDIO_H GT { }
;

global_scope
:   INT MAIN OPP CLP { printf("static void main(String[] args)"); } function_body
;

function_body
:   OPCB { printf("{"); indent++; } statement_sequence CLCB { printf("}"); }
;

statement_sequence
:   statement statement_sequence
|   statement
;

statement
:   RETURN LIT_INT ENDS { printf("return %d;", atoi($2)); }
|   PRINTF OPP LIT_STRING CLP ENDS { printf("println(%s);", $3); }
;

/* PREPROCESSOR */

/* FUNCTIONS */

/* VARIABLES */

/* STATEMENTS & EXPRESSIONS */

/* COMMENTS */

%%

int main(int argc, char **argv)
{
    yyparse();

    return 0;
}

int yyerror(char *s)
{
    printf("Error on line %d: %s\n", line, s);

    return 0;
}