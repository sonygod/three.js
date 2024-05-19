package three.js.examples.jsm.nodes.code;

import three.core.Node;
import three.core.NodeUtils;
import three.shadernode.ShaderNode;
import three.event.EventDispatcher;

class ScriptableValueNode extends Node {

    var _value:Dynamic;
    var _cache:Null<String>;

    public var inputType:Null<String>;
    public var outputType:Null<String>;

    var events:EventDispatcher;

    public var isScriptableValueNode:Bool = true;

    public function new(?value:Dynamic) {
        super();
        this._value = value;
        this._cache = null;

        this.inputType = null;
        this.outputType = null;

        this.events = new EventDispatcher();
    }

    public function get_isScriptableOutputNode():Bool {
        return this.outputType != null;
    }

    public function set_value(val:Dynamic):Void {
        if (this._value === val) return;
        if (this._cache != null && this.inputType == 'URL' && Std.isOfType(this._value, ArrayBuffer)) {
            #if js
            untyped URL.revokeObjectURL(this._cache);
            #end
            this._cache = null;
        }
        this._value = val;
        this.events.dispatchEvent({ type: 'change' });
        this.refresh();
    }

    public function get_value():Dynamic {
        return this._value;
    }

    public function refresh():Void {
        this.events.dispatchEvent({ type: 'refresh' });
    }

    public function getValue():Dynamic {
        var value:Dynamic = this._value;
        if (value != null && this._cache == null && this.inputType == 'URL' && Std.isOfType(value, ArrayBuffer)) {
            #if js
            this._cache = untyped URL.createObjectURL(new Blob([value]));
            #end
        } else if (value != null && value != null && value != undefined && (
            (this.inputType == 'URL' || this.inputType == 'String' && Std.isOfType(value, String)) ||
            (this.inputType == 'Number' && Std.isOfType(value, Float)) ||
            (this.inputType == 'Vector2' && Std.isOfType(value, Vector2)) ||
            (this.inputType == 'Vector3' && Std.isOfType(value, Vector3)) ||
            (this.inputType == 'Vector4' && Std.isOfType(value, Vector4)) ||
            (this.inputType == 'Color' && Std.isOfType(value, Color)) ||
            (this.inputType == 'Matrix3' && Std.isOfType(value, Matrix3)) ||
            (this.inputType == 'Matrix4' && Std.isOfType(value, Matrix4))
        )) {
            return value;
        }
        return this._cache != null ? this._cache : value;
    }

    public function getNodeType(builder:Dynamic):String {
        return this._value != null && Std.isOfType(this._value, Node) ? this._value.getNodeType(builder) : 'float';
    }

    public function setup():Dynamic {
        return this._value != null && Std.isOfType(this._value, Node) ? this._value : float();
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        if (this._value != null) {
            if (this.inputType == 'ArrayBuffer') {
                data.value = NodeUtils.arrayBufferToBase64(this._value);
            } else {
                data.value = this._value != null ? this._value.toJSON(data.meta).uuid : null;
            }
        } else {
            data.value = null;
        }
        data.inputType = this.inputType;
        data.outputType = this.outputType;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        var value:Dynamic = null;
        if (data.value != null) {
            if (data.inputType == 'ArrayBuffer') {
                value = NodeUtils.base64ToArrayBuffer(data.value);
            } else if (data.inputType == 'Texture') {
                value = data.meta.textures[data.value];
            } else {
                value = data.meta.nodes[data.value] || null;
            }
        }
        this._value = value;
        this.inputType = data.inputType;
        this.outputType = data.outputType;
    }
}

class ScriptableValueNodeProxy {
    public static function create():ScriptableValueNode {
        return new ScriptableValueNode();
    }
}

ShaderNode.addNodeElement('scriptableValue', ScriptableValueNodeProxy.create);
Node.addNodeClass('ScriptableValueNode', ScriptableValueNode);