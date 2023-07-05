#include <stdio.h>
#include <stdbool.h>

int main() {
    int entero = 10;
    char caracter = 'A';
    const int constante = 5;
    long largo = 1234567890;
    short corto = 50;
    unsigned int sinSigno = 100;
    double decimal = 3.14;
    bool booleano = true;

    printf("Entero: %d\n", entero);
    printf("Caracter: %c\n", caracter);
    printf("Constante: %d\n", constante);
    printf("Largo: %ld\n", largo);
    printf("Corto: %d\n", corto);
    printf("Sin signo: %u\n", sinSigno);
    printf("Decimal: %f\n", decimal);
    printf("Booleano: %s\n", booleano);

    return 0;
}