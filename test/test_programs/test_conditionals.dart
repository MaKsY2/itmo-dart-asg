void main() {
  int x = 10;
  int y = 20;

  if (x < y) {
    print('x is less than y');
  } else {
    print('x is greater or equal to y');
  }

  if (x > 5) {
    if (y > 15) {
      print('Both conditions are true');
    }
  }

  String result = x > y ? 'x is greater' : 'y is greater';
  print(result);
}