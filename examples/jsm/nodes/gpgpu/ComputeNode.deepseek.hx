import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class ComputeNode extends Node {

	public function new(computeNode:ShaderNode, count:Int, workgroupSize:Array<Int> = [64]) {
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

	public function dispose():Void {
		this.dispatchEvent({type: 'dispose'});
	}

	public function set needsUpdate(value:Bool):Void {
		if (value == true) this.version++;
	}

	public function updateDispatchCount():Void {
		var count = this.count;
		var workgroupSize = this.workgroupSize;

		var size = workgroupSize[0];

		for (i in workgroupSize.length)
			size *= workgroupSize[i];

		this.dispatchCount = Math.ceil(count / size);
	}

	public function onInit():Void { }

	public function updateBefore(renderer:Renderer):Void {
		renderer.compute(this);
	}

	public function generate(builder:Builder):Void {
		var shaderStage = builder.shaderStage;

		if (shaderStage == 'compute') {
			var snippet = this.computeNode.build(builder, 'void');

			if (snippet != '') {
				builder.addLineFlowCode(snippet);
			}
		}
	}

	static public function compute(node:ShaderNode, count:Int, workgroupSize:Array<Int>):ShaderNode {
		return new ComputeNode(new ShaderNode(node), count, workgroupSize);
	}
}

ShaderNode.addNodeElement('compute', ComputeNode.compute);
Node.addNodeClass('ComputeNode', ComputeNode);