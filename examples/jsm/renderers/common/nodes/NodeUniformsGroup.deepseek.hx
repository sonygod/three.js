import UniformsGroup from '../UniformsGroup.js';

static var id = 0;

class NodeUniformsGroup extends UniformsGroup {

	public function new(name:String, groupNode:Dynamic) {

		super(name);

		this.id = id ++;
		this.groupNode = groupNode;

		this.isNodeUniformsGroup = true;

	}

	public function get shared():Dynamic {

		return this.groupNode.shared;

	}

	public function getNodes():Array<Dynamic> {

		var nodes = [];

		for (uniform in this.uniforms) {

			var node = uniform.nodeUniform.node;

			if (node == null) throw 'NodeUniformsGroup: Uniform has no node.';

			nodes.push(node);

		}

		return nodes;

	}

}

typedef NodeUniformsGroup_Impl = NodeUniformsGroup;