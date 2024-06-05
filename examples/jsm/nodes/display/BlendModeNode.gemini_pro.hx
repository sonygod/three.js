import TempNode from "../core/TempNode";
import MathNode from "../math/MathNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class BurnNode extends TempNode {
  public base: ShaderNode.ShaderNode;
  public blend: ShaderNode.ShaderNode;
  public function new(base: ShaderNode.ShaderNode, blend: ShaderNode.ShaderNode) {
    super();
    this.base = base;
    this.blend = blend;
  }
  override function generate(builder: ShaderNode.Builder, output: ShaderNode.Output) : Void {
    builder.addCode('${output} = vec3(blend.x < ${MathNode.EPSILON} ? blend.x : (1.0 - base.x) / blend.x * (1.0 - 1.0), blend.y < ${MathNode.EPSILON} ? blend.y : (1.0 - base.y) / blend.y * (1.0 - 1.0), blend.z < ${MathNode.EPSILON} ? blend.z : (1.0 - base.z) / blend.z * (1.0 - 1.0));');
  }
}

class DodgeNode extends TempNode {
  public base: ShaderNode.ShaderNode;
  public blend: ShaderNode.ShaderNode;
  public function new(base: ShaderNode.ShaderNode, blend: ShaderNode.ShaderNode) {
    super();
    this.base = base;
    this.blend = blend;
  }
  override function generate(builder: ShaderNode.Builder, output: ShaderNode.Output) : Void {
    builder.addCode('${output} = vec3(blend.x == 1.0 ? blend.x : base.x / (1.0 - blend.x) * (1.0 - 0.0), blend.y == 1.0 ? blend.y : base.y / (1.0 - blend.y) * (1.0 - 0.0), blend.z == 1.0 ? blend.z : base.z / (1.0 - blend.z) * (1.0 - 0.0));');
  }
}

class ScreenNode extends TempNode {
  public base: ShaderNode.ShaderNode;
  public blend: ShaderNode.ShaderNode;
  public function new(base: ShaderNode.ShaderNode, blend: ShaderNode.ShaderNode) {
    super();
    this.base = base;
    this.blend = blend;
  }
  override function generate(builder: ShaderNode.Builder, output: ShaderNode.Output) : Void {
    builder.addCode('${output} = vec3((1.0 - base.x) * (1.0 - blend.x) * (1.0 - 0.0), (1.0 - base.y) * (1.0 - blend.y) * (1.0 - 0.0), (1.0 - base.z) * (1.0 - blend.z) * (1.0 - 0.0));');
  }
}

class OverlayNode extends TempNode {
  public base: ShaderNode.ShaderNode;
  public blend: ShaderNode.ShaderNode;
  public function new(base: ShaderNode.ShaderNode, blend: ShaderNode.ShaderNode) {
    super();
    this.base = base;
    this.blend = blend;
  }
  override function generate(builder: ShaderNode.Builder, output: ShaderNode.Output) : Void {
    builder.addCode('${output} = vec3(base.x < 0.5 ? base.x * blend.x * 2.0 : (1.0 - base.x) * (1.0 - blend.x) * (1.0 - 0.0), base.y < 0.5 ? base.y * blend.y * 2.0 : (1.0 - base.y) * (1.0 - blend.y) * (1.0 - 0.0), base.z < 0.5 ? base.z * blend.z * 2.0 : (1.0 - base.z) * (1.0 - blend.z) * (1.0 - 0.0));');
  }
}

class BlendModeNode extends TempNode {
  public blendMode: String;
  public baseNode: ShaderNode.ShaderNode;
  public blendNode: ShaderNode.ShaderNode;

  public static var BURN: String = "burn";
  public static var DODGE: String = "dodge";
  public static var SCREEN: String = "screen";
  public static var OVERLAY: String = "overlay";

  public function new(blendMode: String, baseNode: ShaderNode.ShaderNode, blendNode: ShaderNode.ShaderNode) {
    super();
    this.blendMode = blendMode;
    this.baseNode = baseNode;
    this.blendNode = blendNode;
  }

  override function setup() : ShaderNode.ShaderNode {
    switch (blendMode) {
      case BURN:
        return new BurnNode(baseNode, blendNode);
      case DODGE:
        return new DodgeNode(baseNode, blendNode);
      case SCREEN:
        return new ScreenNode(baseNode, blendNode);
      case OVERLAY:
        return new OverlayNode(baseNode, blendNode);
      default:
        throw "Unknown blend mode: " + blendMode;
    }
  }
}

var burn = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.BURN);
var dodge = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.DODGE);
var overlay = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.OVERLAY);
var screen = ShaderNode.nodeProxy(BlendModeNode, BlendModeNode.SCREEN);

ShaderNode.addNodeElement("burn", burn);
ShaderNode.addNodeElement("dodge", dodge);
ShaderNode.addNodeElement("overlay", overlay);
ShaderNode.addNodeElement("screen", screen);

ShaderNode.addNodeClass("BlendModeNode", BlendModeNode);