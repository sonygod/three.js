import Node from "../core/Node";
import NodeUtils from "../core/NodeUtils";
import ShaderNode from "../shadernode/ShaderNode";
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;
import three.extras.core.EventDispatcher;

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
		return this.outputType != null;
	}

	public function set value(val:Dynamic) {
		if (this._value == val) return;

		if (this._cache != null && this.inputType == "URL" && cast this.value.value to ArrayBuffer) {
			js.html.URL.revokeObjectURL(this._cache);

			this._cache = null;
		}

		this._value = val;

		this.events.dispatchEvent({ type: "change" });

		this.refresh();
	}

	public function get value():Dynamic {
		return this._value;
	}

	public function refresh():Void {
		this.events.dispatchEvent({ type: "refresh" });
	}

	public function getValue():Dynamic {
		var value = this.value;

		if (value != null && this._cache == null && this.inputType == "URL" && cast value.value to ArrayBuffer) {
			this._cache = js.html.URL.createObjectURL(new js.html.Blob([value.value]));
		} else if (value != null && value.value != null && value.value != undefined && (
			((this.inputType == "URL" || this.inputType == "String") && typeof value.value == "string") ||
			(this.inputType == "Number" && typeof value.value == "number") ||
			(this.inputType == "Vector2" && value.value.isVector2) ||
			(this.inputType == "Vector3" && value.value.isVector3) ||
			(this.inputType == "Vector4" && value.value.isVector4) ||
			(this.inputType == "Color" && value.value.isColor) ||
			(this.inputType == "Matrix3" && value.value.isMatrix3) ||
			(this.inputType == "Matrix4" && value.value.isMatrix4)
		)) {
			return value.value;
		}

		return this._cache != null ? this._cache : value;
	}

	public function getNodeType(builder:Dynamic):String {
		return value != null && value.isNode ? value.getNodeType(builder) : "float";
	}

	public function setup():Dynamic {
		return value != null && value.isNode ? value : ShaderNode.float();
	}

	public function serialize(data:StringMap):Void {
		super.serialize(data);

		if (this.value != null) {
			if (this.inputType == "ArrayBuffer") {
				data.set("value", NodeUtils.arrayBufferToBase64(this.value));
			} else {
				data.set("value", this.value != null ? this.value.toJSON(data.get("meta")).uuid : null);
			}
		} else {
			data.set("value", null);
		}

		data.set("inputType", this.inputType);
		data.set("outputType", this.outputType);
	}

	public function deserialize(data:StringMap):Void {
		super.deserialize(data);

		var value:Dynamic = null;

		if (data.get("value") != null) {
			if (data.get("inputType") == "ArrayBuffer") {
				value = NodeUtils.base64ToArrayBuffer(data.get("value"));
			} else if (data.get("inputType") == "Texture") {
				value = data.get("meta").textures.get(data.get("value"));
			} else {
				value = data.get("meta").nodes.get(data.get("value")) != null ? data.get("meta").nodes.get(data.get("value")) : null;
			}
		}

		this.value = value;

		this.inputType = data.get("inputType");
		this.outputType = data.get("outputType");
	}
}

class ScriptableValueNodeProxy {
	public static function create(value:Dynamic = null):ScriptableValueNode {
		return new ScriptableValueNode(value);
	}
}

var scriptableValue = ShaderNode.nodeProxy(ScriptableValueNodeProxy);

ShaderNode.addNodeElement("scriptableValue", scriptableValue);

ShaderNode.addNodeClass("ScriptableValueNode", ScriptableValueNode);