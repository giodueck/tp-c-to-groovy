#include <stdio.h>
#include <stdbool.h>

struct Fact {
    int res;
    int n;
};

int factorial(long n)
{
    if (n <= 1)
        return 1;
    
    return n * factorial(n - 1);
}

void noop(int a, int b, int c)
{
    printf("\n");
    return;
}

int main()
{
    int fact = 1;
    int n = 6;

    for (int i = n; i > 0; i--)
    {
        fact *= i;
    }

    printf("%d! = %d\n", n, fact);

    n++;
    int i = 1;
    fact = i;
    while (true)
    {
        fact *= i++;
        if (i > n)
            break;
        else if (i <= n)
            continue;
    }

    printf("%d! = %d\n", n, fact);

    const int m = 8;
    printf("%d! = %d\n", m, factorial(m));

    noop(1, 2, 3);

    struct Fact some_fact;

    some_fact.n = 0;
    some_fact.res = factorial(some_fact.n);
    printf("%d! = %d\n", some_fact.n, some_fact.res);

    return 0;
}