package three.js.nodes.accessors;

import three.js.nodes.Object3DNode;
import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class CameraNode extends Object3DNode {
  public static inline var PROJECTION_MATRIX:String = 'projectionMatrix';
  public static inline var PROJECTION_MATRIX_INVERSE:String = 'projectionMatrixInverse';
  public static inline var NEAR:String = 'near';
  public static inline var FAR:String = 'far';
  public static inline var LOG_DEPTH:String = 'logDepth';

  public function new(scope:String = POSITION) {
    super(scope);
    updateType = NodeUpdateType.RENDER;
  }

  override public function getNodeType(builder:Node):String {
    var scope:String = this.scope;
    if (scope == PROJECTION_MATRIX || scope == PROJECTION_MATRIX_INVERSE) {
      return 'mat4';
    } else if (scope == NEAR || scope == FAR || scope == LOG_DEPTH) {
      return 'float';
    }
    return super.getNodeType(builder);
  }

  override public function update(frame:Dynamic):Void {
    var camera:Dynamic = frame.camera;
    var uniformNode:Node = this._uniformNode;
    var scope:String = this.scope;

    //cameraGroup.needsUpdate = true;

    if (scope == VIEW_MATRIX) {
      uniformNode.value = camera.matrixWorldInverse;
    } else if (scope == PROJECTION_MATRIX) {
      uniformNode.value = camera.projectionMatrix;
    } else if (scope == PROJECTION_MATRIX_INVERSE) {
      uniformNode.value = camera.projectionMatrixInverse;
    } else if (scope == NEAR) {
      uniformNode.value = camera.near;
    } else if (scope == FAR) {
      uniformNode.value = camera.far;
    } else if (scope == LOG_DEPTH) {
      uniformNode.value = 2.0 / (Math.log(camera.far + 1.0) / Math.LN2);
    } else {
      this.object3d = camera;
      super.update(frame);
    }
  }

  override public function generate(builder:Node):Void {
    var scope:String = this.scope;

    if (scope == PROJECTION_MATRIX || scope == PROJECTION_MATRIX_INVERSE) {
      this._uniformNode.nodeType = 'mat4';
    } else if (scope == NEAR || scope == FAR || scope == LOG_DEPTH) {
      this._uniformNode.nodeType = 'float';
    }

    super.generate(builder);
  }

  public static var cameraProjectionMatrix:Node = nodeImmutable(new CameraNode(PROJECTION_MATRIX));
  public static var cameraProjectionMatrixInverse:Node = nodeImmutable(new CameraNode(PROJECTION_MATRIX_INVERSE));
  public static var cameraNear:Node = nodeImmutable(new CameraNode(NEAR));
  public static var cameraFar:Node = nodeImmutable(new CameraNode(FAR));
  public static var cameraLogDepth:Node = nodeImmutable(new CameraNode(LOG_DEPTH));
  public static var cameraViewMatrix:Node = nodeImmutable(new CameraNode(VIEW_MATRIX));
  public static var cameraNormalMatrix:Node = nodeImmutable(new CameraNode(NORMAL_MATRIX));
  public static var cameraWorldMatrix:Node = nodeImmutable(new CameraNode(WORLD_MATRIX));
  public static var cameraPosition:Node = nodeImmutable(new CameraNode(POSITION));
}

Node.addNodeClass('CameraNode', CameraNode);