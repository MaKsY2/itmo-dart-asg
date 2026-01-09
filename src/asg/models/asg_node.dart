abstract class AsgNode {
  final String id;
  final String label;
  final List<AsgEdge> edges;

  AsgNode({
    required this.id,
    required this.label,
    List<AsgEdge>? edges,
  }) : edges = edges ?? [];

  void addEdge(AsgEdge edge) {
    edges.add(edge);
  }

  String get nodeType;
}

class AsgEdge {
  final String targetId;
  final String label;
  final EdgeType type;

  AsgEdge({
    required this.targetId,
    required this.label,
    required this.type,
  });
}

enum EdgeType {
  controlFlow,
  dataFlow,
  reference,
  contains,
  calls,
  defines,
  uses,
}

class FunctionNode extends AsgNode {
  final String? returnType;
  final List<ParameterNode> parameters;

  FunctionNode({
    required super.id,
    required super.label,
    this.returnType,
    List<ParameterNode>? parameters,
  }) : parameters = parameters ?? [];

  @override
  String get nodeType => 'Function';
}

class ParameterNode extends AsgNode {
  final String? type;

  ParameterNode({
    required super.id,
    required super.label,
    this.type,
  });

  @override
  String get nodeType => 'Parameter';
}

class VariableNode extends AsgNode {
  final String? type;
  final bool isFinal;
  final bool isConst;

  VariableNode({
    required super.id,
    required super.label,
    this.type,
    this.isFinal = false,
    this.isConst = false,
  });

  @override
  String get nodeType => 'Variable';
}

class ClassNode extends AsgNode {
  final List<FunctionNode> methods;
  final List<VariableNode> fields;

  ClassNode({
    required super.id,
    required super.label,
    List<FunctionNode>? methods,
    List<VariableNode>? fields,
  })  : methods = methods ?? [],
        fields = fields ?? [];

  @override
  String get nodeType => 'Class';
}

class BlockNode extends AsgNode {
  BlockNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'Block';
}

class ExpressionNode extends AsgNode {
  final String expressionType;

  ExpressionNode({
    required super.id,
    required super.label,
    required this.expressionType,
  });

  @override
  String get nodeType => 'Expression';
}

class LiteralNode extends AsgNode {
  final String literalType;
  final dynamic value;

  LiteralNode({
    required super.id,
    required super.label,
    required this.literalType,
    this.value,
  });

  @override
  String get nodeType => 'Literal';
}

class IfStatementNode extends AsgNode {
  IfStatementNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'IfStatement';
}

class ForLoopNode extends AsgNode {
  ForLoopNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'ForLoop';
}

class WhileLoopNode extends AsgNode {
  WhileLoopNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'WhileLoop';
}

class ReturnNode extends AsgNode {
  ReturnNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'Return';
}

class AssignmentNode extends AsgNode {
  AssignmentNode({
    required super.id,
    required super.label,
  });

  @override
  String get nodeType => 'Assignment';
}

class MethodCallNode extends AsgNode {
  final String methodName;

  MethodCallNode({
    required super.id,
    required super.label,
    required this.methodName,
  });

  @override
  String get nodeType => 'MethodCall';
}

class BinaryOperationNode extends AsgNode {
  final String operator;

  BinaryOperationNode({
    required super.id,
    required super.label,
    required this.operator,
  });

  @override
  String get nodeType => 'BinaryOperation';
}