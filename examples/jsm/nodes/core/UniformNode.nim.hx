import InputNode from './InputNode.hx';
import { objectGroup } from './UniformGroupNode.hx';
import { addNodeClass } from './Node.hx';
import { nodeObject, getConstNodeType } from '../shadernode/ShaderNode.hx';

class UniformNode extends InputNode {

	public var isUniformNode:Bool = true;
	public var groupNode:Dynamic;

	public function new(value:Dynamic, nodeType:Dynamic = null) {
		super(value, nodeType);
		this.groupNode = objectGroup;
	}

	public function setGroup(group:Dynamic):UniformNode {
		this.groupNode = group;
		return this;
	}

	public function getGroup():Dynamic {
		return this.groupNode;
	}

	public function getUniformHash(builder:Dynamic):Dynamic {
		return this.getHash(builder);
	}

	public function onUpdate(callback:Dynamic, updateType:Dynamic):Void {
		var self = this.getSelf();
		callback = callback.bind(self);
		return super.onUpdate(function(frame) {
			var value = callback(frame, self);
			if (value !== undefined) {
				this.value = value;
			}
		}, updateType);
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var type = this.getNodeType(builder);
		var hash = this.getUniformHash(builder);
		var sharedNode = builder.getNodeFromHash(hash);
		if (sharedNode === undefined) {
			builder.setHashNode(this, hash);
			sharedNode = this;
		}
		var sharedNodeType = sharedNode.getInputType(builder);
		var nodeUniform = builder.getUniformFromNode(sharedNode, sharedNodeType, builder.shaderStage, builder.context.label);
		var propertyName = builder.getPropertyName(nodeUniform);
		if (builder.context.label !== undefined) delete builder.context.label;
		return builder.format(propertyName, type, output);
	}

}

export default UniformNode;

export function uniform(arg1:Dynamic, arg2:Dynamic):Dynamic {
	var nodeType = getConstNodeType(arg2 || arg1);
	var value = (arg1 && arg1.isNode === true) ? (arg1.node && arg1.node.value) || arg1.value : arg1;
	return nodeObject(new UniformNode(value, nodeType));
}

addNodeClass('UniformNode', UniformNode);