String ansi(String s, List<int> codes) => '\x1B[${codes.join(';')}m$s\x1B[0m';

extension ColorX on String {
  String color(int code) => ansi(this, [code]);
  String get red => color(31);
  String get yellow => color(33);
  String get green => color(32);
  String bold() => ansi(this, [1]);
  String bgRed() => ansi(this, [41]);
}
