%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
int yyparse();
int yyerror(char *s);
extern FILE *yyin;

extern int line;

int breakable = 0;
int continueable = 0;

FILE *outfd = NULL;
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

%token LE GE LT GT EQ NE

%token PLUS MINUS ASTERISK SLASH PERCENT INCREMENT DECREMENT AMPERSAND PIPE CARET NEGATION SHIFT_LEFT SHIFT_RIGHT

%token ASSIGN PLUS_ASSIGN MINUS_ASSIGN ASTERISK_ASSIGN SLASH_ASSIGN PERCENT_ASSIGN
%token AMPERSAND_ASSIGN PIPE_ASSIGN CARET_ASSIGN NEGATION_ASSIGN SHIFT_LEFT_ASSIGN SHIFT_RIGHT_ASSIGN

%token AND OR NOT

%token QUESTION COLON

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
:   INT MAIN OPP CLP { fprintf(outfd, "static void main(String[] args)"); } function_body
;

function_declaration
:   VOID IDENTIFIER OPP CLP { fprintf(outfd, "void %s()", $2); } ENDS { yyerror("Cannot do this"); }
;

function_definition
:   VOID IDENTIFIER OPP CLP { fprintf(outfd, "void %s()", $2); } function_body
;

function_body
:   OPCB { fprintf(outfd, "{"); } statement_sequence CLCB { fprintf(outfd, "}"); }
;

statement_sequence
:   statement statement_sequence
|   statement
;

statement
:   statement_no_end ENDS
|   ENDS
|   loop
|   conditional_statement
;

conditional_statement
:   IF { fprintf(outfd, "if "); } condition block else_statement
//| SWITCH '(' expression ')' block
;

else_statement
:
|   ELSE {fprintf(outfd, "else ");} block
;

statement_no_end
:   RETURN { fprintf(outfd, "return "); } literal
|   RETURN { fprintf(outfd, "return"); }
|   CONTINUE { (continueable) ? fprintf(outfd, "continue") : yyerror("No puede usarse \"continue\" fuera de un ciclo"); }
|   BREAK { (continueable) ? fprintf(outfd, "break") : yyerror("No puede usarse \"break\" fuera de un ciclo o un switch"); }
|   print
|   do_loop
|   expression_list
|   assignment
|   variable_declaration
;

print
:   PRINTF OPP LIT_STRING CLP { fprintf(outfd, "printf(%s)", $3); }
|   PRINTF OPP LIT_STRING COMMA { fprintf(outfd, "printf(%s, ", $3); } expression_list CLP { fprintf(outfd, ")"); }
;

loop
:   WHILE { fprintf(outfd, "while "); } condition block_continueable
|   FOR OPP { fprintf(outfd, "for ("); } variable_declaration ENDS { fprintf(outfd, "; "); } expression ENDS { fprintf(outfd, "; "); } expression CLP { fprintf(outfd, ")"); } block_continueable
;

do_loop
:   DO { fprintf(outfd, "do "); } block_continueable WHILE { fprintf(outfd, " while "); } condition
;

block_breakable
:   { breakable = 1; } block { breakable = 0; }
;

block_continueable
:   { continueable = 1; } block_breakable { continueable = 0; }
;

block
:   { fprintf(outfd, "{"); } statement { fprintf(outfd, "}"); }
|   OPCB { fprintf(outfd, "{"); } statement_sequence CLCB { fprintf(outfd, "} "); }
;

condition
:   expression_p
;

identifier_declaration
:   INT IDENTIFIER { fprintf(outfd, "int %s", $2); }
|   CHAR IDENTIFIER { fprintf(outfd, "char %s", $2); }
|   SHORT IDENTIFIER { fprintf(outfd, "short %s", $2); }
|   LONG IDENTIFIER { fprintf(outfd, "long %s", $2); }
|   FLOAT IDENTIFIER { fprintf(outfd, "float %s", $2); }
|   DOUBLE IDENTIFIER { fprintf(outfd, "double %s", $2); }
|   UNSIGNED INT IDENTIFIER { fprintf(outfd, "int %s", $3); }
|   UNSIGNED CHAR IDENTIFIER { fprintf(outfd, "char %s", $3); }
|   UNSIGNED SHORT IDENTIFIER { fprintf(outfd, "short %s", $3); }
|   UNSIGNED LONG IDENTIFIER { fprintf(outfd, "long %s", $3); }
|   CONST INT IDENTIFIER { fprintf(outfd, "final int %s", $3); }
|   BOOL IDENTIFIER { fprintf(outfd, "boolean %s", $2); }
;

variable_declaration
:   identifier_declaration
|   identifier_declaration assign expression
|   variable_declaration COMMA IDENTIFIER {yyerror("No se admiten declaraciones multiples");}
;

assignment
:   IDENTIFIER { fprintf(outfd, "%s", $1); } assign_op expression
//|   assignment COMMA {yyerror("No se admiten asignaciones multiples");} IDENTIFIER
;

assign
:   ASSIGN { fprintf(outfd, " = "); }
;

assign_op
:   assign
|   PLUS_ASSIGN         { fprintf(outfd, " += "); }
|   MINUS_ASSIGN        { fprintf(outfd, " -= "); }
|   ASTERISK_ASSIGN     { fprintf(outfd, " *= "); }
|   SLASH_ASSIGN        { fprintf(outfd, " /= "); }
|   PERCENT_ASSIGN      { fprintf(outfd, " %= "); }
|   AMPERSAND_ASSIGN    { fprintf(outfd, " &= "); }
|   PIPE_ASSIGN         { fprintf(outfd, " |= "); }
|   CARET_ASSIGN        { fprintf(outfd, " ^= "); }
|   NEGATION_ASSIGN     { fprintf(outfd, " ~= "); }
|   SHIFT_LEFT_ASSIGN   { fprintf(outfd, " <<= "); }
|   SHIFT_RIGHT_ASSIGN  { fprintf(outfd, " >>= "); }
;

expression
:   expression_11
|   ternary
|   LIT_STRING { fprintf(outfd, "%s", $1); }
;

expression_list
:   expression
|   expression COMMA { fprintf(outfd, ", "); } expression_list
;

expression_p
:   OPP { fprintf(outfd, "("); } expression CLP { fprintf(outfd, ")"); }
;

literal
:   LIT_INT     { fprintf(outfd, $1); }
|   LIT_DOUBLE  { fprintf(outfd, $1); }
|   LIT_CHAR    { fprintf(outfd, $1); }
|   BOOL_TRUE   { fprintf(outfd, "true"); }
|   BOOL_FALSE  { fprintf(outfd, "false"); }
;

value
:   IDENTIFIER { fprintf(outfd, $1); }
|   unary_pre IDENTIFIER { fprintf(outfd, $2); }
|   IDENTIFIER { fprintf(outfd, $1); } unary_post
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
:   INCREMENT { fprintf(outfd, "++"); }
|   DECREMENT { fprintf(outfd, "--"); }
;

unary_post
:   INCREMENT { fprintf(outfd, "++"); }
|   DECREMENT { fprintf(outfd, "--"); }
;

bitwise_op_1
:   NEGATION { fprintf(outfd, "~"); }
;

unary_op_1
:   MINUS { fprintf(outfd, "-"); }
|   PLUS { fprintf(outfd, "+"); }
;

logical_op_1
:   NOT { fprintf(outfd, "!"); }
;

arithmetic_op_2
:   ASTERISK    { fprintf(outfd, " * "); }
|   SLASH       { fprintf(outfd, " / "); }
|   PERCENT     { fprintf(outfd, " % "); }
;

arithmetic_op_3
:   PLUS    { fprintf(outfd, " + "); }
|   MINUS   { fprintf(outfd, " - "); }
;

bitwise_op_4
:   SHIFT_LEFT  { fprintf(outfd, " << "); }
|   SHIFT_RIGHT { fprintf(outfd, " >> "); }
;

relational_op_5
:   LE { fprintf(outfd, " <= "); }
|   GE { fprintf(outfd, " >= "); }
|   LT { fprintf(outfd, " < "); }
|   GT { fprintf(outfd, " > "); }
;

relational_op_6
:   EQ { fprintf(outfd, " == "); }
|   NE { fprintf(outfd, " != "); }
;

bitwise_op_7
:   AMPERSAND { fprintf(outfd, " & "); }
;

bitwise_op_8
:   CARET { fprintf(outfd, " ^ "); }
;

bitwise_op_9
:   PIPE { fprintf(outfd, " | "); }
;

logical_op_10
:   AND { fprintf(outfd, " && "); }
;

logical_op_11
:   OR { fprintf(outfd, " || "); }
;

/* ternary_op_12 */

/* assignments are 13 */

/* comma is 14 */

ternary
:   expression QUESTION { fprintf(outfd, " ? "); } expression COLON { fprintf(outfd, " : "); } expression
;

%%

int main(int argc, char **argv)
{
    FILE *infd = NULL;

    if (argc >= 3)
    {
        infd = fopen(argv[1], "rt");
        if (!infd)
        {
            fprintf(stderr, "No se pudo abrir el archivo %s\n", argv[1]);
            return EXIT_FAILURE;
        }
        
        outfd = fopen(argv[2], "wt");
        if (!outfd)
        {
            fprintf(stderr, "No se pudo abrir el archivo %s\n", argv[2]);
            return EXIT_FAILURE;
        }
    } else
    {
        fprintf(stderr, "Uso: %s <archivo entrada C> <archivo salida Groovy>\n", argv[0]);
        return EXIT_FAILURE;
    }

    yyin = infd;
    yyparse();

    fclose(infd);
    fclose(outfd);
    return 0;
}

int yyerror(char *s)
{
    printf("\nError en la linea %d: %s\n", line, s);

    return 0;
}