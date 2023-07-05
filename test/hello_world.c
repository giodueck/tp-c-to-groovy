#include <stdio.h>
#include <stdbool.h>

int main()
{
	printf("Hello, World\n");

	int a;
	int b;
	int c;
	bool d;
    
	a = 1;
	b = 2;
	c = 3;

	a = -1 + 10;
	b = (a)?0:1;
	c = (a << c) + 14 * 1;
	b += 2;
	c >>= b;
	d = ((a > 0) ? 1 : 0) || !false;

	printf("%d\n", a);
	printf("%d\n", b);
	printf("%d\n", c);
	printf("%d\n", d);

	return 0;
}