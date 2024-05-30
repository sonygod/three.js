package three.js.examples.jsm.nodes.parsers;

import three.js.core.NodeParser;

class GLSLNodeParser extends NodeParser {
    public function new() {
        super();
    }

    public function parseFunction(source:String):GLSLNodeFunction {
        return new GLSLNodeFunction(source);
    }
}