package three.js.examples.javascript.nodes.gpgpu;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class ComputeNode extends Node {
    public var isComputeNode:Bool = true;
    public var computeNode:Dynamic;
    public var count:Int;
    public var workgroupSize:Array<Int>;
    public var dispatchCount:Int;
    public var version:Int;
    public var updateBeforeType:NodeUpdateType;

    public function new(computeNode:Dynamic, count:Int, workgroupSize:Array<Int> = [64]) {
        super("void");
        this.computeNode = computeNode;
        this.count = count;
        this.workgroupSize = workgroupSize;
        this.dispatchCount = 0;
        this.version = 1;
        this.updateBeforeType = NodeUpdateType.OBJECT;
        updateDispatchCount();
    }

    public function dispose() {
        dispatchEvent({ type: "dispose" });
    }

    public function set_needsUpdate(value:Bool) {
        if (value) version++;
    }

    public function updateDispatchCount() {
        var size:Int = workgroupSize[0];
        for (i in 1...workgroupSize.length) {
            size *= workgroupSize[i];
        }
        dispatchCount = Math.ceil(count / size);
    }

    public function onInit() {}

    public function updateBefore(renderer:Dynamic) {
        renderer.compute(this);
    }

    public function generate(builder:Dynamic) {
        if (builder.shaderStage == "compute") {
            var snippet = computeNode.build(builder, "void");
            if (snippet != "") {
                builder.addLineFlowCode(snippet);
            }
        }
    }
}

// export default ComputeNode;
// export function compute(node:Dynamic, count:Int, workgroupSize:Array<Int>) {
//     return nodeObject(new ComputeNode(nodeObject(node), count, workgroupSize));
// }
// addNodeElement("compute", compute);
// addNodeClass("ComputeNode", ComputeNode);