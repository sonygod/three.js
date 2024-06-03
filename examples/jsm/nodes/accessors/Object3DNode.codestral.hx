import three.core.Node;
import three.core.NodeUpdateType;
import three.core.UniformNode;
import three.shadernode.ShaderNode;
import three.math.Vector3;

class Object3DNode extends Node {
    static var VIEW_MATRIX:String = 'viewMatrix';
    static var NORMAL_MATRIX:String = 'normalMatrix';
    static var WORLD_MATRIX:String = 'worldMatrix';
    static var POSITION:String = 'position';
    static var SCALE:String = 'scale';
    static var VIEW_POSITION:String = 'viewPosition';
    static var DIRECTION:String = 'direction';

    var scope:String;
    var object3d:Object;
    var _uniformNode:UniformNode;

    public function new(scope:String = Object3DNode.VIEW_MATRIX, object3d:Object = null) {
        super();
        this.scope = scope;
        this.object3d = object3d;
        this.updateType = NodeUpdateType.OBJECT;
        this._uniformNode = new UniformNode(null);
    }

    public function getNodeType():String {
        switch (this.scope) {
            case Object3DNode.WORLD_MATRIX:
            case Object3DNode.VIEW_MATRIX:
                return 'mat4';
            case Object3DNode.NORMAL_MATRIX:
                return 'mat3';
            case Object3DNode.POSITION:
            case Object3DNode.VIEW_POSITION:
            case Object3DNode.DIRECTION:
            case Object3DNode.SCALE:
                return 'vec3';
            default:
                return '';
        }
    }

    public function update(frame:Frame):Void {
        var object = this.object3d;
        var uniformNode = this._uniformNode;
        var scope = this.scope;

        switch (scope) {
            case Object3DNode.VIEW_MATRIX:
                uniformNode.value = object.modelViewMatrix;
                break;
            case Object3DNode.NORMAL_MATRIX:
                uniformNode.value = object.normalMatrix;
                break;
            case Object3DNode.WORLD_MATRIX:
                uniformNode.value = object.matrixWorld;
                break;
            case Object3DNode.POSITION:
                if (uniformNode.value == null) uniformNode.value = new Vector3();
                uniformNode.value.setFromMatrixPosition(object.matrixWorld);
                break;
            case Object3DNode.SCALE:
                if (uniformNode.value == null) uniformNode.value = new Vector3();
                uniformNode.value.setFromMatrixScale(object.matrixWorld);
                break;
            case Object3DNode.DIRECTION:
                if (uniformNode.value == null) uniformNode.value = new Vector3();
                object.getWorldDirection(uniformNode.value);
                break;
            case Object3DNode.VIEW_POSITION:
                var camera = frame.camera;
                if (uniformNode.value == null) uniformNode.value = new Vector3();
                uniformNode.value.setFromMatrixPosition(object.matrixWorld);
                uniformNode.value.applyMatrix4(camera.matrixWorldInverse);
                break;
        }
    }

    override public function generate(builder:Builder):String {
        var scope = this.scope;

        switch (scope) {
            case Object3DNode.WORLD_MATRIX:
            case Object3DNode.VIEW_MATRIX:
                this._uniformNode.nodeType = 'mat4';
                break;
            case Object3DNode.NORMAL_MATRIX:
                this._uniformNode.nodeType = 'mat3';
                break;
            case Object3DNode.POSITION:
            case Object3DNode.VIEW_POSITION:
            case Object3DNode.DIRECTION:
            case Object3DNode.SCALE:
                this._uniformNode.nodeType = 'vec3';
                break;
        }

        return this._uniformNode.build(builder);
    }

    override public function serialize(data:Object):Void {
        super.serialize(data);
        data.scope = this.scope;
    }

    override public function deserialize(data:Object):Void {
        super.deserialize(data);
        this.scope = data.scope;
    }
}

var objectDirection = ShaderNode.nodeProxy(Object3DNode, Object3DNode.DIRECTION);
var objectViewMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_MATRIX);
var objectNormalMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.NORMAL_MATRIX);
var objectWorldMatrix = ShaderNode.nodeProxy(Object3DNode, Object3DNode.WORLD_MATRIX);
var objectPosition = ShaderNode.nodeProxy(Object3DNode, Object3DNode.POSITION);
var objectScale = ShaderNode.nodeProxy(Object3DNode, Object3DNode.SCALE);
var objectViewPosition = ShaderNode.nodeProxy(Object3DNode, Object3DNode.VIEW_POSITION);

Node.addNodeClass('Object3DNode', Object3DNode);