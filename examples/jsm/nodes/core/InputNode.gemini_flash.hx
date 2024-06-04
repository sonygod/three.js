import Node from "Node";
import NodeUtils from "NodeUtils";

class InputNode extends Node {

	public var isInputNode:Bool = true;
	public var value:Dynamic;
	public var precision:Null<Int>;

	public function new(value:Dynamic, nodeType:Null<String> = null) {
		super(nodeType);
		this.value = value;
	}

	public function getNodeType(builder:Dynamic):String {
		if (this.nodeType == null) {
			return NodeUtils.getValueType(this.value);
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

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.value = this.value;
		if (Reflect.hasField(this.value, "toArray")) data.value = Reflect.callMethod(this.value, "toArray", []);
		data.valueType = NodeUtils.getValueType(this.value);
		data.nodeType = this.nodeType;
		if (data.valueType == "ArrayBuffer") data.value = NodeUtils.arrayBufferToBase64(data.value);
		data.precision = this.precision;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.nodeType = data.nodeType;
		this.value = if (Std.is(data.value, Array)) {
			NodeUtils.getValueFromType(data.valueType, ...data.value);
		} else {
			data.value;
		};
		this.precision = data.precision != null ? data.precision : null;
		if (Reflect.hasField(this.value, "fromArray")) this.value = Reflect.callMethod(this.value, "fromArray", [data.value]);
	}

	public function generate(builder:Dynamic, output:Dynamic):Void {
		Sys.println("Abstract function.");
	}

}

class InputNodeClass extends Node.NodeClass {

	public function new() {
		super("InputNode");
	}

	override public function create(value:Dynamic, nodeType:Null<String> = null):InputNode {
		return new InputNode(value, nodeType);
	}

}

Node.addNodeClass(new InputNodeClass());