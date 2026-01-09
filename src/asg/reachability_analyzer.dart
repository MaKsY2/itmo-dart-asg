import 'models/asg_graph.dart';
import 'models/asg_node.dart';

class ReachabilityAnalyzer {
  final AsgGraph graph;
  final Set<String> _reachableNodes = {};
  final Map<String, List<String>> _blockChildren = {};
  final Set<String> _terminators = {};

  ReachabilityAnalyzer(this.graph);

  Set<String> analyzeReachability() {
    _reachableNodes.clear();
    _blockChildren.clear();
    _terminators.clear();
    
    _buildBlockChildrenMap();
    _identifyTerminators();
    
    final rootNode = graph.getNode(graph.rootId);
    if (rootNode != null) {
      _markReachable(rootNode.id, false);
    }
    
    return Set.from(_reachableNodes);
  }

  void _buildBlockChildrenMap() {
    for (final node in graph.nodes.values) {
      if (node is BlockNode || node is FunctionNode) {
        final children = <String>[];
        for (final edge in node.edges) {
          if (edge.type == EdgeType.contains || 
              edge.label == 'statement' || 
              edge.label == 'declares' ||
              edge.label == 'call' ||
              edge.label == 'expression') {
            children.add(edge.targetId);
          }
        }
        _blockChildren[node.id] = children;
      }
    }
  }

  void _identifyTerminators() {
    for (final node in graph.nodes.values) {
      if (node is ReturnNode) {
        _terminators.add(node.id);
      }
    }
  }

  void _markReachable(String nodeId, bool insideFunctionBody) {
    if (_reachableNodes.contains(nodeId)) {
      return;
    }
    
    _reachableNodes.add(nodeId);
    final node = graph.getNode(nodeId);
    if (node == null) return;
    
    if (node is FunctionNode) {
      for (final edge in node.edges) {
        if (edge.label == 'parameter') {
          _markReachable(edge.targetId, false);
        } else if (edge.label == 'body') {
          _markReachable(edge.targetId, true);
        }
      }
      return;
    }
    
    if ((node is BlockNode || node is FunctionNode) && insideFunctionBody) {
      final children = _blockChildren[nodeId] ?? [];
      for (int i = 0; i < children.length; i++) {
        final childId = children[i];
        _markReachable(childId, insideFunctionBody);
        
        if (_terminators.contains(childId)) {
          break;
        }
        
        if (_containsTerminator(childId)) {
          break;
        }
      }
    } else {
      for (final edge in node.edges) {
        if (edge.type != EdgeType.controlFlow || edge.label != 'next') {
          _markReachable(edge.targetId, insideFunctionBody);
        }
      }
    }
  }

  bool _containsTerminator(String nodeId) {
    final node = graph.getNode(nodeId);
    if (node == null) return false;
    if (_terminators.contains(nodeId)) return true;
    
    for (final edge in node.edges) {
      if (edge.type == EdgeType.contains) {
        if (_terminators.contains(edge.targetId)) {
          return true;
        }
        if (_containsTerminator(edge.targetId)) {
          return true;
        }
      }
    }
    
    return false;
  }

  Set<String> getUnreachableNodes() {
    final allNodeIds = graph.nodes.keys.toSet();
    return allNodeIds.difference(_reachableNodes);
  }
}