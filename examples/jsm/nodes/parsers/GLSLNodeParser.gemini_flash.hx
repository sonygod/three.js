import NodeParser from '../core/NodeParser.js';
import GLSLNodeFunction from './GLSLNodeFunction.js';

class GLSLNodeParser extends NodeParser {

	public function parseFunction(source:String):GLSLNodeFunction {

		return new GLSLNodeFunction(source);

	}

}

class GLSLNodeParser {
    static public var instance:GLSLNodeParser = new GLSLNodeParser();
}

export default GLSLNodeParser;