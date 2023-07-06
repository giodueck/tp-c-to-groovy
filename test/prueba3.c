#include <stdio.h>
#include <stdbool.h>

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

    return 0;
}