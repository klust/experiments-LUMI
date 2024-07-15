#include <stdlib.h>

int main()
{
  const int size = 10;
  int *array;
  int i;

  array = malloc(sizeof(int)*size);

#pragma omp parallel for
  for (i = 0; i<size; ++i) {
    array[i] = 3;
  }

  free(array);

  return 0;
}
