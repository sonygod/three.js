import NodeParser from '../core/NodeParser.hx';
import GLSLNodeFunction from './GLSLNodeFunction.hx';

class GLSLNodeParser extends NodeParser {

    public function parseFunction(source: String): GLSLNodeFunction {
        return new GLSLNodeFunction(source);
    }
}