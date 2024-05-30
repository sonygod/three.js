import NodeMaterial;
import UniformNode;
import CameraNode;
import MaterialNode;
import ModelNode;
import PositionNode;
import ShaderNode;

import three.SpriteMaterial;

class SpriteNodeMaterial extends NodeMaterial {

	public function new(parameters:Dynamic) {

		super();

		this.isSpriteNodeMaterial = true;

		this.lights = false;
		this.normals = false;

		this.positionNode = null;
		this.rotationNode = null;
		this.scaleNode = null;

		this.setDefaultValues(new SpriteMaterial());

		this.setValues(parameters);

	}

	public function setupPosition(object:Dynamic, context:Dynamic):Dynamic {

		// < VERTEX STAGE >

		var positionNode = this.positionNode;
		var rotationNode = this.rotationNode;
		var scaleNode = this.scaleNode;

		var vertex = PositionNode.positionLocal;

		var mvPosition = ModelNode.modelViewMatrix.mul(ShaderNode.vec3(positionNode || 0));

		var scale = ShaderNode.vec2(ModelNode.modelWorldMatrix[0].xyz.length(), ModelNode.modelWorldMatrix[1].xyz.length());

		if (scaleNode !== null) {

			scale = scale.mul(scaleNode);

		}

		var alignedPosition = vertex.xy;

		if (object.center && object.center.isVector2 === true) {

			alignedPosition = alignedPosition.sub(UniformNode.uniform(object.center).sub(0.5));

		}

		alignedPosition = alignedPosition.mul(scale);

		var rotation = ShaderNode.float(rotationNode || MaterialNode.materialRotation);

		var rotatedPosition = alignedPosition.rotate(rotation);

		mvPosition = ShaderNode.vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);

		var modelViewProjection = CameraNode.cameraProjectionMatrix.mul(mvPosition);

		context.vertex = vertex;

		return modelViewProjection;

	}

	public function copy(source:Dynamic):Dynamic {

		this.positionNode = source.positionNode;
		this.rotationNode = source.rotationNode;
		this.scaleNode = source.scaleNode;

		return super.copy(source);

	}

}

NodeMaterial.addNodeMaterial('SpriteNodeMaterial', SpriteNodeMaterial);