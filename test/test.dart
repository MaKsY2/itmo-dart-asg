import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'utils/logger.dart';

class Tester {
  static const _testSources = 'test/test_programs';
  static const _testExpectations = 'test/test_expectations';
  static const _testResults = 'test/test_results';
  static const _chunkSize = 128 * 1024; // 128 KB
  final Map<String, String> testSources = {};

  static const reset = '\x1B[0m';
  static const red = '\x1B[31m';
  static const yellow = '\x1B[33m';
  static const green = '\x1B[32m';

  Tester();

  Future<void> init() async {
    print('Starting init Tester...');
    final dir = Directory(_testSources);

    final List<Future> futures = [];

    dir.listSync().forEach((entity) => futures.add(_addSources(entity)));
    await Future.wait(futures);

    print('Tester init result length: ${testSources.entries.length}');
  }

  Future<void> _addSources(FileSystemEntity entity) async {
    try {
      if (entity is File) {
        final fileName = p.basenameWithoutExtension(entity.path);
        final fileSrc = await entity.readAsString();
        testSources[fileName] = fileSrc;
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> writeResults(String testName, String results) async {
    final file = File(p.join(_testResults, testName));
    await file.writeAsString(results);
  }

  Future<void> checkResultes() async {
    final testResults = Directory(_testResults)
        .listSync()
        .map(
          (e) => e is File
              ? FilesWithNames(e, p.basenameWithoutExtension(e.path))
              : null,
        )
        .nonNulls
        .toList();
    final testExpectations = Directory(_testExpectations)
        .listSync()
        .map(
          (e) => e is File
              ? FilesWithNames(e, p.basenameWithoutExtension(e.path))
              : null,
        )
        .nonNulls;

    final mapStruct = <String, ComparableFiles>{};
    for (final srcName in testSources.keys) {
      final testFile =
          testResults.firstWhereOrNull((e) => e.name == srcName)?.file;
      final testExpectation =
          testExpectations.firstWhereOrNull((e) => e.name == srcName)?.file;
      if (testFile == null) {
        print('TestFile of $srcName is null');
        continue;
      }
      if (testExpectation == null) {
        print('TestExpectation of $srcName is null');
        continue;
      }
      mapStruct[srcName] = ComparableFiles(testFile, testExpectation);
    }

    for (final comparableFiles in mapStruct.values) {
      print(
        'Comparing ${comparableFiles.first.path} and ${comparableFiles.second.path}',
      );
      final result = await _isFilesIdentical(
        comparableFiles.first,
        comparableFiles.second,
      );
      !result ? Logger.logErr('ERROR') : Logger.logOk('OK');
    }
  }

  Future<bool> _isFilesIdentical(
    File firstEntity,
    File secondEntity,
  ) async {
    if (!await firstEntity.exists() || !await secondEntity.exists()) {
      return false;
    }

    final firstStat = await firstEntity.stat();
    final secondStat = await secondEntity.stat();
    if (firstStat.size != secondStat.size) {
      return false;
    }

    final firstRaf = await firstEntity.open();
    final secondRaf = await firstEntity.open();

    try {
      final firstBuffer = Uint8List(_chunkSize);
      final secondBuffer = Uint8List(_chunkSize);

      int remaining = firstStat.size;
      while (remaining > 0) {
        final toRead = math.min(_chunkSize, remaining);
        final readA = await firstRaf.readInto(firstBuffer, 0, toRead);
        final readB = await secondRaf.readInto(secondBuffer, 0, toRead);
        if (readA != readB) return false;

        for (var i = 0; i < readA; i++) {
          if (firstBuffer[i] != secondBuffer[i]) return false;
        }
        remaining -= readA;
      }
      return true;
    } finally {
      await firstRaf.close();
      await secondRaf.close();
    }
  }
}

class ComparableFiles {
  File first;
  File second;
  ComparableFiles(this.first, this.second);
}

class FilesWithNames {
  String name;
  File file;
  FilesWithNames(this.file, this.name);
}
