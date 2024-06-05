import InputNode from "./InputNode";
import {objectGroup} from "./UniformGroupNode";
import {addNodeClass} from "./Node";
import {nodeObject, getConstNodeType} from "../shadernode/ShaderNode";

class UniformNode extends InputNode {
	public isUniformNode:Bool = true;
	public groupNode:Dynamic = objectGroup;

	public function new(value:Dynamic, nodeType:Dynamic = null) {
		super(value, nodeType);
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

	public function onUpdate(callback:Dynamic, updateType:Dynamic):Dynamic {
		var self = this.getSelf();
		callback = callback.bind(self);
		return super.onUpdate((frame) -> {
			var value = callback(frame, self);
			if (value != null) {
				this.value = value;
			}
		}, updateType);
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var type = this.getNodeType(builder);
		var hash = this.getUniformHash(builder);
		var sharedNode = builder.getNodeFromHash(hash);
		if (sharedNode == null) {
			builder.setHashNode(this, hash);
			sharedNode = this;
		}
		var sharedNodeType = sharedNode.getInputType(builder);
		var nodeUniform = builder.getUniformFromNode(sharedNode, sharedNodeType, builder.shaderStage, builder.context.label);
		var propertyName = builder.getPropertyName(nodeUniform);
		if (builder.context.label != null) {
			delete builder.context.label;
		}
		return builder.format(propertyName, type, output);
	}
}

export var uniform = function(arg1:Dynamic, arg2:Dynamic):Dynamic {
	var nodeType = getConstNodeType(arg2 != null ? arg2 : arg1);
	var value = (arg1 != null && arg1.isNode == true) ? ((arg1.node != null && arg1.node.value != null) ? arg1.node.value : arg1.value) : arg1;
	return nodeObject(new UniformNode(value, nodeType));
};

addNodeClass("UniformNode", UniformNode);