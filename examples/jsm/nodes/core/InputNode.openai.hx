package three.js.examples.jsm.nodes.core;

import Node;
import NodeUtils;

class InputNode extends Node {
    public var isInputNode:Bool = true;
    public var value:Any;
    public var precision:Null<Int>;

    public function new(value:Any, nodeType:Null<String> = null) {
        super(nodeType);
        this.value = value;
        this.precision = null;
    }

    public function getNodeType(builder:Dynamic):String {
        if (nodeType == null) {
            return NodeUtils.getValueType(value);
        }
        return nodeType;
    }

    public function getInputType(builder:Dynamic):String {
        return getNodeType(builder);
    }

    public function setPrecision(precision:Int):InputNode {
        this.precision = precision;
        return this;
    }

    override public function serialize(data:Any):Void {
        super.serialize(data);
        data.value = value;
        if (value != null && Std.isOfType(value, Array)) data.value = value.toArray();
        data.valueType = NodeUtils.getValueType(value);
        data.nodeType = nodeType;
        if (data.valueType == 'ArrayBuffer') data.value = NodeUtils.arrayBufferToBase64(data.value);
        data.precision = precision;
    }

    override public function deserialize(data:Any):Void {
        super.deserialize(data);
        nodeType = data.nodeType;
        value = if (Std.isOfType(data.value, Array)) NodeUtils.getValueFromType(data.valueType, data.value) else data.value;
        precision = data.precision != null ? data.precision : null;
        if (value != null && Std.isOfType(value, { fromArray:Array<Dynamic> -> Void })) value = value.fromArray(data.value);
    }

    public function generate(builder:Dynamic, output:Dynamic) : Void {
        trace('Abstract function.');
    }

    // static registration
    static public function __init__() {
        Node.addNodeClass('InputNode', InputNode);
    }
}