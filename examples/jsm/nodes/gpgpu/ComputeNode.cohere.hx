import Node from '../core/Node.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { addNodeElement, nodeObject } from '../shadernode/ShaderNode.hx';

class ComputeNode extends Node {
    public isComputeNode: Bool;
    public computeNode: Node;
    public count: Int;
    public workgroupSize: Array<Int>;
    public dispatchCount: Int;
    public version: Int;
    public updateBeforeType: NodeUpdateType;

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
        if (value) {
            this.version++;
        }
    }

    public function updateDispatchCount(): Void {
        let size: Int = this.workgroupSize[0];
        for (i in 1...this.workgroupSize.length) {
            size *= this.workgroupSize[i];
        }
        this.dispatchCount = Std.int(Math.ceil(this.count / size));
    }

    public function onInit(): Void { }

    public function updateBefore(renderer: Dynamic): Void {
        renderer.compute(this);
    }

    public function generate(builder: Dynamic): Void {
        if (builder.shaderStage == 'compute') {
            let snippet = this.computeNode.build(builder, 'void');
            if (snippet != '') {
                builder.addLineFlowCode(snippet);
            }
        }
    }
}

function compute(node: Node, count: Int, workgroupSize: Array<Int>) {
    return nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));
}

addNodeElement('compute', compute);
addNodeClass('ComputeNode', ComputeNode);

export { ComputeNode, compute };