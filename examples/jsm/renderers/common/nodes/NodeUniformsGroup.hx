package three.js.examples.jvm.renderers.common.nodes;

import UniformsGroup;

class NodeUniformsGroup extends UniformsGroup {
    private var id:Int;
    private var groupNode:Dynamic;

    public function new(name:String, groupNode:Dynamic) {
        super(name);
        this.id = NodeUniformsGroup.id++;
        this.groupNode = groupNode;
        this.isNodeUniformsGroup = true;
    }

    private static var id:Int = 0;

    public var shared(get, never):Dynamic;
    private function get_shared():Dynamic {
        return groupNode.shared;
    }

    public function getNodes():Array<Dynamic> {
        var nodes:Array<Dynamic> = [];
        for (uniform in uniforms) {
            var node:Dynamic = uniform.nodeUniform.node;
            if (node == null) throw new Error('NodeUniformsGroup: Uniform has no node.');
            nodes.push(node);
        }
        return nodes;
    }
}