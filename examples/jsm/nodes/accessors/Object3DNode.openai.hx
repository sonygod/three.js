package three.js.nodes;

import three.js.core.Node;
import three.js.core.NodeUpdateType;
import three.js.nodes.UniformNode;
import three.js.shadernode.ShaderNode;

class Object3DNode extends Node {

    public static inline var VIEW_MATRIX:String = 'viewMatrix';
    public static inline var NORMAL_MATRIX:String = 'normalMatrix';
    public static inline var WORLD_MATRIX:String = 'worldMatrix';
    public static inline var POSITION:String = 'position';
    public static inline var SCALE:String = 'scale';
    public static inline var VIEW_POSITION:String = 'viewPosition';
    public static inline var DIRECTION:String = 'direction';

    public var scope:String;
    public var object3d:Object3D;
    private var _uniformNode:UniformNode;

    public function new(?scope:String = VIEW_MATRIX, ?object3d:Object3D) {
        super();
        this.scope = scope;
        this.object3d = object3d;
        this.updateType = NodeUpdateType.OBJECT;
        this._uniformNode = new UniformNode(null);
    }

    override public function getNodeType():String {
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

    override public function update(frame:Dynamic):Void {
        var object:Object3D = this.object3d;
        var uniformNode:UniformNode = this._uniformNode;
        var scope:String = this.scope;

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
                var camera:Camera = frame.camera;
                uniformNode.value = uniformNode.value != null ? uniformNode.value : new Vector3();
                uniformNode.value.setFromMatrixPosition(object.matrixWorld);
                uniformNode.value.applyMatrix4(camera.matrixWorldInverse);
        }
    }

    override public function generate(builder:Dynamic):Void {
        var scope:String = this.scope;

        switch (scope) {
            case VIEW_MATRIX, WORLD_MATRIX:
                _uniformNode.nodeType = 'mat4';
            case NORMAL_MATRIX:
                _uniformNode.nodeType = 'mat3';
            case POSITION, VIEW_POSITION, DIRECTION, SCALE:
                _uniformNode.nodeType = 'vec3';
        }

        _uniformNode.build(builder);
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.scope = this.scope;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.scope = data.scope;
    }
}

// helpers
var objectDirection:Dynamic = nodeProxy(Object3DNode, Object3DNode.DIRECTION);
var objectViewMatrix:Dynamic = nodeProxy(Object3DNode, Object3DNode.VIEW_MATRIX);
var objectNormalMatrix:Dynamic = nodeProxy(Object3DNode, Object3DNode.NORMAL_MATRIX);
var objectWorldMatrix:Dynamic = nodeProxy(Object3DNode, Object3DNode.WORLD_MATRIX);
var objectPosition:Dynamic = nodeProxy(Object3DNode, Object3DNode.POSITION);
var objectScale:Dynamic = nodeProxy(Object3DNode, Object3DNode.SCALE);
var objectViewPosition:Dynamic = nodeProxy(Object3DNode, Object3DNode.VIEW_POSITION);

three.js.nodes.addNodeClass('Object3DNode', Object3DNode);