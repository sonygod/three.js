import AttributeNode from "../core/AttributeNode";
import VaryingNode from "../core/VaryingNode";
import PropertyNode from "../core/PropertyNode";
import CameraNode from "./CameraNode";
import ModelNode from "./ModelNode";
import ShaderNode from "../shadernode/ShaderNode";

class NormalGeometry extends AttributeNode {
  public static var instance:NormalGeometry = new NormalGeometry();
  public function new() {
    super("normal", "vec3", ShaderNode.vec3(0, 1, 0));
  }
}

class NormalLocal extends VaryingNode {
  public static var instance:NormalLocal = new NormalLocal();
  public function new() {
    super(NormalGeometry.instance);
    this.name = "normalLocal";
  }
}

class NormalView extends VaryingNode {
  public static var instance:NormalView = new NormalView();
  public function new() {
    super(ModelNode.modelNormalMatrix.mul(NormalLocal.instance));
    this.name = "normalView";
    this.normalize();
  }
}

class NormalWorld extends VaryingNode {
  public static var instance:NormalWorld = new NormalWorld();
  public function new() {
    super(NormalView.instance.transformDirection(CameraNode.cameraViewMatrix));
    this.name = "normalWorld";
    this.normalize();
  }
}

class TransformedNormalView extends PropertyNode {
  public static var instance:TransformedNormalView = new TransformedNormalView();
  public function new() {
    super("vec3", "transformedNormalView");
  }
}

class TransformedNormalWorld extends PropertyNode {
  public static var instance:TransformedNormalWorld = new TransformedNormalWorld();
  public function new() {
    super(TransformedNormalView.instance.transformDirection(CameraNode.cameraViewMatrix));
    this.normalize();
  }
}

class TransformedClearcoatNormalView extends PropertyNode {
  public static var instance:TransformedClearcoatNormalView = new TransformedClearcoatNormalView();
  public function new() {
    super("vec3", "transformedClearcoatNormalView");
  }
}

export {NormalGeometry, NormalLocal, NormalView, NormalWorld, TransformedNormalView, TransformedNormalWorld, TransformedClearcoatNormalView};