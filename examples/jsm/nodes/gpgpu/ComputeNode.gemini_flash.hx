import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
import {addNodeElement, nodeObject} from "../shadernode/ShaderNode";

class ComputeNode extends Node {

	public var isComputeNode:Bool = true;
	public var computeNode:Dynamic;
	public var count:Int;
	public var workgroupSize:Array<Int>;
	public var dispatchCount:Int = 0;
	public var version:Int = 1;
	public var updateBeforeType:NodeUpdateType = NodeUpdateType.OBJECT;

	public function new(computeNode:Dynamic, count:Int, workgroupSize:Array<Int> = [64]) {
		super("void");
		this.computeNode = computeNode;
		this.count = count;
		this.workgroupSize = workgroupSize;
		this.updateDispatchCount();
	}

	public function dispose():Void {
		this.dispatchEvent({type: "dispose"});
	}

	public function set needsUpdate(value:Bool):Void {
		if (value == true) this.version++;
	}

	public function updateDispatchCount():Void {
		var size = workgroupSize[0];
		for (i in 1...workgroupSize.length) {
			size *= workgroupSize[i];
		}
		this.dispatchCount = Math.ceil(count / size);
	}

	public function onInit():Void {
	}

	public function updateBefore(renderer:Dynamic):Void {
		renderer.compute(this);
	}

	public function generate(builder:Dynamic):Void {
		var {shaderStage} = builder;
		if (shaderStage == "compute") {
			var snippet = this.computeNode.build(builder, "void");
			if (snippet != "") {
				builder.addLineFlowCode(snippet);
			}
		}
	}

}

export var compute = (node:Dynamic, count:Int, workgroupSize:Array<Int>) -> Dynamic {
	return nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));
};

addNodeElement("compute", compute);
addNodeClass("ComputeNode", ComputeNode);