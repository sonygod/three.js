package three.js.examples.jvm.renderers.webgpu.nodes;

import three.js.nodes.core.NodeParser;

class WGSLNodeParser extends NodeParser {

    public function parseFunction(source:String):WGSLNodeFunction {
        return new WGSLNodeFunction(source);
    }

}