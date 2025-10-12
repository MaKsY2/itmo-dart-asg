import 'dart:io';
import 'extensions.dart';

abstract class Logger {
  static void logErr(String msg) => stderr.writeln(msg.red);
  static void logOk(String msg) => stdout.writeln(msg.green);
}
