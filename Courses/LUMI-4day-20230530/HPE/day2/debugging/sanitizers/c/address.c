#include <stdlib.h>

int main()
{
  const int size = 10;
  int *array;

  array = malloc(sizeof(int)*size);

  array[size] = 3;

  free(array);

  return 0;
}
