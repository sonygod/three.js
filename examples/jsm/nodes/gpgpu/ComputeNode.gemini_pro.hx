import Node from '../core/Node';
import NodeUpdateType from '../core/constants';
import ShaderNode, { nodeObject, addNodeElement } from '../shadernode/ShaderNode';

class ComputeNode extends Node {

	public var isComputeNode:Bool = true;

	public var computeNode:ShaderNode;
	public var count:Int;
	public var workgroupSize:Array<Int>;
	public var dispatchCount:Int;

	public var version:Int = 1;
	public var updateBeforeType:NodeUpdateType = NodeUpdateType.OBJECT;

	public function new(computeNode:ShaderNode, count:Int, workgroupSize:Array<Int> = [64]) {
		super("void");

		this.computeNode = computeNode;
		this.count = count;
		this.workgroupSize = workgroupSize;
		this.dispatchCount = 0;

		this.updateDispatchCount();
	}

	public function dispose() {
		this.dispatchEvent({ type: "dispose" });
	}

	public function set needsUpdate(value:Bool) {
		if (value) this.version++;
	}

	public function updateDispatchCount() {
		var size = this.workgroupSize[0];

		for (i in 1...this.workgroupSize.length) {
			size *= this.workgroupSize[i];
		}

		this.dispatchCount = Math.ceil(this.count / size);
	}

	public function onInit() {
	}

	public function updateBefore(renderer:Dynamic) {
		renderer.compute(this);
	}

	public function generate(builder:Dynamic) {
		if (builder.shaderStage == "compute") {
			var snippet = this.computeNode.build(builder, "void");

			if (snippet != "") {
				builder.addLineFlowCode(snippet);
			}
		}
	}

}

var compute = (node:ShaderNode, count:Int, workgroupSize:Array<Int>) => nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));

addNodeElement("compute", compute);

addNodeClass("ComputeNode", ComputeNode);