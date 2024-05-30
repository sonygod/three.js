import three.js.examples.jsm.nodes.core.NodeParser;
import three.js.examples.jsm.nodes.parsers.GLSLNodeFunction;

class GLSLNodeParser extends NodeParser {

	public function parseFunction(source:String):GLSLNodeFunction {

		return new GLSLNodeFunction(source);

	}

}

typedef GLSLNodeParserParser = GLSLNodeParser;