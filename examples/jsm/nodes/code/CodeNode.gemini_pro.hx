import Node from '../core/Node';
import ShaderNode from '../shadernode/ShaderNode';

class CodeNode extends Node {

	public var code:String;
	public var language:String;
	public var includes:Array<Dynamic>;

	public function new(code:String = "", includes:Array<Dynamic> = [], language:String = "") {
		super("code");
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

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.code = this.code;
		data.language = this.language;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.code = data.code;
		this.language = data.language;
	}

}

class CodeNodeProxy extends ShaderNode {
	public function new(code:CodeNode) {
		super(code);
	}
}

var code = new CodeNodeProxy(new CodeNode());

var js = function(src:String, includes:Array<Dynamic>):CodeNode {
	return code.set(src, includes, "js");
};

var wgsl = function(src:String, includes:Array<Dynamic>):CodeNode {
	return code.set(src, includes, "wgsl");
};

var glsl = function(src:String, includes:Array<Dynamic>):CodeNode {
	return code.set(src, includes, "glsl");
};

// AddNodeClass is not directly supported in Haxe.
// You may need to implement your own mechanism for registering classes.
// For example:

// class NodeRegistry {
//   public static var registeredClasses:Map<String, Class<Node>> = new Map();
//   public static function register(name:String, clazz:Class<Node>) {
//     registeredClasses.set(name, clazz);
//   }
// }
//
// NodeRegistry.register("CodeNode", CodeNode);