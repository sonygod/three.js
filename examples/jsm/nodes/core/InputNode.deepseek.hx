import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.NodeUtils;

class InputNode extends Node {

	public function new(value, nodeType = null) {
		super(nodeType);
		this.isInputNode = true;
		this.value = value;
		this.precision = null;
	}

	public function getNodeType(builder:Dynamic):String {
		if (this.nodeType === null) {
			return NodeUtils.getValueType(this.value);
		}
		return this.nodeType;
	}

	public function getInputType(builder:Dynamic):String {
		return this.getNodeType(builder);
	}

	public function setPrecision(precision:Dynamic):InputNode {
		this.precision = precision;
		return this;
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.value = this.value;
		if (this.value && this.value.toArray) data.value = this.value.toArray();
		data.valueType = NodeUtils.getValueType(this.value);
		data.nodeType = this.nodeType;
		if (data.valueType === 'ArrayBuffer') data.value = NodeUtils.arrayBufferToBase64(data.value);
		data.precision = this.precision;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.nodeType = data.nodeType;
		this.value = (Std.is(data.value, Array) ? NodeUtils.getValueFromType(data.valueType, data.value) : data.value);
		this.precision = (data.precision || null);
		if (this.value && this.value.fromArray) this.value = this.value.fromArray(data.value);
	}

	public function generate(builder:Dynamic, output:Dynamic):Void {
		trace('Abstract function.');
	}

}

Node.addNodeClass('InputNode', InputNode);