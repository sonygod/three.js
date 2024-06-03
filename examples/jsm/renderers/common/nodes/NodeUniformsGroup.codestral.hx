import UniformsGroup;

class NodeUniformsGroup extends UniformsGroup {

    private var _id: Int;
    private var _groupNode: Dynamic;

    public function new(name: String, groupNode: Dynamic) {
        super(name);

        this._id = id++;
        this._groupNode = groupNode;

        this.isNodeUniformsGroup = true;
    }

    public function get_shared(): Bool {
        return this._groupNode.shared;
    }

    public function getNodes(): Array<Dynamic> {
        var nodes: Array<Dynamic> = [];

        for (uniform in this.uniforms) {
            var node = uniform.nodeUniform.node;

            if (node == null) throw 'NodeUniformsGroup: Uniform has no node.';

            nodes.push(node);
        }

        return nodes;
    }
}

var id = 0;