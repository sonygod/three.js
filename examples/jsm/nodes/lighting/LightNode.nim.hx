import Node, { addNodeClass } from '../core/Node.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';
import { objectPosition } from '../accessors/Object3DNode.js';
import { cameraViewMatrix } from '../accessors/CameraNode.js';

class LightNode extends Node {

	public var scope:String;
	public var light:Null<Dynamic>;

	public function new(scope:String = LightNode.TARGET_DIRECTION, light:Null<Dynamic> = null) {
		super();

		this.scope = scope;
		this.light = light;
	}

	public function setup():Null<Dynamic> {
		var output:Null<Dynamic> = null;

		if (this.scope == LightNode.TARGET_DIRECTION) {
			output = cameraViewMatrix.transformDirection(objectPosition(this.light).sub(objectPosition(this.light.target)));
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

	static public var TARGET_DIRECTION:String = 'targetDirection';
}

export default LightNode;

export var lightTargetDirection = nodeProxy(LightNode, LightNode.TARGET_DIRECTION);

addNodeClass('LightNode', LightNode);