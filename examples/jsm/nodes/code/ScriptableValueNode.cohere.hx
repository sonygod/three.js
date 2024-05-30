import Node from '../core/Node.hx';
import { arrayBufferToBase64, base64ToArrayBuffer } from '../core/NodeUtils.hx';
import { addNodeElement, nodeProxy, float } from '../shadernode/ShaderNode.hx';

class ScriptableValueNode extends Node {
    public _value:Dynamic;
    public _cache:Dynamic;
    public inputType:String;
    public outputType:String;
    public events:EventDispatcher;
    public isScriptableValueNode:Bool;
    public isScriptableOutputNode:Bool;

    public function new(value:Dynamic = null) {
        super();
        this._value = value;
        this._cache = null;
        this.inputType = null;
        this.outputType = null;
        this.events = EventDispatcher();
        this.isScriptableValueNode = true;
    }

    public function set_value(val:Dynamic):Void {
        if (this._value == val) return;
        if (this._cache != null && this.inputType == 'URL' && typeof this.value.value == ArrayBuffer) {
            URL.revokeObjectURL(this._cache);
            this._cache = null;
        }
        this._value = val;
        this.events.dispatchEvent(Event('change'));
        this.refresh();
    }

    public function get_value():Dynamic {
        return this._value;
    }

    public function refresh():Void {
        this.events.dispatchEvent(Event('refresh'));
    }

    public function getValue():Dynamic {
        var value = this.value;
        if (value != null && this._cache == null && this.inputType == 'URL' && typeof value.value == ArrayBuffer) {
            this._cache = URL.createObjectURL(Blob([value.value]));
        } else if (value != null && value.value != null && value.value != undefined) {
            if ((this.inputType == 'URL' || this.inputType == 'String') && Std.is(value.value, String)) return value.value;
            if (this.inputType == 'Number' && Std.is(value.value, Float)) return value.value;
            if (this.inputType == 'Vector2' && value.value.isVector2) return value.value;
            if (this.inputType == 'Vector3' && value.value.isVector3) return value.value;
            if (this.inputType == 'Vector4' && value.value.isVector4) return value.value;
            if (this.inputType == 'Color' && value.value.isColor) return value.value;
            if (this.inputType == 'Matrix3' && value.value.isMatrix3) return value.value;
            if (this.inputType == 'Matrix4' && value.value.isMatrix4) return value.value;
        }
        return this._cache != null ? this._cache : value;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.value != null && this.value.isNode ? this.value.getNodeType(builder) : 'float';
    }

    public function setup():Dynamic {
        return this.value != null && this.value.isNode ? this.value : float();
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);
        if (this.value != null) {
            if (this.inputType == 'ArrayBuffer') {
                data.value = arrayBufferToBase64(this.value);
            } else {
                data.value = this.value != null ? this.value.toJSON(data.meta).uuid : null;
            }
        } else {
            data.value = null;
        }
        data.inputType = this.inputType;
        data.outputType = this.outputType;
    }

    public override function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        var value:Dynamic = null;
        if (data.value != null) {
            if (data.inputType == 'ArrayBuffer') {
                value = base64ToArrayBuffer(data.value);
            } else if (data.inputType == 'Texture') {
                value = data.meta.textures[data.value];
            } else {
                value = data.meta.nodes[data.value] as Dynamic;
            }
        }
        this.value = value;
        this.inputType = data.inputType;
        this.outputType = data.outputType;
    }
}

@:export
var ScriptableValueNode_ = ScriptableValueNode;

@:export
var scriptableValue = nodeProxy(ScriptableValueNode);

addNodeElement('scriptableValue', scriptableValue);

addNodeClass('ScriptableValueNode', ScriptableValueNode);