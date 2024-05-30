import three.js.examples.jsm.renderers.webgpu.nodes.NodeParser;
import three.js.examples.jsm.renderers.webgpu.nodes.WGSLNodeFunction;

class WGSLNodeParser extends NodeParser {

	public function parseFunction(source:String):WGSLNodeFunction {

		return new WGSLNodeFunction(source);

	}

}

typedef WGSLNodeParserParser = WGSLNodeParser;