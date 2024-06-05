import TextureNode from "./TextureNode";
import ReflectVectorNode from "./ReflectVectorNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import WebGPUCoordinateSystem from "three";

class CubeTextureNode extends TextureNode {

  public var isCubeTextureNode:Bool = true;

  public function new(value:Dynamic, uvNode:ShaderNode = null, levelNode:ShaderNode = null) {
    super(value, uvNode, levelNode);
  }

  override public function getInputType(builder:Dynamic):String {
    return "cubeTexture";
  }

  override public function getDefaultUV():ShaderNode {
    return ReflectVectorNode.reflectVector;
  }

  override public function setUpdateMatrix(updateMatrix:Dynamic):Void {
    // Ignore .updateMatrix for CubeTextureNode
  }

  override public function setupUV(builder:Dynamic, uvNode:ShaderNode):ShaderNode {
    var texture = this.value;
    if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
      return ShaderNode.vec3(uvNode.x.negate(), uvNode.yz);
    } else {
      return uvNode;
    }
  }

  override public function generateUV(builder:Dynamic, cubeUV:Dynamic):ShaderNode {
    return cubeUV.build(builder, "vec3");
  }

}

export var cubeTexture:Dynamic = ShaderNode.nodeProxy(CubeTextureNode);

ShaderNode.addNodeElement("cubeTexture", cubeTexture);

Node.addNodeClass("CubeTextureNode", CubeTextureNode);