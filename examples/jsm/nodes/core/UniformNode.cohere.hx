import InputNode from './InputNode.hx';
import { objectGroup } from './UniformGroupNode.hx';
import { addNodeClass } from './Node.hx';
import { nodeObject, getConstNodeType } from '../shadernode/ShaderNode.hx';

class UniformNode extends InputNode {
	public isUniformNode: Bool;
	public groupNode: Dynamic;

	public function new(value: Dynamic, nodeType: Dynamic = null) {
		super(value, nodeType);
		this.isUniformNode = true;
		this.groupNode = objectGroup;
	}

	public function setGroup(group: Dynamic): UniformNode {
		this.groupNode = group;
		return this;
	}

	public function getGroup(): Dynamic {
		return this.groupNode;
	}

	public function getUniformHash(builder: Dynamic): Dynamic {
		return this.getHash(builder);
	}

	public function onUpdate(callback: Dynamic, updateType: Dynamic): Void {
		var self = this.getSelf();
		callback = callback.bind(self);
		super.onUpdate(function (frame: Dynamic) {
			var value = callback(frame, self);
			if (value != null) {
				this.value = value;
			}
		}, updateType);
	}

	public function generate(builder: Dynamic, output: Dynamic): Dynamic {
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
			builder.context.label = null;
		}
		return builder.format(propertyName, type, output);
	}
}

@:extern @:noUsing @:native("JS")
class ExternClass {
	public static function default(arg1: Dynamic, arg2: Dynamic): Dynamic;
}

var UniformNode_default = function (arg1: Dynamic, arg2: Dynamic) {
	var nodeType = getConstNodeType(arg2 == null ? arg1 : arg2);
	var value = (arg1 != null && arg1.isNode != null) ? (arg1.node != null ? arg1.node.value : arg1.value) : arg1;
	return nodeObject(new UniformNode(value, nodeType));
};

addNodeClass('UniformNode', UniformNode);

ExternClass.default = UniformNode_default;