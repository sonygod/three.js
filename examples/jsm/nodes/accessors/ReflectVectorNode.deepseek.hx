import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.CameraNode.cameraViewMatrix;
import three.js.examples.jsm.nodes.accessors.NormalNode.transformedNormalView;
import three.js.examples.jsm.nodes.accessors.PositionNode.positionViewDirection;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeImmutable;

class ReflectVectorNode extends Node {

	public function new() {

		super('vec3');

	}

	public function getHash(builder:Dynamic):String {

		return 'reflectVector';

	}

	public function setup():Dynamic {

		var reflectView = positionViewDirection.negate().reflect(transformedNormalView);

		return reflectView.transformDirection(cameraViewMatrix);

	}

}

@:keep
static public var reflectVector = nodeImmutable(ReflectVectorNode);

addNodeClass('ReflectVectorNode', ReflectVectorNode);