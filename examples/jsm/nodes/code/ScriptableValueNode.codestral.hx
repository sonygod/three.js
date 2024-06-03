import Node from '../core/Node';
import NodeUtils from '../core/NodeUtils';
import ShaderNode from '../shadernode/ShaderNode';
import three.events.EventDispatcher;

class ScriptableValueNode extends Node {

    public var _value : Dynamic;
    public var _cache : Dynamic;
    public var inputType : String;
    public var outputType : String;
    public var events : EventDispatcher;
    public var isScriptableValueNode : Bool;

    public function new(value:Dynamic = null) {
        super();

        this._value = value;
        this._cache = null;

        this.inputType = null;
        this.outputType = null;

        this.events = new EventDispatcher();
        this.isScriptableValueNode = true;
    }

    public function get isScriptableOutputNode():Bool {
        return this.outputType !== null;
    }

    public function set value(val:Dynamic) {
        if (this._value === val) return;

        if (this._cache != null && this.inputType == 'URL' && this._value.value is Array<Int>) {
            js.Browser.window.URL.revokeObjectURL(this._cache);
            this._cache = null;
        }

        this._value = val;
        this.events.dispatchEvent({ type : 'change' });
        this.refresh();
    }

    public function get value():Dynamic {
        return this._value;
    }

    public function refresh() {
        this.events.dispatchEvent({ type : 'refresh' });
    }

    public function getValue():Dynamic {
        var value = this.value;

        if (value != null && this._cache == null && this.inputType == 'URL' && value.value is Array<Int>) {
            this._cache = js.Browser.window.URL.createObjectURL(new js.Browser.window.Blob([value.value]));
        } else if (value != null && value.value != null && value.value != undefined && (
            ((this.inputType == 'URL' || this.inputType == 'String') && Type.typeof(value.value) == String) ||
            (this.inputType == 'Number' && Type.typeof(value.value) == Int) ||
            (this.inputType == 'Vector2' && value.value.isVector2) ||
            (this.inputType == 'Vector3' && value.value.isVector3) ||
            (this.inputType == 'Vector4' && value.value.isVector4) ||
            (this.inputType == 'Color' && value.value.isColor) ||
            (this.inputType == 'Matrix3' && value.value.isMatrix3) ||
            (this.inputType == 'Matrix4' && value.value.isMatrix4)
        )) {
            return value.value;
        }

        return this._cache != null ? this._cache : value;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.value != null && this.value.isNode ? this.value.getNodeType(builder) : 'float';
    }

    public function setup():Dynamic {
        return this.value != null && this.value.isNode ? this.value : ShaderNode.float();
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);

        if (this.value != null) {
            if (this.inputType == 'ArrayBuffer') {
                data.value = NodeUtils.arrayBufferToBase64(this.value);
            } else {
                data.value = this.value != null ? this.value.toJSON(data.meta).uuid : null;
            }
        } else {
            data.value = null;
        }

        data.inputType = this.inputType;
        data.outputType = this.outputType;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);

        var value:Dynamic = null;

        if (data.value != null) {
            if (data.inputType == 'ArrayBuffer') {
                value = NodeUtils.base64ToArrayBuffer(data.value);
            } else if (data.inputType == 'Texture') {
                value = data.meta.textures[data.value];
            } else {
                value = data.meta.nodes[data.value] != null ? data.meta.nodes[data.value] : null;
            }
        }

        this.value = value;
        this.inputType = data.inputType;
        this.outputType = data.outputType;
    }

}

export default ScriptableValueNode;

export function scriptableValue():Dynamic {
    return ShaderNode.nodeProxy(ScriptableValueNode);
}

Node.addNodeElement('scriptableValue', scriptableValue());
Node.addNodeClass('ScriptableValueNode', ScriptableValueNode);