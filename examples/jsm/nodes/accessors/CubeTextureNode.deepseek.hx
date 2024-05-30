import TextureNode from './TextureNode.hx';
import ReflectVectorNode from './ReflectVectorNode.hx';
import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import WebGPUCoordinateSystem from 'three';

class CubeTextureNode extends TextureNode {

	public function new(value, uvNode = null, levelNode = null) {
		super(value, uvNode, levelNode);
		this.isCubeTextureNode = true;
	}

	public function getInputType(/*builder*/) {
		return 'cubeTexture';
	}

	public function getDefaultUV() {
		return ReflectVectorNode.reflectVector;
	}

	public function setUpdateMatrix(/*updateMatrix*/) { } // Ignore .updateMatrix for CubeTextureNode

	public function setupUV(builder, uvNode) {
		var texture = this.value;
		if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
			return ShaderNode.vec3(uvNode.x.negate(), uvNode.yz);
		} else {
			return uvNode;
		}
	}

	public function generateUV(builder, cubeUV) {
		return cubeUV.build(builder, 'vec3');
	}

}

static var cubeTexture = ShaderNode.nodeProxy(CubeTextureNode);

ShaderNode.addNodeElement('cubeTexture', cubeTexture);

Node.addNodeClass('CubeTextureNode', CubeTextureNode);