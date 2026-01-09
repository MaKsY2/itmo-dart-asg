import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'models/asg_graph.dart';
import 'models/asg_node.dart';
import 'reachability_analyzer.dart';

class AsgBuilder {
  int _nodeCounter = 0;
  late AsgGraph _graph;
  final Map<String, String> _symbolTable = {};

  String _generateId() => 'node_${_nodeCounter++}';

  AsgGraph buildFromSource(String source) {
    _nodeCounter = 0;
    _symbolTable.clear();

    final parseResult = parseString(
      content: source,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final unit = parseResult.unit;
    final rootId = _generateId();
    _graph = AsgGraph(rootId: rootId);

    final rootNode = BlockNode(
      id: rootId,
      label: 'CompilationUnit',
    );
    _graph.addNode(rootNode);

    final visitor = _AsgVisitor(this, rootId);
    unit.visitChildren(visitor);

    _removeUnreachableNodes();

    return _graph;
  }

  void _addNode(AsgNode node) {
    _graph.addNode(node);
  }

  void _addEdge(String fromId, AsgEdge edge) {
    _graph.addEdge(fromId, edge);
  }

  void _removeUnreachableNodes() {
    final analyzer = ReachabilityAnalyzer(_graph);
    analyzer.analyzeReachability();
    final unreachable = analyzer.getUnreachableNodes();
    
    for (final nodeId in unreachable) {
      _graph.nodes.remove(nodeId);
    }
    
    for (final node in _graph.nodes.values) {
      node.edges.removeWhere((edge) => unreachable.contains(edge.targetId));
    }
  }
}

class _AsgVisitor extends RecursiveAstVisitor<void> {
  final AsgBuilder _builder;
  String _currentParentId;
  final List<String> _controlFlowStack = [];

  _AsgVisitor(this._builder, this._currentParentId);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final functionId = _builder._generateId();
    final functionNode = FunctionNode(
      id: functionId,
      label: node.name.lexeme,
      returnType: node.returnType?.toSource(),
    );

    _builder._addNode(functionNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: functionId,
        label: 'defines',
        type: EdgeType.defines,
      ),
    );

    if (node.functionExpression.parameters != null) {
      for (final param in node.functionExpression.parameters!.parameters) {
        final paramId = _builder._generateId();
        final paramNode = ParameterNode(
          id: paramId,
          label: param.name?.lexeme ?? 'unnamed',
          type: param is SimpleFormalParameter
              ? param.type?.toSource()
              : null,
        );
        _builder._addNode(paramNode);
        _builder._addEdge(
          functionId,
          AsgEdge(
            targetId: paramId,
            label: 'parameter',
            type: EdgeType.contains,
          ),
        );
        functionNode.parameters.add(paramNode);
      }
    }

    final previousParent = _currentParentId;
    _currentParentId = functionId;
    _controlFlowStack.add(functionId);

    node.functionExpression.body.accept(this);

    _controlFlowStack.removeLast();
    _currentParentId = previousParent;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final methodId = _builder._generateId();
    final methodNode = FunctionNode(
      id: methodId,
      label: node.name.lexeme,
      returnType: node.returnType?.toSource(),
    );

    _builder._addNode(methodNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: methodId,
        label: 'defines',
        type: EdgeType.defines,
      ),
    );

    if (node.parameters != null) {
      for (final param in node.parameters!.parameters) {
        final paramId = _builder._generateId();
        final paramNode = ParameterNode(
          id: paramId,
          label: param.name?.lexeme ?? 'unnamed',
          type: param is SimpleFormalParameter
              ? param.type?.toSource()
              : null,
        );
        _builder._addNode(paramNode);
        _builder._addEdge(
          methodId,
          AsgEdge(
            targetId: paramId,
            label: 'parameter',
            type: EdgeType.contains,
          ),
        );
        methodNode.parameters.add(paramNode);
      }
    }

    final previousParent = _currentParentId;
    _currentParentId = methodId;
    _controlFlowStack.add(methodId);

    node.body.accept(this);

    _controlFlowStack.removeLast();
    _currentParentId = previousParent;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final classId = _builder._generateId();
    final classNode = ClassNode(
      id: classId,
      label: node.name.lexeme,
    );

    _builder._addNode(classNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: classId,
        label: 'defines',
        type: EdgeType.defines,
      ),
    );

    final previousParent = _currentParentId;
    _currentParentId = classId;

    super.visitClassDeclaration(node);

    _currentParentId = previousParent;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final varId = _builder._generateId();
    final parent = node.parent;
    final isFinal = parent is VariableDeclarationList && parent.isFinal;
    final isConst = parent is VariableDeclarationList && parent.isConst;
    final type = parent is VariableDeclarationList
        ? parent.type?.toSource()
        : null;

    final varNode = VariableNode(
      id: varId,
      label: node.name.lexeme,
      type: type,
      isFinal: isFinal,
      isConst: isConst,
    );

    _builder._addNode(varNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: varId,
        label: 'declares',
        type: EdgeType.defines,
      ),
    );

    _builder._symbolTable[node.name.lexeme] = varId;

    if (node.initializer != null) {
      final initId = _visitExpression(node.initializer!);
      if (initId != null) {
        _builder._addEdge(
          varId,
          AsgEdge(
            targetId: initId,
            label: 'initializer',
            type: EdgeType.dataFlow,
          ),
        );
      }
    }
  }

  @override
  void visitBlock(Block node) {
    final blockId = _builder._generateId();
    final blockNode = BlockNode(
      id: blockId,
      label: 'Block',
    );

    _builder._addNode(blockNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: blockId,
        label: 'body',
        type: EdgeType.contains,
      ),
    );

    final previousParent = _currentParentId;
    _currentParentId = blockId;

    String? previousStmtId;
    bool previousWasTerminator = false;
    
    for (final stmt in node.statements) {
      final stmtId = _currentParentId;
      stmt.accept(this);
      
      if (previousStmtId != null && _controlFlowStack.isNotEmpty && !previousWasTerminator) {
        _builder._addEdge(
          previousStmtId,
          AsgEdge(
            targetId: stmtId,
            label: 'next',
            type: EdgeType.controlFlow,
          ),
        );
      }
      
      previousWasTerminator = stmt is ReturnStatement ||
                             stmt is BreakStatement ||
                             stmt is ContinueStatement;
      previousStmtId = stmtId;
    }

    _currentParentId = previousParent;
  }

  @override
  void visitIfStatement(IfStatement node) {
    final ifId = _builder._generateId();
    final ifNode = IfStatementNode(
      id: ifId,
      label: 'if',
    );

    _builder._addNode(ifNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: ifId,
        label: 'statement',
        type: EdgeType.contains,
      ),
    );

    final conditionId = _visitExpression(node.expression);
    if (conditionId != null) {
      _builder._addEdge(
        ifId,
        AsgEdge(
          targetId: conditionId,
          label: 'condition',
          type: EdgeType.dataFlow,
        ),
      );
    }

    final previousParent = _currentParentId;
    _currentParentId = ifId;
    _controlFlowStack.add(ifId);

    node.thenStatement.accept(this);

    if (node.elseStatement != null) {
      node.elseStatement!.accept(this);
    }

    _controlFlowStack.removeLast();
    _currentParentId = previousParent;
  }

  @override
  void visitForStatement(ForStatement node) {
    final forId = _builder._generateId();
    final forNode = ForLoopNode(
      id: forId,
      label: 'for',
    );

    _builder._addNode(forNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: forId,
        label: 'statement',
        type: EdgeType.contains,
      ),
    );

    final previousParent = _currentParentId;
    _currentParentId = forId;
    _controlFlowStack.add(forId);

    node.forLoopParts.accept(this);
    node.body.accept(this);

    _controlFlowStack.removeLast();
    _currentParentId = previousParent;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    final whileId = _builder._generateId();
    final whileNode = WhileLoopNode(
      id: whileId,
      label: 'while',
    );

    _builder._addNode(whileNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: whileId,
        label: 'statement',
        type: EdgeType.contains,
      ),
    );

    final conditionId = _visitExpression(node.condition);
    if (conditionId != null) {
      _builder._addEdge(
        whileId,
        AsgEdge(
          targetId: conditionId,
          label: 'condition',
          type: EdgeType.dataFlow,
        ),
      );
    }

    final previousParent = _currentParentId;
    _currentParentId = whileId;
    _controlFlowStack.add(whileId);

    node.body.accept(this);

    _controlFlowStack.removeLast();
    _currentParentId = previousParent;
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final returnId = _builder._generateId();
    final returnNode = ReturnNode(
      id: returnId,
      label: 'return',
    );

    _builder._addNode(returnNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: returnId,
        label: 'statement',
        type: EdgeType.contains,
      ),
    );

    if (node.expression != null) {
      final exprId = _visitExpression(node.expression!);
      if (exprId != null) {
        _builder._addEdge(
          returnId,
          AsgEdge(
            targetId: exprId,
            label: 'value',
            type: EdgeType.dataFlow,
          ),
        );
      }
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _visitExpression(node.expression);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final assignId = _builder._generateId();
    final assignNode = AssignmentNode(
      id: assignId,
      label: '${node.leftHandSide.toSource()} = ...',
    );

    _builder._addNode(assignNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: assignId,
        label: 'expression',
        type: EdgeType.contains,
      ),
    );

    final leftId = _visitExpression(node.leftHandSide);
    if (leftId != null) {
      _builder._addEdge(
        assignId,
        AsgEdge(
          targetId: leftId,
          label: 'target',
          type: EdgeType.dataFlow,
        ),
      );
    }

    final rightId = _visitExpression(node.rightHandSide);
    if (rightId != null) {
      _builder._addEdge(
        assignId,
        AsgEdge(
          targetId: rightId,
          label: 'value',
          type: EdgeType.dataFlow,
        ),
      );
    }
  }

  String? _visitExpression(Expression node) {
    if (node is BinaryExpression) {
      return _visitBinaryExpression(node);
    } else if (node is MethodInvocation) {
      return _visitMethodInvocation(node);
    } else if (node is SimpleIdentifier) {
      return _visitIdentifier(node);
    } else if (node is IntegerLiteral) {
      return _visitIntegerLiteral(node);
    } else if (node is StringLiteral) {
      return _visitStringLiteral(node);
    } else if (node is BooleanLiteral) {
      return _visitBooleanLiteral(node);
    } else if (node is InstanceCreationExpression) {
      return _visitInstanceCreation(node);
    } else {
      final exprId = _builder._generateId();
      final exprNode = ExpressionNode(
        id: exprId,
        label: node.toSource(),
        expressionType: node.runtimeType.toString(),
      );
      _builder._addNode(exprNode);
      _builder._addEdge(
        _currentParentId,
        AsgEdge(
          targetId: exprId,
          label: 'expression',
          type: EdgeType.contains,
        ),
      );
      return exprId;
    }
  }

  String _visitBinaryExpression(BinaryExpression node) {
    final binOpId = _builder._generateId();
    final binOpNode = BinaryOperationNode(
      id: binOpId,
      label: node.operator.lexeme,
      operator: node.operator.lexeme,
    );

    _builder._addNode(binOpNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: binOpId,
        label: 'expression',
        type: EdgeType.contains,
      ),
    );

    final leftId = _visitExpression(node.leftOperand);
    if (leftId != null) {
      _builder._addEdge(
        binOpId,
        AsgEdge(
          targetId: leftId,
          label: 'left',
          type: EdgeType.dataFlow,
        ),
      );
    }

    final rightId = _visitExpression(node.rightOperand);
    if (rightId != null) {
      _builder._addEdge(
        binOpId,
        AsgEdge(
          targetId: rightId,
          label: 'right',
          type: EdgeType.dataFlow,
        ),
      );
    }

    return binOpId;
  }

  String _visitMethodInvocation(MethodInvocation node) {
    final callId = _builder._generateId();
    final callNode = MethodCallNode(
      id: callId,
      label: node.methodName.name,
      methodName: node.methodName.name,
    );

    _builder._addNode(callNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: callId,
        label: 'call',
        type: EdgeType.calls,
      ),
    );

    if (node.target != null) {
      final targetId = _visitExpression(node.target!);
      if (targetId != null) {
        _builder._addEdge(
          callId,
          AsgEdge(
            targetId: targetId,
            label: 'target',
            type: EdgeType.reference,
          ),
        );
      }
    }

    for (final arg in node.argumentList.arguments) {
      final argId = _visitExpression(arg);
      if (argId != null) {
        _builder._addEdge(
          callId,
          AsgEdge(
            targetId: argId,
            label: 'argument',
            type: EdgeType.dataFlow,
          ),
        );
      }
    }

    return callId;
  }

  String _visitIdentifier(SimpleIdentifier node) {
    final existingId = _builder._symbolTable[node.name];
    if (existingId != null) {
      return existingId;
    }

    final identId = _builder._generateId();
    final identNode = ExpressionNode(
      id: identId,
      label: node.name,
      expressionType: 'Identifier',
    );

    _builder._addNode(identNode);
    return identId;
  }

  String _visitIntegerLiteral(IntegerLiteral node) {
    final litId = _builder._generateId();
    final litNode = LiteralNode(
      id: litId,
      label: node.value.toString(),
      literalType: 'int',
      value: node.value,
    );

    _builder._addNode(litNode);
    return litId;
  }

  String _visitStringLiteral(StringLiteral node) {
    final litId = _builder._generateId();
    final litNode = LiteralNode(
      id: litId,
      label: node.stringValue ?? '',
      literalType: 'String',
      value: node.stringValue,
    );

    _builder._addNode(litNode);
    return litId;
  }

  String _visitBooleanLiteral(BooleanLiteral node) {
    final litId = _builder._generateId();
    final litNode = LiteralNode(
      id: litId,
      label: node.value.toString(),
      literalType: 'bool',
      value: node.value,
    );

    _builder._addNode(litNode);
    return litId;
  }

  String _visitInstanceCreation(InstanceCreationExpression node) {
    final createId = _builder._generateId();
    final createNode = ExpressionNode(
      id: createId,
      label: 'new ${node.constructorName.type.name2.lexeme}',
      expressionType: 'InstanceCreation',
    );

    _builder._addNode(createNode);
    _builder._addEdge(
      _currentParentId,
      AsgEdge(
        targetId: createId,
        label: 'expression',
        type: EdgeType.contains,
      ),
    );

    for (final arg in node.argumentList.arguments) {
      final argId = _visitExpression(arg);
      if (argId != null) {
        _builder._addEdge(
          createId,
          AsgEdge(
            targetId: argId,
            label: 'argument',
            type: EdgeType.dataFlow,
          ),
        );
      }
    }

    return createId;
  }
}