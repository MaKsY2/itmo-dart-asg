import 'models/span.dart';
import 'models/token.dart';
import 'models/token_type.dart';

class Lexer {
  final String source;
  final List<Token> tokens;

  int _i = 0;

  Lexer({
    required this.source,
  }) : tokens = [];

  bool get _eof => _i >= source.length;
  String _ch(int i) => i < source.length ? source[i] : '\u0000';
  String get _c => _ch(_i);
  String get _n => _ch(_i + 1);

  void lex() {
    while (!_eof) {
      final c = _c;
      if (c.trim().isEmpty) {
        _i++;
        continue;
      }
      if (c == '/' && _n == '/') {
        _i += 2;
        while (!_eof && _c != '\n') _i++;
        continue;
      }
      if (c == '/' && _n == '*') {
        _i += 2;
        while (!_eof && !(_c == '*' && _n == '/')) _i++;
        if (!_eof) _i += 2;
        continue;
      }

      final start = _i;
      if (_isIdentStart(c)) {
        _i++;
        while (!_eof && _isIdentCont(_c)) _i++;
        final lex = source.substring(start, _i);
        tokens.add(
          Token(
            type: _kwOrIdent(lex),
            value: lex,
            span: Span(start: start, end: _i),
          ),
        );
        continue;
      }
      if (_isDigit(c)) {
        _i++;
        while (!_eof && _isDigit(_c)) _i++;
        tokens.add(
          Token(
            type: TokenType.integer,
            value: source.substring(start, _i),
            span: Span(start: start, end: _i),
          ),
        );
        continue;
      }
      if (c == '\'' || c == '"') {
        final quote = c;
        _i++;
        while (!_eof && _c != quote) {
          _i++;
        }
        if (!_eof) _i++;
        tokens.add(
          Token(
            type: TokenType.string,
            value: source.substring(start + 1, _i - 1),
            span: Span(start: start, end: _i),
          ),
        );
        continue;
      }

      String two = c + _n;
      switch (two) {
        case '==':
          _emitToken(TokenType.eqEq, 2, start);
          continue;
        case '!=':
          _emitToken(TokenType.bangEq, 2, start);
          continue;
        case '<=':
          _emitToken(TokenType.ltEq, 2, start);
          continue;
        case '>=':
          _emitToken(TokenType.gtEq, 2, start);
          continue;
        case '&&':
          _emitToken(TokenType.ampAmp, 2, start);
          continue;
        case '||':
          _emitToken(TokenType.pipePipe, 2, start);
          continue;
      }
      switch (c) {
        case '(':
          _emitToken(TokenType.lParen, 1, start);
          continue;
        case ')':
          _emitToken(TokenType.rParen, 1, start);
          continue;
        case '{':
          _emitToken(TokenType.lBrace, 1, start);
          continue;
        case '}':
          _emitToken(TokenType.rBrace, 1, start);
          continue;
        case ',':
          _emitToken(TokenType.comma, 1, start);
          continue;
        case ';':
          _emitToken(TokenType.semicolon, 1, start);
          continue;
        case ':':
          _emitToken(TokenType.colon, 1, start);
          continue;
        case '.':
          _emitToken(TokenType.dot, 1, start);
          continue;
        case '+':
          _emitToken(TokenType.plus, 1, start);
          continue;
        case '-':
          _emitToken(TokenType.minus, 1, start);
          continue;
        case '*':
          _emitToken(TokenType.star, 1, start);
          continue;
        case '/':
          _emitToken(TokenType.slash, 1, start);
          continue;
        case '%':
          _emitToken(TokenType.percent, 1, start);
          continue;
        case '!':
          _emitToken(TokenType.bang, 1, start);
          continue;
        case '?':
          _emitToken(TokenType.question, 1, start);
          continue;
        case '=':
          _emitToken(TokenType.eq, 1, start);
          continue;
        case '<':
          _emitToken(TokenType.lt, 1, start);
          continue;
        case '>':
          _emitToken(TokenType.gt, 1, start);
          continue;
      }
      throw FormatException('Unexpected char: "$c" at $start');
    }
    tokens.add(
      Token(
        type: TokenType.eof,
        value: '',
        span: Span(start: _i, end: _i),
      ),
    );
  }

  void _emitToken(TokenType type, int length, int start) {
    tokens.add(
      Token(
        type: type,
        value: source.substring(start, start + length),
        span: Span(start: start, end: start + length),
      ),
    );
    _i += length;
  }

  static bool _isIdentStart(String c) => RegExp(r'[A-Za-z_]').hasMatch(c);
  static bool _isIdentCont(String c) => RegExp(r'[A-Za-z0-9_]').hasMatch(c);
  static bool _isDigit(String c) => RegExp(r'[0-9]').hasMatch(c);

  static const _kwMap = <String, TokenType>{
    'var': TokenType.kwVar,
    'final': TokenType.kwFinal,
    'const': TokenType.kwConst,
    'if': TokenType.kwIf,
    'else': TokenType.kwElse,
    'return': TokenType.kwReturn,
    'true': TokenType.kwTrue,
    'false': TokenType.kwFalse,
    'null': TokenType.kwNull,
    'int': TokenType.kwInt,
    'double': TokenType.kwDouble,
    'bool': TokenType.kwBool,
    'String': TokenType.kwString,
    'void': TokenType.kwVoid,
    'dynamic': TokenType.kwDynamic,
  };

  static TokenType _kwOrIdent(String lex) =>
      _kwMap[lex] ?? TokenType.identifier;
}
