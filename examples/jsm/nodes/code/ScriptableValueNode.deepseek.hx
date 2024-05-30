package three.js.examples.jsm.nodes.code;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.NodeUtils;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeProxy;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.float;
import three.js.examples.jsm.nodes.core.Node.addNodeClass;
import three.three.EventDispatcher;

class ScriptableValueNode extends Node {

	public var _value:Dynamic;
	public var _cache:Dynamic;
	public var inputType:String;
	public var outputType:String;
	public var events:EventDispatcher;
	public var isScriptableValueNode:Bool = true;

	public function new(value:Dynamic = null) {
		super();
		this._value = value;
		this._cache = null;
		this.inputType = null;
		this.outputType = null;
		this.events = new EventDispatcher();
	}

	public function get isScriptableOutputNode():Bool {
		return this.outputType !== null;
	}

	public function set value(val:Dynamic):Void {
		if (this._value === val) return;
		if (this._cache && this.inputType == 'URL' && this.value.value instanceof ArrayBuffer) {
			URL.revokeObjectURL(this._cache);
			this._cache = null;
		}
		this._value = val;
		this.events.dispatchEvent({type: 'change'});
		this.refresh();
	}

	public function get value():Dynamic {
		return this._value;
	}

	public function refresh():Void {
		this.events.dispatchEvent({type: 'refresh'});
	}

	public function getValue():Dynamic {
		var value = this.value;
		if (value && this._cache == null && this.inputType == 'URL' && value.value instanceof ArrayBuffer) {
			this._cache = URL.createObjectURL(new Blob([value.value]));
		} else if (value && value.value != null && value.value != undefined && (
			((this.inputType == 'URL' || this.inputType == 'String') && Std.is(value.value, String)) ||
			(this.inputType == 'Number' && Std.is(value.value, Float)) ||
			(this.inputType == 'Vector2' && value.value.isVector2) ||
			(this.inputType == 'Vector3' && value.value.isVector3) ||
			(this.inputType == 'Vector4' && value.value.isVector4) ||
			(this.inputType == 'Color' && value.value.isColor) ||
			(this.inputType == 'Matrix3' && value.value.isMatrix3) ||
			(this.inputType == 'Matrix4' && value.value.isMatrix4)
		)) {
			return value.value;
		}
		return this._cache || value;
	}

	public function getNodeType(builder:Dynamic):String {
		return this.value && this.value.isNode ? this.value.getNodeType(builder) : 'float';
	}

	public function setup():Dynamic {
		return this.value && this.value.isNode ? this.value : float();
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		if (this.value != null) {
			if (this.inputType == 'ArrayBuffer') {
				data.value = NodeUtils.arrayBufferToBase64(this.value);
			} else {
				data.value = this.value ? this.value.toJSON(data.meta).uuid : null;
			}
		} else {
			data.value = null;
		}
		data.inputType = this.inputType;
		data.outputType = this.outputType;
	}

	public function deserialize(data:Dynamic):Void {
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
		this.value = value;
		this.inputType = data.inputType;
		this.outputType = data.outputType;
	}
}

@:native('three.js.examples.jsm.nodes.shadernode.ShaderNode.addNodeElement')
extern function addNodeElement(name:String, node:Dynamic):Void;

@:native('three.js.examples.jsm.nodes.core.Node.addNodeClass')
extern function addNodeClass(name:String, node:Dynamic):Void;

addNodeElement('scriptableValue', scriptableValue);
addNodeClass('ScriptableValueNode', ScriptableValueNode);