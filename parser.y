%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
int yyparse();
int yyerror(char *s);
extern FILE *yyin;

/* SYMBOL TABLE */

// Symbol types for node
#define ST_NULL    -1
#define ST_VARIABLE 0
#define ST_FUNCTION 1
#define ST_TYPEDEF  2
#define ST_STRUCT   3

// Data type for symbol table, which is actually a linked list node
typedef struct symbol {
    char *name;             // IDENTIFIER name
    int symbol_type;        // symbol types defined
    int data_type;          // insert token name, example INT CHAR
    int is_const;           // 0/1
    struct symbol *args;    // for functions with arguments
    struct symbol *next;    // next symbol in list
} node;

// Arbitrary
#define DIM 50

// Scope will be handled using a stack, top is highest scope, tail is global scope
// This lets us check for existing symbols by going top to bottom through the stack,
// where each node is a symbol table linked list. Entering and exiting scopes involves
// pushing or popping from the stack
typedef struct stack
{
    node *array;
    int top;
    int size;
} stack;

node *st_global = NULL;
stack symbol_table = { NULL, 0, 0 };

void init_stack(stack *s)
{
    s->array = (node *) malloc(sizeof(node) * 2 * DIM);
    s->top = 0;
    s->size = 2 * DIM;
}

void push_stack(stack *s, node n)
{
    s->array[s->top++] = n;
    if (s->top == s->size)
    {
        s->array = (node *) realloc(s->array, sizeof(node) * (2 * DIM + s->size));
        s->size += 2 * DIM;
    }
}

node pop_stack(stack *s)
{
    return s->array[--s->top];
}

node top_stack(stack *s)
{
    if (!s->top)
        return (node){0};
    return s->array[s->top - 1];
}

void free_stack(stack *s)
{
    free(s->array);
    s->top = 0;
}

node init_symbol(char *name, int symbol_type, int data_type, int is_const)
{
    return (node) { name, symbol_type, data_type, is_const, NULL, NULL };
}

void free_node(node n)
{
    // This node struct is allocated by the stack, but it's children are separate
    while (n.next)
    {
        // Free child nodes one by one until NULL node is reached
        node *m = n.next;
        n = *(node*)((void *)n.next);   // cast to void*, then to node*, then get value pointed to
        free(m);
    }
}

/* Useful functions */

// Create and enter new scope, example: enter new block with '{' or 'for' loop
void enter_scope();

// Create and enter a new function scope, with the formal parameters already defined in the new scope
void enter_function(char *name);

// Leave a scope, example when exiting a block with '}'
void exit_scope();

// Returns an integer indicating scope level, 0 = global
int get_scope();

// Add new symbol to scope. If already defined, calls yyerror
void add_symbol(char *name, int symbol_type, int data_type, int is_const);

// Add new formal parameter to a function
void add_parameter(char *function, char *name, int symbol_type, int data_type, int is_const);

// Returns a symbol. If not defined, calls yyerror
node get_symbol(char *name);

// Returns level if symbol exists, -1 if it doesn't
int test_symbol(char *name);

// same as get_symbol, but returns a pointer to the actual symbol node
node *get_symbol_ptr(char *name);

// Returns a function parameter symbol. If not defined, calls yyerror
node get_parameter(char *function, int index);

// Returns index if parameter exists, -1 if it doesn't
int test_parameter(char *function, char *name);

// Returns the number of parameters that a function takes
int get_parameter_count(char *function);

// debug
void dump_symbols()
{
    int level = 0;
    while (level < symbol_table.top)
    {
        node s = symbol_table.array[level];

        while (s.name)
        {
            for (int i = 0; i < level; i++) printf("  ");
            printf("%s\n", s.name);

            if (s.symbol_type == ST_FUNCTION || s.symbol_type == ST_STRUCT)
            {
                for (int i = 0; i < level; i++) printf("  ");
                if (s.symbol_type == ST_FUNCTION) printf(" params: ");
                if (s.symbol_type == ST_STRUCT) printf(" fields: ");
                node a = *s.args;
                while (a.name)
                {
                    printf(a.name);
                    printf(" ");
                    a = *a.next;
                }
                printf("\n");
            }

            s = *s.next;
        }
        level++;
    }
}

/*Useful functions for structures*/

//Create and enter a new class scope, with the formal fields defined in the new scope
void enter_structure(char *name);

//Add new formal field to a class
void add_field(char *structure, char* name, int symbol_type, int data_type, int is_const);

// Returns a field's structure symbol. If not defined, calls yyerror
node get_field(char *structure, char *field_name);

// Returns index if field exists, -1 if it doesn't (creo que no necesito)
//int test_field(char *function, char *name);

// Returns the number of field that a structure has
int get_field_count(char *structure);

// Return the name structure, if the structure name doesn't exist, calls yerror
node get_structure(char *structure, char *struct_name);

/* GLOBAL VARIABLES */
extern int line;

int breakable = 0;
int continueable = 0;

char *function_name = NULL;
char *struct_name = NULL;
node s = (node){0};
int arg_count = 0;
int flag_count_args = 0;
int flag_in_struct = 0;

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

%token DOT

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
:   function_definition
|   structure_definition
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
:   INT MAIN OPP CLP { fprintf(outfd, "static void main(String[] args)"); add_symbol("main", ST_FUNCTION, INT, 0); enter_function("main"); } function_body
;

function_definition
:   function_type IDENTIFIER OPP { fprintf(outfd, "%s(", $2); function_name = $2; add_symbol(function_name, ST_FUNCTION, s.data_type, 0); } parameters CLP { fprintf(outfd, ")"); enter_function(function_name); } function_body
;

function_body
:   OPCB { fprintf(outfd, "{"); } statement_sequence CLCB { fprintf(outfd, "}"); exit_scope(); }
|   error { yyerror("Funcion sin cuerpo"); }
;

function_call
:   IDENTIFIER OPP { get_symbol($1); fprintf(outfd, "%s(", $1); function_name = $1; flag_count_args = 1; arg_count = 0; } argument_list CLP { fprintf(outfd, ")"); flag_count_args = 0; if (get_parameter_count(function_name) != arg_count) {char msg[BUFSIZ]; sprintf(msg, "Llamada a '%s' con numero incorrecto de argumentos: %d, esperaba %d", function_name, arg_count, get_parameter_count(function_name)); yyerror(msg); } }
;

parameters
:
|   parameter_list
;

parameter_list
:   parameter_list_end
|   parameter_list COMMA { fprintf(outfd, ", "); } parameter_list_end
;

parameter_list_end
:   identifier_declaration { add_parameter(function_name, s.name, ST_VARIABLE, s.data_type, s.is_const); }
;

argument_list
:
|   expression_list
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
|   statement_no_end error ENDS { yyerror("Falta un ';' al final de la sentencia"); }
;

conditional_statement
:   IF { fprintf(outfd, "if "); } condition { enter_scope(); } block else_statement
//| SWITCH '(' expression ')' block
;

else_statement
:
|   ELSE { fprintf(outfd, "else "); enter_scope(); } block
;

statement_no_end
:   RETURN { fprintf(outfd, "return "); } expression
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
:   WHILE { fprintf(outfd, "while "); enter_scope(); } condition block_continueable
|   FOR OPP { fprintf(outfd, "for ("); enter_scope(); } variable_declaration ENDS { fprintf(outfd, "; "); } expression ENDS { fprintf(outfd, "; "); } expression CLP { fprintf(outfd, ")"); } block_continueable
;

do_loop
:   DO { fprintf(outfd, "do "); enter_scope(); } block_continueable WHILE { fprintf(outfd, " while "); } condition
;

block_breakable
:   { breakable = 1; } block { breakable = 0; }
;

block_continueable
:   { continueable = 1; } block_breakable { continueable = 0; }
;

block
:   { fprintf(outfd, "{"); } statement { fprintf(outfd, "}"); exit_scope(); }
|   OPCB { fprintf(outfd, "{"); } statement_sequence CLCB { fprintf(outfd, "} "); exit_scope(); }
;

condition
:   expression_p
;

type_qualifier
:   CONST   { fprintf(outfd, "final "); s.is_const = 1; }
;

variable_type 
:   INT      { fprintf(outfd, "int "); s.data_type = INT; }
|   CHAR     { fprintf(outfd, "char "); s.data_type = CHAR; }
|   SHORT    { fprintf(outfd, "short "); s.data_type = SHORT; }
|   LONG     { fprintf(outfd, "long "); s.data_type = LONG; }
|   FLOAT    { fprintf(outfd, "float "); s.data_type = FLOAT; }
|   DOUBLE   { fprintf(outfd, "double "); s.data_type = DOUBLE; }
|   BOOL     { fprintf(outfd, "boolean "); s.data_type = BOOL; }
|   STRUCT IDENTIFIER { fprintf(outfd, "%s ", $2); s.data_type = STRUCT; node temp_s = get_symbol($2); s.args = temp_s.args; struct_name = $2; }
;

function_type
:   variable_type
|   VOID { fprintf(outfd, "void "); s.data_type = VOID; }
;

identifier_declaration
:   variable_type IDENTIFIER                { fprintf(outfd, $2); if (s.data_type == STRUCT) fprintf(outfd, " = new %s()", struct_name); s.name = $2; s.is_const = 0; }
|   type_qualifier variable_type IDENTIFIER { fprintf(outfd, $3); s.name = $3; }
|   UNSIGNED INT IDENTIFIER                 { fprintf(outfd, "int %s", $3); s.name = $3; s.data_type = INT; s.is_const = 0; }
|   UNSIGNED CHAR IDENTIFIER                { fprintf(outfd, "char %s", $3); s.name = $3; s.data_type = CHAR; s.is_const = 0; }
|   UNSIGNED SHORT IDENTIFIER               { fprintf(outfd, "short %s", $3); s.name = $3; s.data_type = SHORT; s.is_const = 0; }
|   UNSIGNED LONG IDENTIFIER                { fprintf(outfd, "long %s", $3); s.name = $3; s.data_type = LONG; s.is_const = 0; }
;

variable_declaration
:   identifier_declaration { add_symbol(s.name, ST_VARIABLE, s.data_type, s.is_const); if (s.data_type == STRUCT) { get_symbol_ptr(s.name)->args = s.args; } }
|   identifier_declaration { add_symbol(s.name, ST_VARIABLE, s.data_type, s.is_const); if (s.data_type == STRUCT) { yyerror("No admite asignar a estructuras al declarar"); }} assign expression
|   variable_declaration COMMA error ENDS { yyerror("No se admiten declaraciones multiples"); yyerrok; }
;

assignment
:   IDENTIFIER { get_symbol($1); fprintf(outfd, "%s", $1); } assign_op expression
|   IDENTIFIER DOT IDENTIFIER { s = get_symbol($1); if (s.data_type == STRUCT) s = get_field($1, $3); fprintf(outfd, "%s.%s", $1, $3); } assign_op expression
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
:   expression { if (flag_count_args) arg_count++; }
|   expression COMMA { fprintf(outfd, ", "); if (flag_count_args) arg_count++; } expression_list
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
:   IDENTIFIER { get_symbol($1); fprintf(outfd, $1); }
|   unary_pre IDENTIFIER { get_symbol($2); fprintf(outfd, $2); }
|   IDENTIFIER { get_symbol($1); fprintf(outfd, $1); } unary_post
|   literal
|   IDENTIFIER DOT IDENTIFIER { s = get_symbol($1); if (s.data_type == STRUCT) { s = get_field($1, $3); fprintf(outfd, "%s.%s", $1, $3); } else { char msg[BUFSIZ]; sprintf(msg, "'%s' no es una estructura, no puede usarse el operador '.'", $1); yyerror(msg); } }
|   unary_pre IDENTIFIER DOT IDENTIFIER { s = get_symbol($2); if (s.data_type == STRUCT) { s = get_field($2, $4); fprintf(outfd, "%s.%s", $2, $4); } else { char msg[BUFSIZ]; sprintf(msg, "'%s' no es una estructura, no puede usarse el operador '.'", $2); yyerror(msg); } }
|   IDENTIFIER DOT IDENTIFIER { s = get_symbol($1); if (s.data_type == STRUCT) { s = get_field($1, $3); fprintf(outfd, "%s.%s", $1, $3); } else { char msg[BUFSIZ]; sprintf(msg, "'%s' no es una estructura, no puede usarse el operador '.'", $1); yyerror(msg); } } 
                                unary_post
;

expression_0
:   value
|   expression_p
|   function_call
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

/*structures*/

structure_definition
:   STRUCT IDENTIFIER { fprintf(outfd, "class %s", $2); struct_name = $2; add_symbol(struct_name, ST_STRUCT, STRUCT, 0); enter_structure($2); } structure_fields ENDS
|   TYPEDEF STRUCT IDENTIFIER { fprintf(outfd, "class %s", $3); struct_name = $3; add_symbol(struct_name, ST_STRUCT, STRUCT, 0); enter_structure($3); } structure_fields ENDS
;

structure_fields
:   OPCB { fprintf(outfd, "{"); flag_in_struct = 1; } structure_field_list CLCB { fprintf(outfd, "}"); exit_scope(); flag_in_struct = 0; }
//|   error { yyerror("Estructura sin propiedades definidas");}
;

structure_field_list
:   structure_field
|   structure_field_list structure_field 
;

structure_field
:   identifier_declaration {add_field(struct_name, s.name, ST_VARIABLE, s.data_type, s.is_const); } ENDS
;

/*structure_assignation
:   STRUCT IDENTIFIER { }

structure_call
: */  

%%

int main(int argc, char **argv)
{
    FILE *infd = NULL;

    if (argc >= 3)
    {
        infd = fopen(argv[1], "rt");
        if (!infd)
        {
            fprintf(stderr, "No se pudo abrir el archivo '%s'\n", argv[1]);
            return EXIT_FAILURE;
        }
        
        outfd = fopen(argv[2], "wt");
        if (!outfd)
        {
            fprintf(stderr, "No se pudo abrir el archivo '%s'\n", argv[2]);
            return EXIT_FAILURE;
        }
    } else
    {
        fprintf(stderr, "Uso: %s <archivo entrada C> <archivo salida Groovy>\n", argv[0]);
        return EXIT_FAILURE;
    }

    // Initialize scope stack
    init_stack(&symbol_table);
    enter_scope();  // global scope

    // Change input to file instead of stdin
    yyin = infd;
    yyparse();

    fclose(infd);
    fclose(outfd);
    return 0;
}

int yyerror(char *s)
{
    printf("\nError linea %d: %s\n", line, s);

    return 0;
}

// Create and enter new scope, example: enter new block with '{' or 'for' loop
void enter_scope()
{
    // Create new linked-list head, with NULL name to signify the end of the list
    push_stack(&symbol_table, init_symbol(NULL, ST_NULL, VOID, 0));
}

// Create and enter a new function scope, with the formal parameters already defined in the new scope
void enter_function(char *name)
{
    node *a = get_symbol(name).args;
    enter_scope();

    while (a->name)
    {
        add_symbol(a->name, a->symbol_type, a->data_type, a->is_const);
        a = a->next;
    }
}

// Leave a scope, example when exiting a block with '}'
void exit_scope()
{
    free_node(pop_stack(&symbol_table));
}

// Returns an integer indicating scope level, 0 = global
int get_scope()
{
    return symbol_table.top - 1;
}

// Add new symbol to scope. If already defined, calls yyerror
void add_symbol(char *name, int symbol_type, int data_type, int is_const)
{
    int sc = test_symbol(name);
    if (sc != -1)
    {
        node s = get_symbol(name);
        if (s.symbol_type == ST_FUNCTION)
        {
            char msg[BUFSIZ];
            sprintf(msg, "Simbolo '%s' ya definido como funcion", name);
            yyerror(msg);
            return;
        }
        if (sc == get_scope())
        {
            char msg[BUFSIZ];
            sprintf(msg, "Simbolo '%s' ya definido en este ambito", name);
            yyerror(msg);
            return;
        }
    }

    node *table = &(symbol_table.array[symbol_table.top - 1]);
    node *new_symbol = malloc(sizeof(node));
    *new_symbol = *table;
    *table = init_symbol(name, symbol_type, data_type, is_const);
    (*table).next = new_symbol;
    if (symbol_type == ST_FUNCTION || symbol_type == ST_STRUCT)
    {
        table->args = malloc(sizeof(node));
        *table->args = init_symbol(NULL, ST_NULL, VOID, 0);
    }
}

// Add new formal parameter to a function
void add_parameter(char *function, char *name, int symbol_type, int data_type, int is_const)
{
    node *f = get_symbol_ptr(function);

    node *table = f->args;

    if (test_parameter(function, name) != -1)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Parametro '%s' ya definido en la funcion '%s'", name, function);
        yyerror(msg);
        return;
    }

    while (table->next)
        table = table->next;
    node *new_symbol = malloc(sizeof(node));
    *new_symbol = *table;
    *table = init_symbol(name, symbol_type, data_type, is_const);
    (*table).next = new_symbol;
}

// Returns a symbol. If not defined, calls yyerror
node get_symbol(char *name)
{
    node n;
    int found = 0;
    for (int i = symbol_table.top - 1; i >= 0 && !found; i--)
    {
        n = symbol_table.array[i];

        while (n.name != NULL && !found)
        {
            if (strcmp(n.name, name) == 0)
            {
                found = 1;
                continue;
            }
            if (n.next == NULL)
                break;
            n = *n.next;
        }
    }

    if (!found)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Simbolo '%s' no definido", name);
        yyerror(msg);
        return (node){0};
    }
    return n;
}

// Returns level if symbol exists, -1 if it doesn't
int test_symbol(char *name)
{
    node n;
    int found = 0;
    for (int i = symbol_table.top - 1; i >= 0; i--)
    {
        n = symbol_table.array[i];

        while (n.name != NULL)
        {
            if (strcmp(n.name, name) == 0)
            {
                return i;
            }
            if (n.next == NULL)
                break;
            n = *n.next;
        }
    }

    return -1;
}

node *get_symbol_ptr(char *name)
{
    node *n;
    int found = 0;
    for (int i = symbol_table.top - 1; i >= 0 && !found; i--)
    {
        n = &symbol_table.array[i];

        while (n->name != NULL && !found)
        {
            if (strcmp(n->name, name) == 0)
            {
                found = 1;
                continue;
            }
            if (n->next == NULL)
                break;
            n = n->next;
        }
    }

    if (!found)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Simbolo '%s' no definido", name);
        yyerror(msg);
        return NULL;
    }
    return n;
}

// Returns a function parameter symbol. If not defined, calls yyerror
node get_parameter(char *function, int index)
{
    node *param = get_symbol_ptr(function)->args;

    while (param)
    {
        if (param->name == NULL)
        {
            char msg[BUFSIZ];
            sprintf(msg, "Demasiados argumentos para la funcion '%s'", function);
            yyerror(msg);
            return (node){0};
        }
        if (index == 0)
            return *param;
        index--;
        param = param->next;
    }
}

// Returns index if parameter exists, -1 if it doesn't
int test_parameter(char *function, char *name)
{
    node n = get_symbol(function);
    if (!n.name)
        return -1;
    n = *get_symbol(function).args;
    int i = 0;
    while (n.name != NULL)
    {
        if (strcmp(n.name, name) == 0)
        {
            return i;
        }
        if (n.next == NULL)
            break;
        n = *n.next;
        i++;
    }

    return -1;
}

// Returns the number of parameters that a function takes
int get_parameter_count(char *function)
{
    node n = get_symbol(function);
    if (!n.name)
        return 0;
    else if (n.symbol_type != ST_FUNCTION && n.symbol_type != ST_STRUCT)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Simbolo '%s' no es una funcion", function);
        yyerror(msg);
        return 0;
    }
    n = *get_symbol(function).args;
    int i = 0;
    while (n.name != NULL)
    {
        if (n.next == NULL)
            break;
        n = *n.next;
        i++;
    }

    return i;
}


/*--------- Structure function's implementation -------- */

//Create and enter a new class scope, with the formal fields defined in the new scope
void enter_structure(char *name){
    //Get the arguments of the function from the symbol table 
    node *a = get_symbol(name).args;
    enter_scope();

    while (a->name)
    {
        add_symbol(a->name, a->symbol_type, a->data_type, a->is_const);
        a = a->next;
    }
}

//Add new formal field to a class
void add_field(char *structure, char* name, int symbol_type, int data_type, int is_const){
    node *f = get_symbol_ptr(structure);

    node *table = f->args;

    if (test_parameter(structure, name) != -1)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Campo '%s' ya definido en la estructura '%s'", name);
        yyerror(msg);
        return;
    }

    while (table->next)
        table = table->next;
    node *new_symbol = malloc(sizeof(node));
    *new_symbol = *table;
    *table = init_symbol(name, symbol_type, data_type, is_const);
    (*table).next = new_symbol;
}

// Returns a structure's field symbol. If not defined, calls yyerror
node get_field(char *structure, char *field_name){
    node *field = get_symbol_ptr(structure)->args;

    while (field->name != NULL)
    {
        if (strcmp(field->name, field_name) == 0)
            return *field;

        field = field->next;
    }

    // If while finish and there's no return, get a error message that field does not exist
    char msg[BUFSIZ];
    //No such property: name for class: Person
    sprintf(msg, "No existe el campo '%s' para la estructura '%s'", field_name, structure);
    yyerror(msg);

    return (node){0};
}

// Returns the number of field that a structure has
int get_field_count(char *structure){
    node n = get_symbol(structure);
    if (!n.name)
        return 0;
    else if (n.symbol_type != ST_STRUCT)
    {
        char msg[BUFSIZ];
        sprintf(msg, "Simbolo '%s' no es una estructura", structure);
        yyerror(msg);
        return 0;
    }
    n = *get_symbol(structure).args;
    int i = 0;
    while (n.name != NULL)
    {
        if (n.next == NULL)
            break;
        n = *n.next;
        i++;
    }

    return i;
}

/*char* get_structure(char *structure, char *struct_name){

}*/