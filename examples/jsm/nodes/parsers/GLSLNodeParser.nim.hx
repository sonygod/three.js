import NodeParser from '../core/NodeParser.js';
import GLSLNodeFunction from './GLSLNodeFunction.js';

class GLSLNodeParser extends NodeParser {

	public function parseFunction( source:String ) {

		return new GLSLNodeFunction( source );

	}

}

export default GLSLNodeParser;


Please note that Haxe uses `public function` instead of JavaScript's `function` keyword to define methods. Also, Haxe uses `String` instead of JavaScript's `string` for type annotation.

Additionally, Haxe does not have a direct equivalent to JavaScript's `export default` syntax. Instead, you can use `@:expose` metadata to expose a class or function for use in other modules. However, this is not necessary if you are using a build tool like haxelib that can handle module exports.

Here is an example of how you might use `@:expose`:


@:expose
class GLSLNodeParser extends NodeParser {

	public function parseFunction( source:String ) {

		return new GLSLNodeFunction( source );

	}

}


Then, in another module, you can import `GLSLNodeParser` like this:


import GLSLNodeParser from './GLSLNodeParser.js';