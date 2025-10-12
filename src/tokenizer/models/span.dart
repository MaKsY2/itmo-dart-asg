class Span {
  final int start;
  final int end;

  const Span({
    required this.start,
    required this.end,
  });

  @override
  String toString() => '$start..$end';
}
