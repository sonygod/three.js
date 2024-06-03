import Object3DNode from './Object3DNode';
import Node from '../core/Node';
import NodeUpdateType from '../core/constants';
//import UniformGroupNode from '../core/UniformGroupNode';
import ShaderNode from '../shadernode/ShaderNode';

//var cameraGroup = UniformGroupNode.sharedUniformGroup("camera");

class CameraNode extends Object3DNode {

    public inline function new(scope:String = CameraNode.POSITION) {
        super(scope);
        this.updateType = NodeUpdateType.RENDER;
        //this._uniformNode.groupNode = cameraGroup;
    }

    public function getNodeType(builder:Node):String {
        var scope = this.scope;
        if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
            return 'mat4';
        } else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
            return 'float';
        }
        return super.getNodeType(builder);
    }

    public function update(frame:Node) {
        var camera = frame.camera;
        var uniformNode = this._uniformNode;
        var scope = this.scope;

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

    public function generate(builder:Node):Node {
        var scope = this.scope;
        if (scope == CameraNode.PROJECTION_MATRIX || scope == CameraNode.PROJECTION_MATRIX_INVERSE) {
            this._uniformNode.nodeType = 'mat4';
        } else if (scope == CameraNode.NEAR || scope == CameraNode.FAR || scope == CameraNode.LOG_DEPTH) {
            this._uniformNode.nodeType = 'float';
        }
        return super.generate(builder);
    }
}

class CameraNode {
    public static var PROJECTION_MATRIX:String = 'projectionMatrix';
    public static var PROJECTION_MATRIX_INVERSE:String = 'projectionMatrixInverse';
    public static var NEAR:String = 'near';
    public static var FAR:String = 'far';
    public static var LOG_DEPTH:String = 'logDepth';
}

var cameraProjectionMatrix = ShaderNode.nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX);
var cameraProjectionMatrixInverse = ShaderNode.nodeImmutable(CameraNode, CameraNode.PROJECTION_MATRIX_INVERSE);
var cameraNear = ShaderNode.nodeImmutable(CameraNode, CameraNode.NEAR);
var cameraFar = ShaderNode.nodeImmutable(CameraNode, CameraNode.FAR);
var cameraLogDepth = ShaderNode.nodeImmutable(CameraNode, CameraNode.LOG_DEPTH);
var cameraViewMatrix = ShaderNode.nodeImmutable(CameraNode, CameraNode.VIEW_MATRIX);
var cameraNormalMatrix = ShaderNode.nodeImmutable(CameraNode, CameraNode.NORMAL_MATRIX);
var cameraWorldMatrix = ShaderNode.nodeImmutable(CameraNode, CameraNode.WORLD_MATRIX);
var cameraPosition = ShaderNode.nodeImmutable(CameraNode, CameraNode.POSITION);

Node.addNodeClass("CameraNode", CameraNode);