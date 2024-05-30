import Node, { addNodeClass } from '../core/Node.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';

class CodeNode extends Node {

	public var isCodeNode:Bool = true;
	public var code:String;
	public var language:String;
	public var includes:Array<Dynamic>;

	public function new( code:String = "", includes:Array<Dynamic> = [], language:String = "" ) {

		super("code");

		this.code = code;
		this.language = language;
		this.includes = includes;

	}

	public function isGlobal():Bool {

		return true;

	}

	public function setIncludes( includes:Array<Dynamic> ):CodeNode {

		this.includes = includes;

		return this;

	}

	public function getIncludes( /*builder*/ ):Array<Dynamic> {

		return this.includes;

	}

	public function generate( builder:Dynamic ) {

		var includes = this.getIncludes( builder );

		for ( include in includes ) {

			include.build( builder );

		}

		var nodeCode = builder.getCodeFromNode( this, this.getNodeType( builder ) );
		nodeCode.code = this.code;

		return nodeCode.code;

	}

	public function serialize( data:Dynamic ) {

		super.serialize( data );

		data.code = this.code;
		data.language = this.language;

	}

	public function deserialize( data:Dynamic ) {

		super.deserialize( data );

		this.code = data.code;
		this.language = data.language;

	}

}

export default CodeNode;

export var code = nodeProxy( CodeNode );

export var js = function( src:String, includes:Array<Dynamic> ) {
	return code( src, includes, 'js' );
};

export var wgsl = function( src:String, includes:Array<Dynamic> ) {
	return code( src, includes, 'wgsl' );
};

export var glsl = function( src:String, includes:Array<Dynamic> ) {
	return code( src, includes, 'glsl' );
};

addNodeClass( 'CodeNode', CodeNode );