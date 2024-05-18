package three.js.examples.jm.nodes.core;

import Node from './Node.hx';
import NodeUtils from './NodeUtils.hx';

class InputNode extends Node {

    public var isInputNode:Bool = true;

    public var value:Dynamic;
    public var precision:Null<Float>;

    public function new(value:Dynamic, nodeType:Null<String> = null) {
        super(nodeType);
        this.value = value;
        this.precision = null;
    }

    public function getNodeType(?builder:Dynamic):String {
        if (this.nodeType == null) {
            return NodeUtils.getValueType(this.value);
        }
        return this.nodeType;
    }

    public function getInputType(builder:Dynamic):String {
        return this.getNodeType(builder);
    }

    public function setPrecision(precision:Float):InputNode {
        this.precision = precision;
        return this;
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.value = this.value;
        if (this.value != null && this.value.toArray != null) data.value = this.value.toArray();
        data.valueType = NodeUtils.getValueType(this.value);
        data.nodeType = this.nodeType;
        if (data.valueType == 'ArrayBuffer') data.value = NodeUtils.arrayBufferToBase64(data.value);
        data.precision = this.precision;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.nodeType = data.nodeType;
        this.value = if (Std.isOfType(data.value, Array)) NodeUtils.getValueFromType(data.valueType, data.value) else data.value;
        this.precision = data.precision != null ? data.precision : null;
        if (this.value != null && this.value.fromArray != null) this.value = this.value.fromArray(data.value);
    }

    public function generate(?builder:Dynamic, ?output:Dynamic):Void {
        trace('Abstract function.');
    }

}

.addNodeClass('InputNode', InputNode);