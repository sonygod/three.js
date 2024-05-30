import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class CodeNode extends Node {

	public function new(code:String = '', includes:Array<Dynamic> = [], language:String = '') {
		super('code');

		this.isCodeNode = true;

		this.code = code;
		this.language = language;

		this.includes = includes;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function setIncludes(includes:Array<Dynamic>):CodeNode {
		this.includes = includes;
		return this;
	}

	public function getIncludes(builder:Dynamic):Array<Dynamic> {
		return this.includes;
	}

	public function generate(builder:Dynamic):String {
		var includes = this.getIncludes(builder);

		for (include in includes) {
			include.build(builder);
		}

		var nodeCode = builder.getCodeFromNode(this, this.getNodeType(builder));
		nodeCode.code = this.code;

		return nodeCode.code;
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);

		data.code = this.code;
		data.language = this.language;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);

		this.code = data.code;
		this.language = data.language;
	}

}

static function code(src:String, includes:Array<Dynamic>, language:String):CodeNode {
	return new CodeNode(src, includes, language);
}

static function js(src:String, includes:Array<Dynamic>):CodeNode {
	return code(src, includes, 'js');
}

static function wgsl(src:String, includes:Array<Dynamic>):CodeNode {
	return code(src, includes, 'wgsl');
}

static function glsl(src:String, includes:Array<Dynamic>):CodeNode {
	return code(src, includes, 'glsl');
}

Node.addNodeClass('CodeNode', CodeNode);