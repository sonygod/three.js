import RegExp;

class NodeKeywords {

    public var keywords:Array<String>;
    public var nodes:Map<String, Dynamic>;
    public var keywordsCallback:Map<String, Dynamic>;

    public function new() {

        this.keywords = [];
        this.nodes = new Map();
        this.keywordsCallback = new Map();

    }

    public function getNode(name:String):Dynamic {

        var node = this.nodes.get(name);

        if (node == null && this.keywordsCallback.exists(name)) {

            node = this.keywordsCallback.get(name)(name);

            this.nodes.set(name, node);

        }

        return node;

    }

    public function addKeyword(name:String, callback:Dynamic):NodeKeywords {

        this.keywords.push(name);
        this.keywordsCallback.set(name, callback);

        return this;

    }

    public function parse(code:String):Array<Dynamic> {

        var keywordNames = this.keywords;

        var regExp = new RegExp(RegExp.escape("\\b") + keywordNames.join(RegExp.escape("\\b|\\b")) + RegExp.escape("\\b"), 'g');

        var codeKeywords = code.match(regExp);

        var keywordNodes = [];

        if (codeKeywords != null) {

            for (keyword in codeKeywords) {

                var node = this.getNode(keyword);

                if (node != null && !keywordNodes.exists(node)) {

                    keywordNodes.push(node);

                }

            }

        }

        return keywordNodes;

    }

    public function include(builder:Dynamic, code:String):Void {

        var keywordNodes = this.parse(code);

        for (node in keywordNodes) {

            node.build(builder);

        }

    }

}