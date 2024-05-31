import NodeParser from '../../../nodes/core/NodeParser';
import WGSLNodeFunction from './WGSLNodeFunction';

class WGSLNodeParser extends NodeParser {

  public function parseFunction(source:String):WGSLNodeFunction {
    return new WGSLNodeFunction(source);
  }

}

export default WGSLNodeParser;