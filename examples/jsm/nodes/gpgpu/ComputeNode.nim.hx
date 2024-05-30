import Node, { addNodeClass } from '../core/Node.js';
import { NodeUpdateType } from '../core/constants.js';
import { addNodeElement, nodeObject } from '../shadernode/ShaderNode.js';

class ComputeNode extends Node {

	public var isComputeNode:Bool;
	public var computeNode:Node;
	public var count:Int;
	public var workgroupSize:Array<Int>;
	public var dispatchCount:Int;
	public var version:Int;
	public var updateBeforeType:NodeUpdateType;

	public function new(computeNode:Node, count:Int, workgroupSize:Array<Int> = [ 64 ]) {

		super('void');

		this.isComputeNode = true;

		this.computeNode = computeNode;

		this.count = count;
		this.workgroupSize = workgroupSize;
		this.dispatchCount = 0;

		this.version = 1;
		this.updateBeforeType = NodeUpdateType.OBJECT;

		this.updateDispatchCount();

	}

	public function dispose() {

		this.dispatchEvent({ type: 'dispose' });

	}

	public function set needsUpdate(value:Bool) {

		if (value === true) this.version++;

	}

	public function updateDispatchCount() {

		let size = this.workgroupSize[0];

		for (i in 1...this.workgroupSize.length)
			size *= this.workgroupSize[i];

		this.dispatchCount = Math.ceil(this.count / size);

	}

	public function onInit() { }

	public function updateBefore(renderer:Renderer) {

		renderer.compute(this);

	}

	public function generate(builder:Builder) {

		let shaderStage = builder.shaderStage;

		if (shaderStage === 'compute') {

			let snippet = this.computeNode.build(builder, 'void');

			if (snippet !== '') {

				builder.addLineFlowCode(snippet);

			}

		}

	}

}

export default ComputeNode;

export function compute(node:Node, count:Int, workgroupSize:Array<Int>) {
	return nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));
}

addNodeElement('compute', compute);

addNodeClass('ComputeNode', ComputeNode);