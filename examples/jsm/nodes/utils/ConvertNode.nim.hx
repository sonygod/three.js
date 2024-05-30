import Node, { addNodeClass } from '../core/Node.hx';

class ConvertNode extends Node {

  public var node:Node;
  public var convertTo:String;

  public function new(node:Node, convertTo:String) {

    super();

    this.node = node;
    this.convertTo = convertTo;

  }

  public function getNodeType(builder:NodeBuilder):String {

    var requestType = this.node.getNodeType(builder);

    var convertTo = null;

    for (overloadingType in this.convertTo.split('|')) {

      if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(overloadingType)) {

        convertTo = overloadingType;

      }

    }

    return convertTo;

  }

  public function serialize(data:Dynamic) {

    super.serialize(data);

    data.convertTo = this.convertTo;

  }

  public function deserialize(data:Dynamic) {

    super.deserialize(data);

    this.convertTo = data.convertTo;

  }

  public function generate(builder:NodeBuilder, output:Dynamic):Dynamic {

    var node = this.node;
    var type = this.getNodeType(builder);

    var snippet = node.build(builder, type);

    return builder.format(snippet, type, output);

  }

}

@:build(macro.NodeBuilder.registerClass())
class ConvertNodeMacro {
  static macro function build() {
    return macro 'ConvertNode';
  }
}