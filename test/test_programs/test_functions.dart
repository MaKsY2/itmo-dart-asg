int add(int a, int b) {
  return a + b;
}

int multiply(int x, int y) {
  int result = x * y;
  return result;
}

void printMessage(String message) {
  print(message);
}

int factorial(int n) {
  if (n <= 1) {
    return 1;
  }
  return n * factorial(n - 1);
}

void main() {
  int sum = add(5, 3);
  print(sum);

  int product = multiply(4, 7);
  print(product);

  printMessage('Hello from function');

  int fact = factorial(5);
  print('Factorial: $fact');
}