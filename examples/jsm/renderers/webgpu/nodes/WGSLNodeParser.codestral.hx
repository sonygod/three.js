import NodeParser from '../../../nodes/core/NodeParser.hx';
import WGSLNodeFunction from './WGSLNodeFunction.hx';

class WGSLNodeParser extends NodeParser {

    public function parseFunction(source:String):WGSLNodeFunction {
        return new WGSLNodeFunction(source);
    }

}

export default WGSLNodeParser;