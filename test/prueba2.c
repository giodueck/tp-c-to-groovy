#include <stdio.h>

struct Person {
    char name;
    int age;
    float height;
};

int main() 
{
    // Declarar una variable de tipo Person
    struct Person person;

    // Asignar valores a los miembros de la estructura
    person.name = 'c';
    person.age = 30;
    person.height = 1.75;

    // Imprimir los valores de la estructura
    printf("Name: %s\n", person.name);
    printf("Age: %d\n", person.age);
    printf("Height: %.2f\n", person.height);

    return 0;
}