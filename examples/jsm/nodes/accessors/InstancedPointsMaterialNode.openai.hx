package three.js.examples.jvm.nodes.accessors;

import three.js.examples.jvm.nodes.MaterialNode;

class InstancedPointsMaterialNode extends MaterialNode {
  static public var POINT_WIDTH:String = 'pointWidth';

  public function setup(builder:Dynamic) {
    return getFloat(this.scope);
  }

  static public var materialPointWidth:InstancedPointsMaterialNode = nodeImmutable(new InstancedPointsMaterialNode(), POINT_WIDTH);
}

// Register the node class
Node.registerNodeClass('InstancedPointsMaterialNode', InstancedPointsMaterialNode);