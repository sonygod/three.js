import Node from '../core/Node.hx';
import NodeUtils from '../core/NodeUtils.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import EventDispatcher from 'three/src/core/EventDispatcher.hx';

class ScriptableValueNode extends Node {

	public var value:Dynamic;
	public var _cache:Dynamic;

	public var inputType:String;
	public var outpuType:String;

	public var events:EventDispatcher;

	public var isScriptableValueNode:Bool;

	public function new(value:Dynamic = null) {
		super();
		this.value = value;
		this._cache = null;
		this.inputType = null;
		this.outpuType = null;
		this.events = new EventDispatcher();
		this.isScriptableValueNode = true;
	}

	public function get isScriptableOutputNode():Bool {
		return this.outputType != null;
	}

	public function set value(val:Dynamic) {
		if (this.value == val) return;

		if (this._cache != null && this.inputType == 'URL' && cast(this.value, ArrayBuffer) != null) {
			js.Lib.global.URL.revokeObjectURL(this._cache);
			this._cache = null;
		}

		this.value = val;
		this.events.dispatchEvent({ type: 'change' });
		this.refresh();
	}

	public function get value():Dynamic {
		return this.value;
	}

	public function refresh() {
		this.events.dispatchEvent({ type: 'refresh' });
	}

	public function getValue():Dynamic {
		var value = this.value;
		if (value != null && this._cache == null && this.inputType == 'URL' && cast(value, ArrayBuffer) != null) {
			this._cache = js.Lib.global.URL.createObjectURL(new js.Lib.global.Blob([value]));
		} else if (value != null && value != null && value != null && (
			( ( this.inputType == 'URL' || this.inputType == 'String' ) && Std.is(value, String) ) ||
			( this.inputType == 'Number' && Std.is(value, Float) ) ||
			( this.inputType == 'Vector2' && value.isVector2 ) ||
			( this.inputType == 'Vector3' && value.isVector3 ) ||
			( this.inputType == 'Vector4' && value.isVector4 ) ||
			( this.inputType == 'Color' && value.isColor ) ||
			( this.inputType == 'Matrix3' && value.isMatrix3 ) ||
			( this.inputType == 'Matrix4' && value.isMatrix4 )
		)) {
			return value;
		}
		return this._cache != null ? this._cache : value;
	}

	public function getNodeType(builder:Dynamic):String {
		return value != null && value.isNode ? value.getNodeType(builder) : 'float';
	}

	public function setup():Dynamic {
		return value != null && value.isNode ? value : ShaderNode.float();
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

export var ScriptableValueNode = ScriptableValueNode;
export var scriptableValue = ShaderNode.nodeProxy(ScriptableValueNode);
ShaderNode.addNodeElement('scriptableValue', scriptableValue);
ShaderNode.addNodeClass('ScriptableValueNode', ScriptableValueNode);