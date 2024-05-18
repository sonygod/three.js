Here is the converted Haxe code:
```
package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.Object3DNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
//import three.js.examples.jsm.nodes.core.UniformGroupNode;

class CameraNode extends Object3DNode {
    public static inline var PROJECTION_MATRIX:String = 'projectionMatrix';
    public static inline var PROJECTION_MATRIX_INVERSE:String = 'projectionMatrixInverse';
    public static inline var NEAR:String = 'near';
    public static inline var FAR:String = 'far';
    public static inline var LOG_DEPTH:String = 'logDepth';

    public function new(scope:String = POSITION) {
        super(scope);
        updateType = NodeUpdateType.RENDER;
        //_uniformNode.groupNode = cameraGroup;
    }

    override public function getNodeType(builder:Dynamic):String {
        var scope:String = this.scope;
        if (scope == PROJECTION_MATRIX || scope == PROJECTION_MATRIX_INVERSE) {
            return 'mat4';
        } else if (scope == NEAR || scope == FAR || scope == LOG_DEPTH) {
            return 'float';
        }
        return super.getNodeType(builder);
    }

    override public function update(frame:Dynamic) {
        var camera:Dynamic = frame.camera;
        var uniformNode:Dynamic = _uniformNode;
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
            object3d = camera;
            super.update(frame);
        }
    }

    override public function generate(builder:Dynamic):Void {
        var scope:String = this.scope;

        if (scope == PROJECTION_MATRIX || scope == PROJECTION_MATRIX_INVERSE) {
            _uniformNode.nodeType = 'mat4';
        } else if (scope == NEAR || scope == FAR || scope == LOG_DEPTH) {
            _uniformNode.nodeType = 'float';
        }

        super.generate(builder);
    }
}

// Register the node class
Node.registerNodeClass('CameraNode', CameraNode);

// Export immutable nodes
var cameraProjectionMatrix:CameraNode = nodeImmutable(new CameraNode(CameraNode.PROJECTION_MATRIX));
var cameraProjectionMatrixInverse:CameraNode = nodeImmutable(new CameraNode(CameraNode.PROJECTION_MATRIX_INVERSE));
var cameraNear:CameraNode = nodeImmutable(new CameraNode(CameraNode.NEAR));
var cameraFar:CameraNode = nodeImmutable(new CameraNode(CameraNode.FAR));
var cameraLogDepth:CameraNode = nodeImmutable(new CameraNode(CameraNode.LOG_DEPTH));
var cameraViewMatrix:CameraNode = nodeImmutable(new CameraNode(VIEW_MATRIX));
var cameraNormalMatrix:CameraNode = nodeImmutable(new CameraNode(NORMAL_MATRIX));
var cameraWorldMatrix:CameraNode = nodeImmutable(new CameraNode(WORLD_MATRIX));
var cameraPosition:CameraNode = nodeImmutable(new CameraNode(POSITION));
```
Note that I've kept the same file structure and naming conventions as the original JavaScript code. I've also assumed that the `nodeImmutable` function is defined elsewhere in the codebase, so I haven't included its implementation here. If you need help with that as well, let me know!