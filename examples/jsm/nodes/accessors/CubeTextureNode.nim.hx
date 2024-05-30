import TextureNode from './TextureNode.hx';
import { reflectVector } from './ReflectVectorNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy, vec3 } from '../shadernode/ShaderNode.hx';
import { WebGPUCoordinateSystem } from 'three';

class CubeTextureNode extends TextureNode {

	public function new(value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null) {

		super(value, uvNode, levelNode);

		this.isCubeTextureNode = true;

	}

	public function getInputType() {

		return 'cubeTexture';

	}

	public function getDefaultUV() {

		return reflectVector;

	}

	public function setUpdateMatrix(updateMatrix:Dynamic) { } // Ignore .updateMatrix for CubeTextureNode

	public function setupUV(builder:Dynamic, uvNode:Dynamic) {

		const texture = this.value;

		if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || ! Std.is(texture.isRenderTargetTexture, true)) {

			return vec3(uvNode.x.negate(), uvNode.yz);

		} else {

			return uvNode;

		}

	}

	public function generateUV(builder:Dynamic, cubeUV:Dynamic) {

		return cubeUV.build(builder, 'vec3');

	}

}

@:expose
@:forward
class CubeTextureNodeProxy extends CubeTextureNode {}

@:expose
@:forward
class CubeTextureNodeClass extends CubeTextureNode {}

@:forward
class CubeTextureNodeElement extends CubeTextureNode {}

@:expose
@:forward
class CubeTextureNodeProxyElement extends CubeTextureNode {}

addNodeElement('cubeTexture', new CubeTextureNodeElement());
addNodeClass('CubeTextureNode', new CubeTextureNodeClass());

export default CubeTextureNode;
export var cubeTexture = new CubeTextureNodeProxy();