import Object3DNode from "./Object3DNode";
import Node from "../core/Node";
import { NodeUpdateType } from "../core/constants";

//const cameraGroup = sharedUniformGroup( 'camera' );

class CameraNode extends Object3DNode {

	public static PROJECTION_MATRIX:String = "projectionMatrix";
	public static PROJECTION_MATRIX_INVERSE:String = "projectionMatrixInverse";
	public static NEAR:String = "near";
	public static FAR:String = "far";
	public static LOG_DEPTH:String = "logDepth";

	public constructor(scope:String = CameraNode.POSITION) {
		super(scope);
		this.updateType = NodeUpdateType.RENDER;
		//this._uniformNode.groupNode = cameraGroup;
	}

	public getNodeType(builder:Dynamic):String {
		const scope:String = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			return "mat4";
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			return "float";
		}
		return super.getNodeType(builder);
	}

	public update(frame:Dynamic) {
		const camera:Dynamic = frame.camera;
		const uniformNode:Dynamic = this._uniformNode;
		const scope:String = this.scope;
		//cameraGroup.needsUpdate = true;
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

	public generate(builder:Dynamic):Dynamic {
		const scope:String = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			this._uniformNode.nodeType = "mat4";
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			this._uniformNode.nodeType = "float";
		}
		return super.generate(builder);
	}

}

// Note: The `nodeImmutable` function is not included in this conversion.
// You'll need to implement it based on your Haxe setup and the functionality
// of the original `nodeImmutable` function.

export var cameraProjectionMatrix:Dynamic = Node.immutable(CameraNode, CameraNode.PROJECTION_MATRIX);
export var cameraProjectionMatrixInverse:Dynamic = Node.immutable(CameraNode, CameraNode.PROJECTION_MATRIX_INVERSE);
export var cameraNear:Dynamic = Node.immutable(CameraNode, CameraNode.NEAR);
export var cameraFar:Dynamic = Node.immutable(CameraNode, CameraNode.FAR);
export var cameraLogDepth:Dynamic = Node.immutable(CameraNode, CameraNode.LOG_DEPTH);
export var cameraViewMatrix:Dynamic = Node.immutable(CameraNode, CameraNode.VIEW_MATRIX);
export var cameraNormalMatrix:Dynamic = Node.immutable(CameraNode, CameraNode.NORMAL_MATRIX);
export var cameraWorldMatrix:Dynamic = Node.immutable(CameraNode, CameraNode.WORLD_MATRIX);
export var cameraPosition:Dynamic = Node.immutable(CameraNode, CameraNode.POSITION);

Node.addClass("CameraNode", CameraNode);

export default CameraNode;