import Node, { addNodeClass } from './Node.js';
import { getValueType, getValueFromType, arrayBufferToBase64 } from './NodeUtils.js';

class InputNode extends Node {

	public var isInputNode:Bool = true;
	public var value;
	public var precision:Null<Int>;

	public function new(value:Dynamic, nodeType:Null<String>) {
		super(nodeType);

		this.value = value;
		this.precision = null;
	}

	public function getNodeType(/*builder:Dynamic*/):String {
		if (this.nodeType == null) {
			return getValueType(this.value);
		}

		return this.nodeType;
	}

	public function getInputType(builder:Dynamic):String {
		return this.getNodeType(builder);
	}

	public function setPrecision(precision:Int):InputNode {
		this.precision = precision;
		return this;
	}

	public override function serialize(data:Dynamic) {
		super.serialize(data);

		data.value = this.value;

		if (this.value != null && this.value.toArray != null) data.value = this.value.toArray();

		data.valueType = getValueType(this.value);
		data.nodeType = this.nodeType;

		if (data.valueType == 'ArrayBuffer') data.value = arrayBufferToBase64(data.value);

		data.precision = this.precision;
	}

	public override function deserialize(data:Dynamic) {
		super.deserialize(data);

		this.nodeType = data.nodeType;
		this.value = Array.isArray(data.value) ? getValueFromType(data.valueType, data.value) : data.value;

		this.precision = data.precision || null;

		if (this.value != null && this.value.fromArray != null) this.value = this.value.fromArray(data.value);
	}

	public function generate(/*builder:Dynamic, output:Dynamic*/) {
		trace('Abstract function.');
	}
}

export default InputNode;

addNodeClass('InputNode', InputNode);