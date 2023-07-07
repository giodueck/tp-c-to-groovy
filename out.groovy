


int factorial(long n)
{
    if (n <= 1)
        {return 1}
    else 
        {return n * factorial(n - 1)}
}

void noop(int a, int b, int c)
{
    printf("\n")
    return
}

static void main(String[] args)
{
    int fact = 1
    int n = 6

    for (int i = n; i > 0; i--)
    {
        fact *= i
    } 

    printf("%d! = %d\n", n, fact)

    n++
    int i = 1
    fact = i
    while (true)
    {
        fact *= i++
        if (i > n)
            {break}
        else {if (i <= n)
            {continue}
    }} 

    printf("%d! = %d\n", n, fact)

    final int m = 8
    printf("%d! = %d\n", m, factorial(m))

    noop(1, 2, 3)

    return 0
}