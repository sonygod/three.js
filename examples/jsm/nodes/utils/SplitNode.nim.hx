import Node, { addNodeClass } from '../core/Node.js';
import { vectorComponents } from '../core/constants.js';

class SplitNode extends Node {

  public var node:Node;
  public var components:String;

  public function new(node:Node, components:String = 'x') {

    super();

    this.node = node;
    this.components = components;

    this.isSplitNode = true;

  }

  public function getVectorLength():Int {

    var vectorLength:Int = this.components.length;

    for (c in this.components) {

      vectorLength = Math.max(vectorComponents.indexOf(c) + 1, vectorLength);

    }

    return vectorLength;

  }

  public function getComponentType(builder:Dynamic):Dynamic {

    return builder.getComponentType(this.node.getNodeType(builder));

  }

  public function getNodeType(builder:Dynamic):Dynamic {

    return builder.getTypeFromLength(this.components.length, this.getComponentType(builder));

  }

  public function generate(builder:Dynamic, output:Dynamic):Dynamic {

    var node:Node = this.node;
    var nodeTypeLength:Int = builder.getTypeLength(node.getNodeType(builder));

    var snippet:Dynamic = null;

    if (nodeTypeLength > 1) {

      var type:Dynamic = null;

      var componentsLength:Int = this.getVectorLength();

      if (componentsLength >= nodeTypeLength) {

        // needed expand the input node

        type = builder.getTypeFromLength(this.getVectorLength(), this.getComponentType(builder));

      }

      var nodeSnippet:Dynamic = node.build(builder, type);

      if (this.components.length == nodeTypeLength && this.components == vectorComponents.slice(0, this.components.length)) {

        // unnecessary swizzle

        snippet = builder.format(nodeSnippet, type, output);

      } else {

        snippet = builder.format("${nodeSnippet}.${this.components}", this.getNodeType(builder), output);

      }

    } else {

      // ignore .components if .node returns float/integer

      snippet = node.build(builder, output);

    }

    return snippet;

  }

  public function serialize(data:Dynamic) {

    super.serialize(data);

    data.components = this.components;

  }

  public function deserialize(data:Dynamic) {

    super.deserialize(data);

    this.components = data.components;

  }

}

addNodeClass('SplitNode', SplitNode);