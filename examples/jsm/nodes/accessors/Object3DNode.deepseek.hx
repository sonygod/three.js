import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

import three.js.Vector3;

class Object3DNode extends Node {

	public var scope:String;
	public var object3d:Dynamic;
	public var _uniformNode:UniformNode;

	public function new(scope:String = Object3DNode.VIEW_MATRIX, object3d:Dynamic = null) {
		super();
		this.scope = scope;
		this.object3d = object3d;
		this.updateType = NodeUpdateType.OBJECT;
		this._uniformNode = new UniformNode(null);
	}

	public function getNodeType():String {
		var scope = this.scope;
		if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
			return 'mat4';
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			return 'mat3';
		} else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION || scope == Object3DNode.DIRECTION || scope == Object3DNode.SCALE) {
			return 'vec3';
		}
		return "";
	}

	public function update(frame:Dynamic) {
		var object = this.object3d;
		var uniformNode = this._uniformNode;
		var scope = this.scope;
		if (scope == Object3DNode.VIEW_MATRIX) {
			uniformNode.value = object.modelViewMatrix;
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			uniformNode.value = object.normalMatrix;
		} else if (scope == Object3DNode.WORLD_MATRIX) {
			uniformNode.value = object.matrixWorld;
		} else if (scope == Object3DNode.POSITION) {
			uniformNode.value = uniformNode.value ?? new Vector3();
			uniformNode.value.setFromMatrixPosition(object.matrixWorld);
		} else if (scope == Object3DNode.SCALE) {
			uniformNode.value = uniformNode.value ?? new Vector3();
			uniformNode.value.setFromMatrixScale(object.matrixWorld);
		} else if (scope == Object3DNode.DIRECTION) {
			uniformNode.value = uniformNode.value ?? new Vector3();
			object.getWorldDirection(uniformNode.value);
		} else if (scope == Object3DNode.VIEW_POSITION) {
			var camera = frame.camera;
			uniformNode.value = uniformNode.value ?? new Vector3();
			uniformNode.value.setFromMatrixPosition(object.matrixWorld);
			uniformNode.value.applyMatrix4(camera.matrixWorldInverse);
		}
	}

	public function generate(builder:Dynamic) {
		var scope = this.scope;
		if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
			this._uniformNode.nodeType = 'mat4';
		} else if (scope == Object3DNode.NORMAL_MATRIX) {
			this._uniformNode.nodeType = 'mat3';
		} else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION || scope == Object3DNode.DIRECTION || scope == Object3DNode.SCALE) {
			this._uniformNode.nodeType = 'vec3';
		}
		return this._uniformNode.build(builder);
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.scope = this.scope;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.scope = data.scope;
	}

	public static var VIEW_MATRIX:String = 'viewMatrix';
	public static var NORMAL_MATRIX:String = 'normalMatrix';
	public static var WORLD_MATRIX:String = 'worldMatrix';
	public static var POSITION:String = 'position';
	public static var SCALE:String = 'scale';
	public static var VIEW_POSITION:String = 'viewPosition';
	public static var DIRECTION:String = 'direction';
}

ShaderNode.nodeProxy(Object3DNode, Object3DNode.DIRECTION);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_MATRIX);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.NORMAL_MATRIX);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.WORLD_MATRIX);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.POSITION);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.SCALE);
ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_POSITION);

Node.addNodeClass('Object3DNode', Object3DNode);