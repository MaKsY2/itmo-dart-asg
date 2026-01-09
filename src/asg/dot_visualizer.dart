import 'models/asg_graph.dart';
import 'models/asg_node.dart';

class DotVisualizer {
  String generateDot(AsgGraph graph) {
    final buffer = StringBuffer();
    
    buffer.writeln('digraph ASG {');
    buffer.writeln('  rankdir=TB;');
    buffer.writeln('  node [shape=box, style=rounded];');
    buffer.writeln('');

    for (final node in graph.getAllNodes()) {
      _writeNode(buffer, node);
    }

    buffer.writeln('');

    for (final node in graph.getAllNodes()) {
      for (final edge in node.edges) {
        _writeEdge(buffer, node.id, edge);
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeNode(StringBuffer buffer, AsgNode node) {
    final shape = _getNodeShape(node);
    final color = _getNodeColor(node);
    final label = _escapeLabel(node.label);
    
    buffer.write('  ${node.id} [');
    buffer.write('label="$label\\n(${node.nodeType})"');
    buffer.write(', shape=$shape');
    buffer.write(', fillcolor="$color"');
    buffer.write(', style="filled,rounded"');
    
    if (node is FunctionNode && node.returnType != null) {
      buffer.write(', tooltip="${node.returnType} ${node.label}"');
    } else if (node is VariableNode) {
      final modifiers = <String>[];
      if (node.isConst) modifiers.add('const');
      if (node.isFinal) modifiers.add('final');
      final prefix = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';
      final type = node.type ?? 'dynamic';
      buffer.write(', tooltip="$prefix$type ${node.label}"');
    } else if (node is BinaryOperationNode) {
      buffer.write(', tooltip="Binary: ${node.operator}"');
    } else if (node is MethodCallNode) {
      buffer.write(', tooltip="Call: ${node.methodName}"');
    }
    
    buffer.writeln('];');
  }

  void _writeEdge(StringBuffer buffer, String fromId, AsgEdge edge) {
    final color = _getEdgeColor(edge.type);
    final style = _getEdgeStyle(edge.type);
    final label = _escapeLabel(edge.label);
    
    buffer.write('  $fromId -> ${edge.targetId}');
    buffer.write(' [label="$label"');
    buffer.write(', color="$color"');
    buffer.write(', style=$style');
    buffer.write(', fontsize=10');
    buffer.writeln('];');
  }

  String _getNodeShape(AsgNode node) {
    if (node is FunctionNode) return 'ellipse';
    if (node is ClassNode) return 'component';
    if (node is VariableNode) return 'box';
    if (node is ParameterNode) return 'box';
    if (node is BlockNode) return 'folder';
    if (node is IfStatementNode) return 'diamond';
    if (node is ForLoopNode) return 'octagon';
    if (node is WhileLoopNode) return 'octagon';
    if (node is ReturnNode) return 'house';
    if (node is LiteralNode) return 'plaintext';
    if (node is BinaryOperationNode) return 'circle';
    if (node is MethodCallNode) return 'ellipse';
    return 'box';
  }

  String _getNodeColor(AsgNode node) {
    if (node is FunctionNode) return '#E8F4F8';
    if (node is ClassNode) return '#FFF4E6';
    if (node is VariableNode) return '#E8F5E9';
    if (node is ParameterNode) return '#F3E5F5';
    if (node is BlockNode) return '#F5F5F5';
    if (node is IfStatementNode) return '#FFF9C4';
    if (node is ForLoopNode) return '#FFE0B2';
    if (node is WhileLoopNode) return '#FFE0B2';
    if (node is ReturnNode) return '#FFCDD2';
    if (node is LiteralNode) return '#E1F5FE';
    if (node is BinaryOperationNode) return '#F8BBD0';
    if (node is MethodCallNode) return '#D1C4E9';
    if (node is AssignmentNode) return '#C8E6C9';
    return '#FFFFFF';
  }

  String _getEdgeColor(EdgeType type) {
    switch (type) {
      case EdgeType.controlFlow:
        return '#2196F3';
      case EdgeType.dataFlow:
        return '#4CAF50';
      case EdgeType.reference:
        return '#FF9800';
      case EdgeType.contains:
        return '#9E9E9E';
      case EdgeType.calls:
        return '#9C27B0';
      case EdgeType.defines:
        return '#F44336';
      case EdgeType.uses:
        return '#00BCD4';
    }
  }

  String _getEdgeStyle(EdgeType type) {
    switch (type) {
      case EdgeType.controlFlow:
        return 'bold';
      case EdgeType.dataFlow:
        return 'solid';
      case EdgeType.reference:
        return 'dashed';
      case EdgeType.contains:
        return 'solid';
      case EdgeType.calls:
        return 'bold';
      case EdgeType.defines:
        return 'solid';
      case EdgeType.uses:
        return 'dotted';
    }
  }

  String _escapeLabel(String label) {
    return label
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }

  String generateHtml(AsgGraph graph) {
    final dot = generateDot(graph);
    final escapedDot = dot
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ASG Visualization</title>
    <script src="https://cdn.jsdelivr.net/npm/viz.js@2.1.2/viz.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/viz.js@2.1.2/full.render.js"></script>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
        }
        #container {
            max-width: 100%;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 20px;
        }
        h1 {
            margin-top: 0;
            color: #333;
        }
        #graph {
            width: 100%;
            overflow: auto;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
        }
        .legend {
            margin-top: 20px;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 4px;
        }
        .legend h3 {
            margin-top: 0;
        }
        .legend-item {
            display: inline-block;
            margin: 5px 15px 5px 0;
        }
        .legend-color {
            display: inline-block;
            width: 20px;
            height: 20px;
            margin-right: 5px;
            vertical-align: middle;
            border: 1px solid #ccc;
        }
    </style>
</head>
<body>
    <div id="container">
        <h1>Abstract Semantic Graph (ASG)</h1>
        <div id="graph"></div>
        <div class="legend">
            <h3>Legend</h3>
            <div>
                <strong>Node Types:</strong><br>
                <span class="legend-item"><span class="legend-color" style="background: #E8F4F8;"></span>Function</span>
                <span class="legend-item"><span class="legend-color" style="background: #FFF4E6;"></span>Class</span>
                <span class="legend-item"><span class="legend-color" style="background: #E8F5E9;"></span>Variable</span>
                <span class="legend-item"><span class="legend-color" style="background: #FFF9C4;"></span>If Statement</span>
                <span class="legend-item"><span class="legend-color" style="background: #FFE0B2;"></span>Loop</span>
                <span class="legend-item"><span class="legend-color" style="background: #FFCDD2;"></span>Return</span>
            </div>
            <div style="margin-top: 10px;">
                <strong>Edge Types:</strong><br>
                <span class="legend-item" style="color: #2196F3;">■ Control Flow</span>
                <span class="legend-item" style="color: #4CAF50;">■ Data Flow</span>
                <span class="legend-item" style="color: #FF9800;">■ Reference</span>
                <span class="legend-item" style="color: #9C27B0;">■ Calls</span>
                <span class="legend-item" style="color: #F44336;">■ Defines</span>
            </div>
        </div>
    </div>
    <script>
        var viz = new Viz();
        var dotString = `$escapedDot`;
        
        viz.renderSVGElement(dotString)
            .then(function(element) {
                document.getElementById('graph').appendChild(element);
            })
            .catch(error => {
                console.error('Error rendering graph:', error);
                document.getElementById('graph').innerHTML = 
                    '<p style="color: red;">Error rendering graph. Check console for details.</p>';
            });
    </script>
</body>
</html>
''';
  }
}