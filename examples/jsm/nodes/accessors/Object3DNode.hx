package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.core.UniformNode;
import three.js.shadernode.ShaderNode;

import three.js.math.Vector3;

class Object3DNode extends Node {
    public static inline var VIEW_MATRIX:String = 'viewMatrix';
    public static inline var NORMAL_MATRIX:String = 'normalMatrix';
    public static inline var WORLD_MATRIX:String = 'worldMatrix';
    public static inline var POSITION:String = 'position';
    public static inline var SCALE:String = 'scale';
    public static inline var VIEW_POSITION:String = 'viewPosition';
    public static inline var DIRECTION:String = 'direction';

    public var scope:String;
    public var object3d:Dynamic;
    public var _uniformNode:UniformNode;

    public function new(scope:String = VIEW_MATRIX, object3d:Dynamic = null) {
        super();
        this.scope = scope;
        this.object3d = object3d;
        this.updateType = NodeUpdateType.OBJECT;
        this._uniformNode = new UniformNode(null);
    }

    public function getNodeType():String {
        switch (scope) {
            case VIEW_MATRIX, WORLD_MATRIX:
                return 'mat4';
            case NORMAL_MATRIX:
                return 'mat3';
            case POSITION, VIEW_POSITION, DIRECTION, SCALE:
                return 'vec3';
            default:
                return null;
        }
    }

    public function update(frame:Dynamic) {
        var object = object3d;
        var uniformNode = _uniformNode;
        switch (scope) {
            case VIEW_MATRIX:
                uniformNode.value = object.modelViewMatrix;
            case NORMAL_MATRIX:
                uniformNode.value = object.normalMatrix;
            case WORLD_MATRIX:
                uniformNode.value = object.matrixWorld;
            case POSITION:
                uniformNode.value = uniformNode.value != null ? uniformNode.value : new Vector3();
                uniformNode.value.setFromMatrixPosition(object.matrixWorld);
            case SCALE:
                uniformNode.value = uniformNode.value != null ? uniformNode.value : new Vector3();
                uniformNode.value.setFromMatrixScale(object.matrixWorld);
            case DIRECTION:
                uniformNode.value = uniformNode.value != null ? uniformNode.value : new Vector3();
                object.getWorldDirection(uniformNode.value);
            case VIEW_POSITION:
                var camera = frame.camera;
                uniformNode.value = uniformNode.value != null ? uniformNode.value : new Vector3();
                uniformNode.value.setFromMatrixPosition(object.matrixWorld);
                uniformNode.value.applyMatrix4(camera.matrixWorldInverse);
        }
    }

    public function generate(builder:Dynamic) {
        switch (scope) {
            case VIEW_MATRIX, WORLD_MATRIX:
                _uniformNode.nodeType = 'mat4';
            case NORMAL_MATRIX:
                _uniformNode.nodeType = 'mat3';
            case POSITION, VIEW_POSITION, DIRECTION, SCALE:
                _uniformNode.nodeType = 'vec3';
        }
        return _uniformNode.build(builder);
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = scope;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        scope = data.scope;
    }
}

// node proxy exports
var objectDirection = ShaderNode.nodeProxy(Object3DNode, Object3DNode.DIRECTION);
var objectViewMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_MATRIX);
var objectNormalMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.NORMAL_MATRIX);
var objectWorldMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.WORLD_MATRIX);
var objectPosition = ShaderNode.nodeProxy(Object3DNode, Object3DNode.POSITION);
var objectScale = ShaderNode.nodeProxy(Object3DNode, Object3DNode.SCALE);
var objectViewPosition = ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_POSITION);

Node.addNodeClass('Object3DNode', Object3DNode);