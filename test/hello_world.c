#include <stdio.h>

int main()
{
	printf("Hello, World\n");

	do
		printf("Do test\n");
	while (0);

	for (int abc; 5; printf("Infinite loop\n"))
		return 1;

	while (1)
	{
		printf("Infinite loop\n");

		return 0;
	}

	return 0;
}