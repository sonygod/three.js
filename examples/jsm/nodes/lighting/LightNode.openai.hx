package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.accessors.Object3DNode;
import three.js.accessors.CameraNode;

class LightNode extends Node {
  public static inline var TARGET_DIRECTION = 'targetDirection';

  public var scope:String;
  public var light:Dynamic;

  public function new(?scope:String = TARGET_DIRECTION, ?light:Dynamic) {
    super();
    this.scope = scope;
    this.light = light;
  }

  public function setup():Null<Float32Array> {
    var output:Null<Float32Array> = null;
    if (scope == TARGET_DIRECTION) {
      output = CameraNode.cameraViewMatrix.transformDirection(Object3DNode.objectPosition(light).sub(Object3DNode.objectPosition(light.target)));
    }
    return output;
  }

  public function serialize(data:Dynamic) {
    super.serialize(data);
    data.scope = scope;
  }

  public function deserialize(data:Dynamic) {
    super.deserialize(data);
    scope = data.scope;
  }
}

// Export the class
@:nativeGen
class LightNodeProxy extends LightNode {
  public static var lightTargetDirection:LightNodeProxy = new LightNodeProxy(LightNode.TARGET_DIRECTION);
}

// Register the node class
Node.addNodeClass('LightNode', LightNode);