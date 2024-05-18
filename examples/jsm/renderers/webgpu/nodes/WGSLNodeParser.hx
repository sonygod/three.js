package three.js.examples.jsm.renderers.webgpu.nodes;

import nodes.core.NodeParser;

class WGSLNodeParser extends NodeParser {
    override function parseFunction(source:String):WGSLNodeFunction {
        return new WGSLNodeFunction(source);
    }
}