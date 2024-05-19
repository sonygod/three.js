package three.js.examples.jsm.nodes.parsers;

import three.js.core.NodeParser;

class GLSLNodeParser extends NodeParser {
    public function new() {
        super();
    }

    override public function parseFunction(source:String):Void {
        return new GLSLNodeFunction(source);
    }
}