package three.js.nodes.core;

import three.js.nodes.Node;

class ContextNode extends Node {
  public var isContextNode:Bool = true;

  public var node:Node;
  public var context: Dynamic;

  public function new(node:Node, ?context:Dynamic) {
    super();
    this.node = node;
    this.context = context != null ? context : {};
  }

  public function getNodeType(builder:Builder):NodeType {
    return node.getNodeType(builder);
  }

  public function setup(builder:Builder):Node {
    var previousContext:Dynamic = builder.getContext();
    builder.setContext({ ...builder.context, ...context });
    var node = node.build(builder);
    builder.setContext(previousContext);
    return node;
  }

  public function generate(builder:Builder, output:Output):Snippet {
    var previousContext:Dynamic = builder.getContext();
    builder.setContext({ ...builder.context, ...context });
    var snippet:Snippet = node.build(builder, output);
    builder.setContext(previousContext);
    return snippet;
  }
}

typedef NodeType = String;
typedef Builder = { function getContext():Dynamic; function setContext(context:Dynamic):Void; };
typedef Output = Dynamic;
typedef Snippet = String;

extern class ShaderNode { static function nodeProxy(nodeClass:Class<ContextNode>):ContextNode->Dynamic; }

@:export var context:ContextNode->Dynamic = ShaderNode.nodeProxy(ContextNode);
@:export var label:(node:Node, name:String)->Dynamic = function(node, name) return context(node, { label: name });

@:export function addNodeElement(name:String, createElement:Void->Dynamic):Void { /* todo: implement */ }
@:export function addNodeClass(name:String, nodeClass:Class<ContextNode>):Void { /* todo: implement */ }

addNodeElement('context', context);
addNodeElement('label', label);
addNodeClass('ContextNode', ContextNode);