import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
import UniformNode from "../core/UniformNode";
import {nodeProxy} from "../shadernode/ShaderNode";

import {Vector3} from "three";

class Object3DNode extends Node {

	public static VIEW_MATRIX:String = "viewMatrix";
	public static NORMAL_MATRIX:String = "normalMatrix";
	public static WORLD_MATRIX:String = "worldMatrix";
	public static POSITION:String = "position";
	public static SCALE:String = "scale";
	public static VIEW_POSITION:String = "viewPosition";
	public static DIRECTION:String = "direction";

	public scope:String;
	public object3d:Dynamic;
	private _uniformNode:UniformNode;

	public function new(scope:String = Object3DNode.VIEW_MATRIX, object3d:Dynamic = null) {
		super();

		this.scope = scope;
		this.object3d = object3d;

		this.updateType = NodeUpdateType.OBJECT;

		this._uniformNode = new UniformNode(null);
	}

	public function getNodeType():String {
		const scope = this.scope;

		if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
			return "mat4";
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			return "mat3";
		} else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION || scope == Object3DNode.DIRECTION || scope == Object3DNode.SCALE) {
			return "vec3";
		}

		return null;
	}

	public function update(frame:Dynamic):Void {
		const object = this.object3d;
		const uniformNode = this._uniformNode;
		const scope = this.scope;

		if (scope == Object3DNode.VIEW_MATRIX) {
			uniformNode.value = object.modelViewMatrix;
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			uniformNode.value = object.normalMatrix;
		} else if (scope == Object3DNode.WORLD_MATRIX) {
			uniformNode.value = object.matrixWorld;
		} else if (scope == Object3DNode.POSITION) {
			uniformNode.value = cast uniformNode.value;
			if (uniformNode.value == null) {
				uniformNode.value = new Vector3();
			}
			uniformNode.value.setFromMatrixPosition(object.matrixWorld);
		} else if (scope == Object3DNode.SCALE) {
			uniformNode.value = cast uniformNode.value;
			if (uniformNode.value == null) {
				uniformNode.value = new Vector3();
			}
			uniformNode.value.setFromMatrixScale(object.matrixWorld);
		} else if (scope == Object3DNode.DIRECTION) {
			uniformNode.value = cast uniformNode.value;
			if (uniformNode.value == null) {
				uniformNode.value = new Vector3();
			}
			object.getWorldDirection(uniformNode.value);
		} else if (scope == Object3DNode.VIEW_POSITION) {
			const camera = frame.camera;
			uniformNode.value = cast uniformNode.value;
			if (uniformNode.value == null) {
				uniformNode.value = new Vector3();
			}
			uniformNode.value.setFromMatrixPosition(object.matrixWorld);
			uniformNode.value.applyMatrix4(camera.matrixWorldInverse);
		}
	}

	public function generate(builder:Dynamic):Dynamic {
		const scope = this.scope;

		if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
			this._uniformNode.nodeType = "mat4";
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			this._uniformNode.nodeType = "mat3";
		} else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION || scope == Object3DNode.DIRECTION || scope == Object3DNode.SCALE) {
			this._uniformNode.nodeType = "vec3";
		}

		return this._uniformNode.build(builder);
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

export var objectDirection = nodeProxy(Object3DNode, Object3DNode.DIRECTION);
export var objectViewMatrix = nodeProxy(Object3DNode, Object3DNode.VIEW_MATRIX);
export var objectNormalMatrix = nodeProxy(Object3DNode, Object3DNode.NORMAL_MATRIX);
export var objectWorldMatrix = nodeProxy(Object3DNode, Object3DNode.WORLD_MATRIX);
export var objectPosition = nodeProxy(Object3DNode, Object3DNode.POSITION);
export var objectScale = nodeProxy(Object3DNode, Object3DNode.SCALE);
export var objectViewPosition = nodeProxy(Object3DNode, Object3DNode.VIEW_POSITION);

addNodeClass("Object3DNode", Object3DNode);