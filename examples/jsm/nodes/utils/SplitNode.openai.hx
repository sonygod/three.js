package three.js.nodes.utils;

import three.js.core.Node;
import three.js.core.constants.VectorComponents;

class SplitNode extends Node {
  public var node:Node;
  public var components:String;

  public function new(node:Node, ?components:String = 'x') {
    super();
    this.node = node;
    this.components = components;
    this.isSplitNode = true;
  }

  public function getVectorLength():Int {
    var vectorLength:Int = this.components.length;
    for (c in this.components) {
      vectorLength = Math.max(VectorComponents.indexOf(c) + 1, vectorLength);
    }
    return vectorLength;
  }

  public function getComponentType(builder:Dynamic):String {
    return builder.getComponentType(this.node.getNodeType(builder));
  }

  public function getNodeType(builder:Dynamic):String {
    return builder.getTypeFromLength(this.components.length, this.getComponentType(builder));
  }

  public function generate(builder:Dynamic, output:Dynamic):String {
    var node = this.node;
    var nodeTypeLength:Int = builder.getTypeLength(node.getNodeType(builder));
    var snippet:String = null;
    if (nodeTypeLength > 1) {
      var type:String = null;
      var componentsLength:Int = this.getVectorLength();
      if (componentsLength >= nodeTypeLength) {
        type = builder.getTypeFromLength(this.getVectorLength(), this.getComponentType(builder));
      }
      var nodeSnippet:String = node.build(builder, type);
      if (this.components.length == nodeTypeLength && this.components == VectorComponents.substr(0, this.components.length)) {
        snippet = builder.format(nodeSnippet, type, output);
      } else {
        snippet = builder.format('${nodeSnippet}.${this.components}', this.getNodeType(builder), output);
      }
    } else {
      snippet = node.build(builder, output);
    }
    return snippet;
  }

  public function serialize(data:Dynamic):Void {
    super.serialize(data);
    data.components = this.components;
  }

  public function deserialize(data:Dynamic):Void {
    super.deserialize(data);
    this.components = data.components;
  }
}

typedef VectorComponents = {
  var X:Int;
  var Y:Int;
  var Z:Int;
  var W:Int;
}

@:keep
class VectorComponents {
  public static inline var X:Int = 0;
  public static inline var Y:Int = 1;
  public static inline var Z:Int = 2;
  public static inline var W:Int = 3;
  public static inline function join(str:String):String {
    return str;
  }
  public static inline function indexOf(c:String):Int {
    return switch (c) {
      case 'x': X;
      case 'y': Y;
      case 'z': Z;
      case 'w': W;
      default: -1;
    }
  }
}