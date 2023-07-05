#include <stdio.h>

int main()
{
	printf("Hello, World\n");

	int a;
	int b;
	int c;
    
	a = 1;
	b = 2;
	c = 3;

	a = -1 + 10;
	b = (a)?0:1;
	c = (a << c) + 14 * 1;
	b += 2;
	c >>= b;

	printf("%d\n", a);
	printf("%d\n", b);
	printf("%d\n", c);

	return 0;
}