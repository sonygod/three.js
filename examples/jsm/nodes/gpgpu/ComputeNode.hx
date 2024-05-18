package three.js.examples.jvm.nodes.gpgpu;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.shadernode.ShaderNode;

class ComputeNode extends Node {
    public var isComputeNode:Bool = true;
    public var computeNode:Dynamic;
    public var count:Int;
    public var workgroupSize:Array<Int>;
    public var dispatchCount:Int = 0;
    public var version:Int = 1;
    public var updateBeforeType:NodeUpdateType = NodeUpdateType.OBJECT;

    public function new(computeNode:Dynamic, count:Int, workgroupSize:Array<Int> = [64]) {
        super('void');
        this.computeNode = computeNode;
        this.count = count;
        this.workgroupSize = workgroupSize;
        updateDispatchCount();
    }

    public function dispose():Void {
        dispatchEvent({ type: 'dispose' });
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value) version++;
    }

    public function updateDispatchCount():Void {
        var size:Int = workgroupSize[0];
        for (i in 1...workgroupSize.length) {
            size *= workgroupSize[i];
        }
        dispatchCount = Math.ceil(count / size);
    }

    public function onInit():Void {}

    public function updateBefore(renderer:Dynamic):Void {
        renderer.compute(this);
    }

    public function generate(builder:Dynamic):Void {
        if (builder.shaderStage == 'compute') {
            var snippet:String = computeNode.build(builder, 'void');
            if (snippet != '') {
                builder.addLineFlowCode(snippet);
            }
        }
    }

    public static function compute(node:Dynamic, count:Int, workgroupSize:Array<Int> = [64]):ComputeNode {
        return new ComputeNode(nodeObject(node), count, workgroupSize);
    }
}

ShaderNode.addNodeElement('compute', ComputeNode.compute);
Node.addNodeClass('ComputeNode', ComputeNode);