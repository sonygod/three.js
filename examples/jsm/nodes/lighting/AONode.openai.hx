package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;

class AONode extends LightingNode {
  public var aoNode:Dynamic;

  public function new(?aoNode:Dynamic) {
    super();
    this.aoNode = aoNode;
  }

  public function setup(builder:Dynamic) {
    var aoIntensity = 1.0;
    var aoNode = this.aoNode.x.sub(1.0).mul(aoIntensity).add(1.0);
    builder.context.ambientOcclusion.mulAssign(aoNode);
  }
}

nodejs.three.addNodeClass('AONode', AONode);