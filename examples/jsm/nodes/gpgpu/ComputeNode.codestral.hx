import Node from '../core/Node';
import NodeUpdateType from '../core/constants';
import { addNodeElement, nodeObject } from '../shadernode/ShaderNode';

class ComputeNode extends Node {

    public var isComputeNode: Bool;
    public var computeNode: Node;
    public var count: Int;
    public var workgroupSize: Array<Int>;
    public var dispatchCount: Int;
    public var version: Int;
    public var updateBeforeType: NodeUpdateType;

    public function new(computeNode: Node, count: Int, workgroupSize: Array<Int> = [64]) {
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

    public function dispose(): Void {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function set needsUpdate(value: Bool): Void {
        if (value == true) this.version++;
    }

    public function updateDispatchCount(): Void {
        var size = this.workgroupSize[0];
        for (i in 1...this.workgroupSize.length)
            size *= this.workgroupSize[i];
        this.dispatchCount = Math.ceil(this.count / size);
    }

    public function onInit(): Void {}

    public function updateBefore(data: Dynamic): Void {
        data.renderer.compute(this);
    }

    public function generate(builder: Dynamic): Void {
        if (builder.shaderStage == 'compute') {
            var snippet = this.computeNode.build(builder, 'void');
            if (snippet != '') {
                builder.addLineFlowCode(snippet);
            }
        }
    }
}

function compute(node: Node, count: Int, workgroupSize: Array<Int>): Node {
    return nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));
}

addNodeElement('compute', compute);
addNodeClass('ComputeNode', ComputeNode);