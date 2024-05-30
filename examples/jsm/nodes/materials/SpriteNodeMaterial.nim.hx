import NodeMaterial.addNodeMaterial;
import UniformNode.uniform;
import CameraNode.cameraProjectionMatrix;
import MaterialNode.materialRotation;
import ModelNode.{modelViewMatrix, modelWorldMatrix};
import PositionNode.positionLocal;
import ShaderNode.{float, vec2, vec3, vec4};

import SpriteMaterial from 'three';

class DefaultValues extends SpriteMaterial {}

class SpriteNodeMaterial extends NodeMaterial {

	public var isSpriteNodeMaterial:Bool = true;
	public var lights:Bool = false;
	public var normals:Bool = false;

	public var positionNode:Null<Dynamic> = null;
	public var rotationNode:Null<Dynamic> = null;
	public var scaleNode:Null<Dynamic> = null;

	public function new(parameters:Dynamic) {
		super();

		this.setDefaultValues(new DefaultValues());
		this.setValues(parameters);
	}

	public function setupPosition(object:Dynamic, context:Dynamic):Dynamic {
		// < VERTEX STAGE >

		var {positionNode, rotationNode, scaleNode} = this;

		var vertex = positionLocal;

		var mvPosition = modelViewMatrix.mul(vec3(positionNode ?? 0));

		var scale = vec2(modelWorldMatrix[0].xyz.length(), modelWorldMatrix[1].xyz.length());

		if (scaleNode != null) {
			scale = scale.mul(scaleNode);
		}

		var alignedPosition = vertex.xy;

		if (object.center && object.center.isVector2 == true) {
			alignedPosition = alignedPosition.sub(uniform(object.center).sub(0.5));
		}

		alignedPosition = alignedPosition.mul(scale);

		var rotation = float(rotationNode ?? materialRotation);

		var rotatedPosition = alignedPosition.rotate(rotation);

		mvPosition = vec4(mvPosition.xy.add(rotatedPosition), mvPosition.zw);

		var modelViewProjection = cameraProjectionMatrix.mul(mvPosition);

		context.vertex = vertex;

		return modelViewProjection;
	}

	public function copy(source:SpriteNodeMaterial):SpriteNodeMaterial {
		this.positionNode = source.positionNode;
		this.rotationNode = source.rotationNode;
		this.scaleNode = source.scaleNode;

		return super.copy(source);
	}
}

addNodeMaterial('SpriteNodeMaterial', SpriteNodeMaterial);