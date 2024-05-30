import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.accessors.Object3DNode;
import three.js.examples.jsm.nodes.accessors.CameraNode;

class LightNode extends Node {

	public static var TARGET_DIRECTION:String = 'targetDirection';

	public var scope:String;
	public var light:Dynamic;

	public function new(scope:String = TARGET_DIRECTION, light:Dynamic = null) {
		super();
		this.scope = scope;
		this.light = light;
	}

	public function setup():Dynamic {
		var output:Dynamic = null;
		if (this.scope == TARGET_DIRECTION) {
			output = CameraNode.cameraViewMatrix.transformDirection(Object3DNode.objectPosition(this.light).sub(Object3DNode.objectPosition(this.light.target)));
		}
		return output;
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.scope = this.scope;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.scope = data.scope;
	}

}

public static function lightTargetDirection(light:Dynamic):Dynamic {
	return ShaderNode.nodeProxy(LightNode, LightNode.TARGET_DIRECTION);
}

Node.addNodeClass('LightNode', LightNode);