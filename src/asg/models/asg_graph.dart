import 'asg_node.dart';

class AsgGraph {
  final Map<String, AsgNode> nodes;
  final String rootId;

  AsgGraph({
    Map<String, AsgNode>? nodes,
    required this.rootId,
  }) : nodes = nodes ?? {};

  void addNode(AsgNode node) {
    nodes[node.id] = node;
  }

  AsgNode? getNode(String id) {
    return nodes[id];
  }

  List<AsgNode> getAllNodes() {
    return nodes.values.toList();
  }

  List<AsgEdge> getAllEdges() {
    final edges = <AsgEdge>[];
    for (final node in nodes.values) {
      edges.addAll(node.edges);
    }
    return edges;
  }

  void addEdge(String fromId, AsgEdge edge) {
    final node = nodes[fromId];
    if (node != null) {
      node.addEdge(edge);
    }
  }
}