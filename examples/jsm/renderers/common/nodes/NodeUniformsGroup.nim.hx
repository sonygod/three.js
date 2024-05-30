import UniformsGroup from '../UniformsGroup.hx';

class NodeUniformsGroup extends UniformsGroup {
    public static var id:Int = 0;

    public var groupNode:Dynamic;
    public var isNodeUniformsGroup:Bool = true;

    public function new(name:String, groupNode:Dynamic) {
        super(name);

        this.id = id++;
        this.groupNode = groupNode;
    }

    public function get shared():Dynamic {
        return this.groupNode.shared;
    }

    public function getNodes():Array<Dynamic> {
        var nodes:Array<Dynamic> = [];

        for (uniform in this.uniforms) {
            var node = uniform.nodeUniform.node;

            if (node == null) throw new Error('NodeUniformsGroup: Uniform has no node.');

            nodes.push(node);
        }

        return nodes;
    }
}