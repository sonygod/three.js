package three.js.examples.jvm.nodes.core;

class NodeKeywords {
    public var keywords:Array<String>;
    public var nodes:Map<String, Dynamic>;
    public var keywordsCallback:Map<String, String->Dynamic>;

    public function new() {
        keywords = [];
        nodes = new Map<String, Dynamic>();
        keywordsCallback = new Map<String, String->Dynamic>();
    }

    public function getNode(name:String):Dynamic {
        var node = nodes.get(name);
        if (node == null && keywordsCallback.exists(name)) {
            node = keywordsCallback.get(name)(name);
            nodes.set(name, node);
        }
        return node;
    }

    public function addKeyword(name:String, callback:String->Dynamic):NodeKeywords {
        keywords.push(name);
        keywordsCallback.set(name, callback);
        return this;
    }

    public function parse(code:String):Array<Dynamic> {
        var keywordNames = keywords;
        var regExp = new EReg('\\b' + keywordNames.join('\\b|\\b') + '\\b', 'g');
        var codeKeywords = regExp.match(code);
        var keywordNodes:Array<Dynamic> = [];

        if (codeKeywords != null) {
            for (keyword in codeKeywords) {
                var node = getNode(keyword);
                if (node != null && Lambda.indexOf(keywordNodes, node) == -1) {
                    keywordNodes.push(node);
                }
            }
        }

        return keywordNodes;
    }

    public function include(builder:Dynamic, code:String):Void {
        var keywordNodes = parse(code);
        for (keywordNode in keywordNodes) {
            keywordNode.build(builder);
        }
    }
}