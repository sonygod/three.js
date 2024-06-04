import Object3DNode from "./Object3DNode";
import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
//import {sharedUniformGroup} from "../core/UniformGroupNode";
import {nodeImmutable} from "../shadernode/ShaderNode";

//const cameraGroup = sharedUniformGroup( "camera" );

class CameraNode extends Object3DNode {
	static PROJECTION_MATRIX:String = "projectionMatrix";
	static PROJECTION_MATRIX_INVERSE:String = "projectionMatrixInverse";
	static NEAR:String = "near";
	static FAR:String = "far";
	static LOG_DEPTH:String = "logDepth";

	public constructor(scope:String = CameraNode.POSITION) {
		super(scope);
		this.updateType = NodeUpdateType.RENDER;
		//this._uniformNode.groupNode = cameraGroup;
	}

	public getNodeType(builder:Dynamic):String {
		const scope = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			return "mat4";
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			return "float";
		}
		return super.getNodeType(builder);
	}

	public update(frame:Dynamic):Void {
		const camera = frame.camera;
		const uniformNode = this._uniformNode;
		const scope = this.scope;
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
		const scope = this.scope;
		if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
			this._uniformNode.nodeType = "mat4";
		} else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
			this._uniformNode.nodeType = "float";
		}
		return super.generate(builder);
	}
}

export var cameraProjectionMatrix:Dynamic = nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX);
export var cameraProjectionMatrixInverse:Dynamic = nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX_INVERSE);
export var cameraNear:Dynamic = nodeImmutable(CameraNode, CameraNode.NEAR);
export var cameraFar:Dynamic = nodeImmutable(CameraNode, CameraNode.FAR);
export var cameraLogDepth:Dynamic = nodeImmutable(CameraNode, CameraNode.LOG_DEPTH);
export var cameraViewMatrix:Dynamic = nodeImmutable(CameraNode, CameraNode.VIEW_MATRIX);
export var cameraNormalMatrix:Dynamic = nodeImmutable(CameraNode, CameraNode.NORMAL_MATRIX);
export var cameraWorldMatrix:Dynamic = nodeImmutable(CameraNode, CameraNode.WORLD_MATRIX);
export var cameraPosition:Dynamic = nodeImmutable(CameraNode, CameraNode.POSITION);

Node.addNodeClass("CameraNode", CameraNode);

export default CameraNode;