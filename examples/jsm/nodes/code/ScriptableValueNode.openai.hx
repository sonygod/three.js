package three.js.examples.jsm.nodes.code;

import three.js.core.Node;
import three.js.core.NodeUtils;
import three.js.shadernode.ShaderNode;
import three.js.EventDispatcher;

class ScriptableValueNode extends Node {
    
    public var _value:Dynamic;
    public var _cache:Null<String>;

    public var inputType:Null<String>;
    public var outputType:Null<String>;

    public var events:EventDispatcher;

    public var isScriptableValueNode:Bool;

    public function new(?value:Dynamic) {
        super();

        _value = value;
        _cache = null;

        inputType = null;
        outputType = null;

        events = new EventDispatcher();

        isScriptableValueNode = true;
    }

    public var isScriptableOutputNode(get, never):Bool;

    function get_isScriptableOutputNode():Bool {
        return outputType != null;
    }

    public var value(get, set):Dynamic;

    function get_value():Dynamic {
        return _value;
    }

    function set_value(val:Dynamic):Void {
        if (_value == val) return;

        if (_cache != null && inputType == 'URL' && _value.value is ArrayBuffer) {
            // URL.revokeObjectURL is not available in Haxe, so we can't implement this part
            // _cache = null;
        }

        _value = val;

        events.dispatchEvent({ type: 'change' });

        refresh();
    }

    public function refresh():Void {
        events.dispatchEvent({ type: 'refresh' });
    }

    public function getValue():Dynamic {
        var value = _value;

        if (value != null && _cache == null && inputType == 'URL' && value.value is ArrayBuffer) {
            // URL.createObjectURL is not available in Haxe, so we can't implement this part
            // _cache = URL.createObjectURL(new Blob([value.value]));
        } else if (value != null && value.value != null && value.value != null && (
            (inputType == 'URL' || inputType == 'String' && Std.isOfType(value.value, String)) ||
            (inputType == 'Number' && Std.isOfType(value.value, Float)) ||
            (inputType == 'Vector2' && value.value.isVector2) ||
            (inputType == 'Vector3' && value.value.isVector3) ||
            (inputType == 'Vector4' && value.value.isVector4) ||
            (inputType == 'Color' && value.value.isColor) ||
            (inputType == 'Matrix3' && value.value.isMatrix3) ||
            (inputType == 'Matrix4' && value.value.isMatrix4)
        )) {
            return value.value;
        }

        return _cache != null ? _cache : value;
    }

    public function getNodeType(builder:Dynamic):String {
        return _value != null && _value.isNode ? _value.getNodeType(builder) : 'float';
    }

    public function setup():Dynamic {
        return _value != null && _value.isNode ? _value : float();
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);

        if (_value != null) {
            if (inputType == 'ArrayBuffer') {
                data.value = NodeUtils.arrayBufferToBase64(_value);
            } else {
                data.value = _value.toJSON(data.meta).uuid;
            }
        } else {
            data.value = null;
        }

        data.inputType = inputType;
        data.outputType = outputType;
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

        _value = value;

        inputType = data.inputType;
        outputType = data.outputType;
    }
}

 extern class ScriptableValueNode {
    static public var scriptableValue:ShaderNode = nodeProxy(ScriptableValueNode);
}

addNodeElement('scriptableValue', ScriptableValueNode.scriptableValue);

addNodeClass('ScriptableValueNode', ScriptableValueNode);