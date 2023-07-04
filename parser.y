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

%token<str> IDENTIFIER LIT_INT LIT_DOUBLE LIT_STRING LIT_CHAR

%token HASH PP_INCLUDE STDIO_H
%token PRINTF 

%token INT DOUBLE CHAR VOID CONST LONG SHORT SIGNED UNSIGNED STATIC VOLATILE FLOAT EXTERN BOOL
%token RETURN MAIN
%token IF ELSE GOTO SWITCH CASE DEFAULT BREAK
%token FOR DO WHILE CONTINUE

%token ENUM SIZEOF STRUCT TYPEDEF UNION
%token AUTO REGISTER

%token OPP CLP OPCB CLCB OPB CLB
%token ENDS

%token<str> LE GE LT GT EQ NE

%token<str> PLUS MINUS ASTERISK SLASH PERCENT INCREMENT DECREMENT AMPERSAND PIPE CARET NEGATION SHIFT_LEFT SHIFT_RIGHT

%token<str> ASSIGN PLUS_ASSIGN MINUS_ASSIGN ASTERISK_ASSIGN SLASH_ASSIGN PERCENT_ASSIGN
%token<str> AMPERSAND_ASSIGN PIPE_ASSIGN CARET_ASSIGN NEGATION_ASSIGN SHIFT_LEFT_ASSIGN SHIFT_RIGHT_ASSIGN

%token<str> AND OR NOT

%token<str> QUESTION COLON

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
:   OPCB { printf("{"); } statement_sequence CLCB { printf("}"); }
;

statement_sequence
:   statement statement_sequence
|   statement
;

statement
:   statement_no_end ENDS
|   ENDS
|   loop
;

statement_no_end
:   RETURN LIT_INT { printf("return %s", $2); }
|   PRINTF OPP LIT_STRING CLP { printf("println(%s)", $3); }
|   loop
|   do_loop
|   expression
|   variable_declaration
;

loop
:   WHILE { printf("while "); } condition block
|   FOR OPP { printf("for ("); } variable_declaration ENDS { printf("; "); } expression ENDS { printf("; "); } statement_no_end CLP { printf(")"); } block
;

do_loop
:   DO { printf("do "); } block WHILE { printf(" while "); } condition
;

block
:   { printf("{"); } statement { printf("}"); }
|   OPCB { printf("{"); } statement_sequence CLCB { printf("} "); }
;

condition
:   OPP { printf("("); } expression CLP { printf(")"); }
;

expression_p
:   condition
;

variable_declaration
:   INT IDENTIFIER { printf("int %s", $2); }
|   CHAR IDENTIFIER { printf("char %s", $2); }
|   SHORT IDENTIFIER { printf("short %s", $2); }
|   LONG IDENTIFIER { printf("long %s", $2); }
|   FLOAT IDENTIFIER { printf("float %s", $2); }
|   DOUBLE IDENTIFIER { printf("double %s", $2); }
|   UNSIGNED INT IDENTIFIER { printf("int %s", $3); }
|   UNSIGNED CHAR IDENTIFIER { printf("char %s", $3); }
|   UNSIGNED SHORT IDENTIFIER { printf("short %s", $3); }
|   UNSIGNED LONG IDENTIFIER { printf("long %s", $3); }
|   CONST INT IDENTIFIER { printf("final int %s", $3); }
|   BOOL IDENTIFIER { printf("boolean %s", $2); }
;

assignment
:   IDENTIFIER { printf("%s", $1); } assign_op expression
;

assign_op
:   ASSIGN { printf(" %s ", $1); }
|   PLUS_ASSIGN { printf(" %s ", $1); }
|   MINUS_ASSIGN { printf(" %s ", $1); }
|   ASTERISK_ASSIGN { printf(" %s ", $1); }
|   SLASH_ASSIGN { printf(" %s ", $1); }
|   PERCENT_ASSIGN { printf(" %s ", $1); }
|   AMPERSAND_ASSIGN { printf(" %s ", $1); }
|   PIPE_ASSIGN { printf(" %s ", $1); }
|   CARET_ASSIGN { printf(" %s ", $1); }
|   NEGATION_ASSIGN { printf(" %s ", $1); }
|   SHIFT_LEFT_ASSIGN { printf(" %s ", $1); }
|   SHIFT_RIGHT_ASSIGN { printf(" %s ", $1); }
;

expression
:   value
|   expression_p
|   LIT_STRING { printf($1); }
|   expression binary_op expression
|   assignment
|   unary_op expression
|   ternary
;

unary_op
:   NOT { printf($1); }
|   MINUS { printf($1); }
;

unary_pre
:   INCREMENT { printf($1); }
|   DECREMENT { printf($1); }
;

unary_post
:   INCREMENT { printf($1); }
|   DECREMENT { printf($1); }
;

binary_op
:   arithmetic_op
|   bitwise_op
|   logical_op
;

arithmetic_op
:   PLUS { printf(" %s ", $1); }
|   MINUS { printf(" %s ", $1); }
|   ASTERISK { printf(" %s ", $1); }
|   SLASH { printf(" %s ", $1); }
|   PERCENT { printf(" %s ", $1); }
;

bitwise_op
:   AMPERSAND { printf(" %s ", $1); }
|   PIPE { printf(" %s ", $1); }
|   CARET { printf(" %s ", $1); }
|   NEGATION { printf(" %s ", $1); }
|   SHIFT_LEFT { printf(" %s ", $1); }
|   SHIFT_RIGHT { printf(" %s ", $1); }
;

logical_op
:   AND { printf(" %s ", $1); }
|   OR { printf(" %s ", $1); }
;

ternary
:   condition QUESTION { printf(" %s ", $2); } statement_no_end COLON { printf(" %s ", $5); } statement_no_end

value
:   IDENTIFIER { printf($1); }
|   LIT_INT { printf($1); }
|   unary_pre IDENTIFIER { printf($2); }
|   IDENTIFIER { printf($1); } unary_post
|   LIT_DOUBLE { printf($1); }
|   LIT_CHAR   { printf($1); }
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
    printf("\nError on line %d: %s\n", line, s);

    return 0;
}