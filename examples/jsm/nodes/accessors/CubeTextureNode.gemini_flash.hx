import TextureNode from "./TextureNode";
import ReflectVectorNode from "./ReflectVectorNode";
import {addNodeClass, addNodeElement, nodeProxy, vec3} from "../shadernode/ShaderNode";
import {WebGPUCoordinateSystem} from "three";

class CubeTextureNode extends TextureNode {

	public var isCubeTextureNode:Bool = true;

	public function new(value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null) {
		super(value, uvNode, levelNode);
	}

	public function getInputType(?builder:Dynamic):String {
		return "cubeTexture";
	}

	public function getDefaultUV():Dynamic {
		return ReflectVectorNode;
	}

	public function setUpdateMatrix(?updateMatrix:Dynamic):Void {
		// Ignore .updateMatrix for CubeTextureNode
	}

	public function setupUV(builder:Dynamic, uvNode:Dynamic):Dynamic {
		var texture = this.value;

		if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
			return vec3(uvNode.x.negate(), uvNode.yz);
		} else {
			return uvNode;
		}
	}

	public function generateUV(builder:Dynamic, cubeUV:Dynamic):Dynamic {
		return cubeUV.build(builder, "vec3");
	}
}

export var CubeTextureNode = CubeTextureNode;
export var cubeTexture = nodeProxy(CubeTextureNode);

addNodeElement("cubeTexture", cubeTexture);
addNodeClass("CubeTextureNode", CubeTextureNode);