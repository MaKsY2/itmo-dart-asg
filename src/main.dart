import 'dart:io';
import 'package:path/path.dart' as p;

import 'asg/asg_builder.dart';
import 'asg/dot_visualizer.dart';

void main(List<String> arguments) async {
  final testProgramsDir = Directory('test/test_programs');
  final outputDir = Directory('output');

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  if (!await testProgramsDir.exists()) {
    print('Error: test/test_programs directory not found');
    exit(1);
  }

  final testFiles = testProgramsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  if (testFiles.isEmpty) {
    print('No test files found');
    exit(1);
  }

  final hasGraphviz = await _checkGraphviz();

  if (!hasGraphviz) {
    print('hasGraphviz is false');
    exit(1);
  }

  for (final file in testFiles) {
    final fileName = p.basenameWithoutExtension(file.path);
    
    try {
      final source = await file.readAsString();
      final builder = AsgBuilder();
      final graph = builder.buildFromSource(source);
      final visualizer = DotVisualizer();
      
      final dotContent = visualizer.generateDot(graph);
      final dotFile = File(p.join(outputDir.path, '$fileName.dot'));
      await dotFile.writeAsString(dotContent);
      
      if (hasGraphviz) {
        final pngFile = p.join(outputDir.path, '$fileName.png');
        await Process.run('dot', ['-Tpng', dotFile.path, '-o', pngFile]);
      }
    } catch (e) {
      print('Error processing $fileName: $e');
    }
  }
}

Future<bool> _checkGraphviz() async {
  try {
    final result = await Process.run('dot', ['-V']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}