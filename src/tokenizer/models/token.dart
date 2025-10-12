import 'token_type.dart';
import 'span.dart';

class Token {
  final TokenType type;
  final String value;

  final Span span;

  Token({
    required this.type,
    required this.value,
    required this.span,
  });

  @override
  String toString() => '$type("$value")@$span';
}
