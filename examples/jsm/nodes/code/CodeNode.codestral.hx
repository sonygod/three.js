import Node from '../core/Node';
import { nodeProxy } from '../shadernode/ShaderNode';

class CodeNode extends Node {

	public var code: String;
	public var language: String;
	public var includes: Array<Node>;

	public function new(code: String = '', includes: Array<Node> = [], language: String = '') {
		super('code');
		this.isCodeNode = true;
		this.code = code;
		this.language = language;
		this.includes = includes;
	}

	public function isGlobal(): Bool {
		return true;
	}

	public function setIncludes(includes: Array<Node>): CodeNode {
		this.includes = includes;
		return this;
	}

	public function getIncludes(/*builder*/): Array<Node> {
		return this.includes;
	}

	public function generate(builder: Builder): String {
		var includes: Array<Node> = this.getIncludes(builder);
		for (include in includes) {
			include.build(builder);
		}
		var nodeCode: NodeCode = builder.getCodeFromNode(this, this.getNodeType(builder));
		nodeCode.code = this.code;
		return nodeCode.code;
	}

	public function serialize(data: Dynamic): Void {
		super.serialize(data);
		data.code = this.code;
		data.language = this.language;
	}

	public function deserialize(data: Dynamic): Void {
		super.deserialize(data);
		this.code = data.code;
		this.language = data.language;
	}
}

export default CodeNode;

export var code: (src: String, includes: Array<Node>, language: String) -> CodeNode = nodeProxy(CodeNode);

export function js(src: String, includes: Array<Node>): CodeNode {
	return code(src, includes, 'js');
}

export function wgsl(src: String, includes: Array<Node>): CodeNode {
	return code(src, includes, 'wgsl');
}

export function glsl(src: String, includes: Array<Node>): CodeNode {
	return code(src, includes, 'glsl');
}

Node.addNodeClass('CodeNode', CodeNode);