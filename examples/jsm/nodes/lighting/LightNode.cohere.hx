import Node from '../core/Node';
import { nodeProxy } from '../shadernode/ShaderNode';
import { objectPosition } from '../accessors/Object3DNode';
import { cameraViewMatrix } from '../accessors/CameraNode';

class LightNode extends Node {
	public var scope:String = LightNode.TARGET_DIRECTION;
	public var light:Dynamic;

	public function new(scope:String = LightNode.TARGET_DIRECTION, light:Dynamic = null) {
		super();
		this.scope = scope;
		this.light = light;
	}

	override function setup():Dynamic {
		if (scope == LightNode.TARGET_DIRECTION) {
			return cameraViewMatrix.transformDirection(objectPosition(light).sub(objectPosition(light.target)));
		}
		return null;
	}

	override function serialize(data:Dynamic) {
		super.serialize(data);
		data.scope = scope;
	}

	override function deserialize(data:Dynamic) {
		super.deserialize(data);
		scope = data.scope;
	}
}

class LightNodeStatics {
	static public var TARGET_DIRECTION:String = 'targetDirection';
}

static extension LightNodeStaticsExtension on Node {
	static public var LightNode:LightNodeStatics = { TARGET_DIRECTION: 'targetDirection' };
}

@:nodeProxy(LightNode, LightNode.TARGET_DIRECTION)
public function lightTargetDirection():Void {}

@:addNodeClass('LightNode', LightNode)
public function addLightNodeClass():Void {}