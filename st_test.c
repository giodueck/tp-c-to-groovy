#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SYMBOL TABLE */

// Symbol types for node
#define ST_NULL    -1
#define ST_VARIABLE 0
#define ST_FUNCTION 1
#define ST_TYPEDEF  2
#define ST_STRUCT   3

#define VOID 0

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

            if (s.symbol_type == ST_FUNCTION)
            {
                for (int i = 0; i < level; i++) printf("  ");
                printf(" params: ");
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

int main()
{
    node s;

    init_stack(&symbol_table);
    enter_scope();  // global scope
    add_symbol("variable", ST_VARIABLE, 1, 0);
    add_symbol("main", ST_FUNCTION, 1, 0);
    enter_scope();
    add_symbol("function", ST_FUNCTION, VOID, 0);
    add_parameter("function", "arg1", ST_VARIABLE, 1, 1);
    add_parameter("function", "arg2", ST_VARIABLE, 2, 1);
    add_parameter("function", "arg1", ST_VARIABLE, 1, 1);
    add_symbol("local variable", ST_VARIABLE, 2, 1);
    s = get_symbol("local variable");
    s = get_symbol("error");
    s = get_symbol("variable");
    s = get_symbol("function");
    s = get_parameter("function", 0);
    s = get_parameter("function", 1);
    s = get_parameter("function", 2);
    enter_function("function");
    s = get_symbol("arg2");
    add_symbol("local variable", ST_VARIABLE, 3, 0);

    dump_symbols();
    exit_scope();

    add_symbol("local variable", ST_VARIABLE, 3, 0);
    add_symbol("variable", ST_VARIABLE, 3, 0);
    add_symbol("main", ST_VARIABLE, 3, 0);

    exit_scope();

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
            printf("Simbolo ya definido como funcion\n");
            return;
        }
        if (sc == get_scope())
        {
            printf("Simbolo ya definido en este scope\n");
            return;
        }
    }

    node *table = &(symbol_table.array[symbol_table.top - 1]);
    node *new_symbol = malloc(sizeof(node));
    *new_symbol = *table;
    *table = init_symbol(name, symbol_type, data_type, is_const);
    (*table).next = new_symbol;
    if (symbol_type == ST_FUNCTION)
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
        printf("Parametro %s repetido\n", name);
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
        printf("Simbolo no definido\n");
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
        printf("Simbolo no definido\n");
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
            printf("Too many arguments\n");
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
    node n = *get_symbol(function).args;
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