abstract class NodeParser {

    public function parseFunction(source:String):Void {

        trace('Abstract function.');

    }

}

class NodeParserImpl extends NodeParser {}