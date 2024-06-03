import Node from Node;
import NodeUtils from NodeUtils;
import NodeClassRegister from NodeClassRegister;

class InputNode extends Node {
    public var isInputNode:Bool = true;
    public var value:Dynamic;
    public var precision:Int;

    public function new(value:Dynamic, nodeType:String = null) {
        super(nodeType);
        this.value = value;
        this.precision = null;
    }

    public function getNodeType(/*builder*/):String {
        if(this.nodeType == null) {
            return NodeUtils.getValueType(this.value);
        }
        return this.nodeType;
    }

    public function getInputType(/*builder*/):String {
        return this.getNodeType(/*builder*/);
    }

    public function setPrecision(precision:Int):InputNode {
        this.precision = precision;
        return this;
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.value = this.value;

        if(this.value != null && Reflect.hasField(this.value, "toArray")) {
            data.value = this.value.toArray();
        }

        data.valueType = NodeUtils.getValueType(this.value);
        data.nodeType = this.nodeType;

        if(data.valueType == "ArrayBuffer") {
            data.value = NodeUtils.arrayBufferToBase64(data.value);
        }

        data.precision = this.precision;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.nodeType = data.nodeType;
        this.value = (Std.is(data.value, Array)) ? NodeUtils.getValueFromType(data.valueType, data.value[0], data.value[1]) : data.value;

        this.precision = (data.precision != null) ? data.precision : null;

        if(this.value != null && Reflect.hasField(this.value, "fromArray")) {
            this.value = this.value.fromArray(data.value);
        }
    }

    public function generate(/*builder, output*/) {
        trace("Abstract function.");
    }
}

NodeClassRegister.addNodeClass("InputNode", InputNode);