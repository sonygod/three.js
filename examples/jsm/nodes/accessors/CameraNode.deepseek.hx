import Object3DNode from './Object3DNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { nodeImmutable } from '../shadernode/ShaderNode.hx';

class CameraNode extends Object3DNode {

	public function new(scope:String = CameraNode.POSITION) {
		super(scope);
		this.updateType = NodeUpdateType.RENDER;
	}

	public function getNodeType(builder:Dynamic):String {
		var scope = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			return 'mat4';
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			return 'float';
		}
		return super.getNodeType(builder);
	}

	public function update(frame:Dynamic):Void {
		var camera = frame.camera;
		var uniformNode = this._uniformNode;
		var scope = this.scope;
		if (scope == CameraNode.VIEW_MATRIX) {
			uniformNode.value = camera.matrixWorldInverse;
		} else if (scope == CameraNode.PROJECTION_MATRIX) {
			uniformNode.value = camera.projectionMatrix;
		} else if (scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			uniformNode.value = camera.projectionMatrixInverse;
		} else if (scope == CameraNode.NEAR) {
			uniformNode.value = camera.near;
		} else if (scope == CameraNode.FAR) {
			uniformNode.value = camera.far;
		} else if (scope == CameraNode.LOG_DEPTH) {
			uniformNode.value = 2.0 / (Math.log(camera.far + 1.0) / Math.LN2);
		} else {
			this.object3d = camera;
			super.update(frame);
		}
	}

	public function generate(builder:Dynamic):Dynamic {
		var scope = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			this._uniformNode.nodeType = 'mat4';
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			this._uniformNode.nodeType = 'float';
		}
		return super.generate(builder);
	}

	public static var PROJECTION_MATRIX:String = 'projectionMatrix';
	public static var PROJECTION_MATRIX_INVERSE:String = 'projectionMatrixInverse';
	public static var NEAR:String = 'near';
	public static var FAR:String = 'far';
	public static var LOG_DEPTH:String = 'logDepth';
}

var cameraProjectionMatrix = nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX);
var cameraProjectionMatrixInverse = nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX_INVERSE);
var cameraNear = nodeImmutable(CameraNode, CameraNode.NEAR);
var cameraFar = nodeImmutable(CameraNode, CameraNode.FAR);
var cameraLogDepth = nodeImmutable(CameraNode, CameraNode.LOG_DEPTH);
var cameraViewMatrix = nodeImmutable(CameraNode, CameraNode.VIEW_MATRIX);
var cameraNormalMatrix = nodeImmutable(CameraNode, CameraNode.NORMAL_MATRIX);
var cameraWorldMatrix = nodeImmutable(CameraNode, CameraNode.WORLD_MATRIX);
var cameraPosition = nodeImmutable(CameraNode, CameraNode.POSITION);

addNodeClass('CameraNode', CameraNode);