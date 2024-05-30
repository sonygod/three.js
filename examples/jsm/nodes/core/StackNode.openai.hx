package three.js.examples.jsm.nodes.core;

import Node;
import math.CondNode;
import shadernode.ShaderNode;

class StackNode extends Node {
  public var nodes:Array<Node>;
  public var outputNode:Node;
  public var parent:Node;
  public var _currentCond:CondNode;
  public var isStackNode:Bool;

  public function new(?parent:Node) {
    super();
    this.nodes = [];
    this.outputNode = null;
    this.parent = parent;
    this._currentCond = null;
    this.isStackNode = true;
  }

  public function getNodeType(builder:Dynamic):String {
    return outputNode != null ? outputNode.getNodeType(builder) : 'void';
  }

  public function add(node:Node):StackNode {
    nodes.push(node);
    return this;
  }

  public function if_(boolNode:Node, method:Dynamic):StackNode {
    var methodNode = new ShaderNode(method);
    _currentCond = CondNode.cond(boolNode, methodNode);
    return add(_currentCond);
  }

  public function elseif_(boolNode:Node, method:Dynamic):StackNode {
    var methodNode = new ShaderNode(method);
    var ifNode = CondNode.cond(boolNode, methodNode);
    _currentCond.elseNode = ifNode;
    _currentCond = ifNode;
    return this;
  }

  public function else_(method:Dynamic):StackNode {
    _currentCond.elseNode = new ShaderNode(method);
    return this;
  }

  public function build(builder:Dynamic, params:Array<Dynamic>):Node {
    var previousStack = GetCurrentStack();
    SetCurrentStack(this);
    for (node in nodes) {
      node.build(builder, 'void');
    }
    SetCurrentStack(previousStack);
    return outputNode != null ? outputNode.build(builder, params) : super.build(builder, params);
  }
}

@:keep
private function nodeProxy<T>(_func:T) {
  return _func;
}

@:keep
private function addNodeClass(name:String, nodeClass:Class<Dynamic>) {
  // TO DO: implement addNodeClass
}

private static function GetCurrentStack():StackNode {
  // TO DO: implement GetCurrentStack
  return null;
}

private static function SetCurrentStack(stack:StackNode):Void {
  // TO DO: implement SetCurrentStack
}