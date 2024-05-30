package three.js.examples.jsm.renderers.common.nodes;

import three.js.examples.jsm.renderers.common.UniformsGroup;

class NodeUniformsGroup extends UniformsGroup {
    public var id:Int;
    public var groupNode:Dynamic;
    public var isNodeUniformsGroup:Bool = true;

    public function new(name:String, groupNode:Dynamic) {
        super(name);
        id = Std.parseInt(id++) ;
        this.groupNode = groupNode;
    }

    public function get_shared():Dynamic {
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