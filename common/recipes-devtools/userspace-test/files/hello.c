#include <stdio.h>

int value;

void f(void)
{
	value = 1;
	value ++;
	value ++;
	printf("a simple test: the value is %d\n", value);	
}

int main(void)
{
        printf("Hello world\n");
	f();
        return 0;
}
