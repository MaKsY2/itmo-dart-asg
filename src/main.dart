import 'dart:io';

import '../test/test.dart';
import 'tokenizer/lexer.dart';

void main() async {
  final tester = Tester();
  await tester.init();
  for (final testSource in tester.testSources.entries) {
    final lexer = Lexer(source: testSource.value);
    lexer.lex();
    await tester.writeResults(testSource.key, lexer.getTokensAsString());
    tester.checkResultes();
  }
}
