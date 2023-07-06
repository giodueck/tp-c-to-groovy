%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
int yyparse();
int yyerror(char *s);

extern int line;

int breakable = 0;
int continueable = 0;
%}

%union {
    char *str;
}

%token<str> IDENTIFIER LIT_INT LIT_DOUBLE LIT_STRING LIT_CHAR

%token HASH PP_INCLUDE STDIO_H STDBOOL_H
%token PRINTF
%token BOOL_TRUE BOOL_FALSE

%token INT DOUBLE CHAR VOID CONST LONG SHORT SIGNED UNSIGNED STATIC VOLATILE FLOAT EXTERN BOOL
%token RETURN MAIN
%token IF ELSE GOTO SWITCH CASE DEFAULT BREAK
%token FOR DO WHILE CONTINUE

%token ENUM SIZEOF STRUCT TYPEDEF UNION
%token AUTO REGISTER

%token OPP CLP OPCB CLCB OPB CLB
%token ENDS COMMA

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
:   HASH PP_INCLUDE LT pp_library_to_ignore GT { }
;

pp_library_to_ignore
:   STDIO_H
|   STDBOOL_H
;

global_statement
:   function_declaration
|   function_definition
;

global_scope
:   main
|   main global_scope_no_main
|   global_statement global_scope
;

global_scope_no_main
:   global_statement global_scope_no_main
|   global_statement
;

main
:   INT MAIN OPP CLP { printf("static void main(String[] args)"); } function_body
;

function_declaration
:   VOID IDENTIFIER OPP CLP { printf("void %s()", $2); } ENDS { yyerror("Cannot do this"); }
;

function_definition
:   VOID IDENTIFIER OPP CLP { printf("void %s()", $2); } function_body
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

conditional_statement
: IF '(' OPP {printf("if ( ");} expression ')' CLP block ELSE {printf("else ");} block
| IF '(' OPP {printf("if ( ");} expression ')' CLP block
| IF '(' OPP {printf("if ( ");} expression error '{' {yyerror("Se espera un simbolo ')' en la expresion 'if'.");}
//| SWITCH '(' expression ')' block
;

statement_no_end
:   RETURN { printf("return "); } literal
|   RETURN { printf("return"); }
|   CONTINUE { (continueable) ? printf("continue") : yyerror("Cannot use \"continue\" if not in a loop"); }
|   BREAK { (continueable) ? printf("break") : yyerror("Cannot use \"break\" if not in a loop or a switch statement"); }
|   print
|   do_loop
|   expression_list
|   assignment
|   variable_declaration
;

print
:   PRINTF OPP LIT_STRING CLP { printf("printf(%s)", $3); }
|   PRINTF OPP LIT_STRING COMMA { printf("printf(%s, ", $3); } expression_list CLP { printf(")"); }
;

loop
:   WHILE { printf("while "); } condition block_continueable
|   FOR OPP { printf("for ("); } variable_declaration ENDS { printf("; "); } expression ENDS { printf("; "); } expression CLP { printf(")"); } block_continueable
;

do_loop
:   DO { printf("do "); } block_continueable WHILE { printf(" while "); } condition
;

block_breakable
:   { breakable = 1; } block { breakable = 0; }
;

block_continueable
:   { continueable = 1; } block_breakable { continueable = 0; }
;

block
:   { printf("{"); } statement { printf("}"); }
|   OPCB { printf("{"); } statement_sequence CLCB { printf("} "); }
;

condition
:   expression_p
;

identifier_declaration
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

variable_declaration
:   identifier_declaration
|   identifier_declaration assign expression
|   variable_declaration COMMA IDENTIFIER {yyerror("No se admiten declaraciones multiples");}
;

assignment
:   IDENTIFIER { printf("%s", $1); } assign_op expression
//|   assignment COMMA {yyerror("No se admiten asignaciones multiples");} IDENTIFIER
;

assign
:   ASSIGN { printf(" %s ", $1); }
;

assign_op
:   assign
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
:   expression_11
|   ternary
|   LIT_STRING { printf("%s", $1); }
;

expression_list
:   expression
|   expression COMMA { printf(", "); } expression_list
;

expression_p
:   OPP { printf("("); } expression CLP { printf(")"); }
;

literal
:   LIT_INT     { printf($1); }
|   LIT_DOUBLE  { printf($1); }
|   LIT_CHAR    { printf($1); }
|   BOOL_TRUE   { printf("true"); }
|   BOOL_FALSE  { printf("false"); }
;

value
:   IDENTIFIER { printf($1); }
|   unary_pre IDENTIFIER { printf($2); }
|   IDENTIFIER { printf($1); } unary_post
|   literal
;

expression_0
:   value
|   expression_p
;

expression_1
:   expression_0
|   bitwise_op_1 expression_1
|   unary_op_1 expression_1
|   logical_op_1 expression_1
;

expression_2
:   expression_1
|   expression_2 arithmetic_op_2 expression_2
;

expression_3
:   expression_2
|   expression_3 arithmetic_op_3 expression_3
;

expression_4
:   expression_3
|   expression_4 bitwise_op_4 expression_4
;

expression_5
:   expression_4
|   expression_5 relational_op_5 expression_5
;

expression_6
:   expression_5
|   expression_6 relational_op_6 expression_6
;

expression_7
:   expression_6
|   expression_7 bitwise_op_7 expression_7
;

expression_8
:   expression_7
|   expression_8 bitwise_op_8 expression_8
;

expression_9
:   expression_8
|   expression_9 bitwise_op_9 expression_9
;

expression_10
:   expression_9
|   expression_10 logical_op_10 expression_10
;

expression_11
:   expression_10
|   expression_11 logical_op_11 expression_11
;

/* Operator precedence:
    Highest is lowest number, pre and postfix ++ or -- are 0

 */

unary_pre
:   INCREMENT { printf($1); }
|   DECREMENT { printf($1); }
;

unary_post
:   INCREMENT { printf($1); }
|   DECREMENT { printf($1); }
;

bitwise_op_1
:   NEGATION { printf(" %s ", $1); }
;

unary_op_1
:   MINUS { printf($1); }
|   PLUS { printf($1); }
;

logical_op_1
:   NOT { printf($1); }
;

arithmetic_op_2
:   ASTERISK { printf(" %s ", $1); }
|   SLASH { printf(" %s ", $1); }
|   PERCENT { printf(" %s ", $1); }
;

arithmetic_op_3
:   PLUS { printf(" %s ", $1); }
|   MINUS { printf(" %s ", $1); }
;

bitwise_op_4
:   SHIFT_LEFT { printf(" %s ", $1); }
|   SHIFT_RIGHT { printf(" %s ", $1); }
;

relational_op_5
:   LE { printf(" %s ", $1); }
|   GE { printf(" %s ", $1); }
|   LT { printf(" %s ", $1); }
|   GT { printf(" %s ", $1); }
;

relational_op_6
:   EQ { printf(" %s ", $1); }
|   NE { printf(" %s ", $1); }
;

bitwise_op_7
:   AMPERSAND { printf(" %s ", $1); }
;

bitwise_op_8
:   CARET { printf(" %s ", $1); }
;

bitwise_op_9
:   PIPE { printf(" %s ", $1); }
;

logical_op_10
:   AND { printf(" %s ", $1); }
;

logical_op_11
:   OR { printf(" %s ", $1); }
;

/* ternary_op_12 */

/* assignments are 13 */

/* comma is 14 */

ternary
:   expression QUESTION { printf(" %s ", $2); } expression COLON { printf(" %s ", $5); } expression
;

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