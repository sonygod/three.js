class NodeKeywords {

	public var keywords:Array<String> = [];
	public var nodes:Map<String,Dynamic> = new Map();
	public var keywordsCallback:Map<String,Dynamic->Dynamic> = new Map();

	public function new() {
	}

	public function getNode(name:String):Dynamic {

		var node = nodes.get(name);

		if (node == null && keywordsCallback.exists(name)) {

			node = keywordsCallback.get(name)(name);

			nodes.set(name, node);

		}

		return node;

	}

	public function addKeyword(name:String, callback:Dynamic->Dynamic):NodeKeywords {

		keywords.push(name);
		keywordsCallback.set(name, callback);

		return this;

	}

	public function parse(code:String):Array<Dynamic> {

		var keywordNames = keywords;

		var regExp = new EReg(`\\b${keywordNames.join('\\b|\\b')}\\b`, 'g');

		var codeKeywords = regExp.match(code);

		var keywordNodes:Array<Dynamic> = [];

		if (codeKeywords != null) {

			for (keyword in codeKeywords) {

				var node = getNode(keyword);

				if (node != null && keywordNodes.indexOf(node) == -1) {

					keywordNodes.push(node);

				}

			}

		}

		return keywordNodes;

	}

	public function include(builder:Dynamic, code:String) {

		var keywordNodes = parse(code);

		for (keywordNode in keywordNodes) {

			keywordNode.build(builder);

		}

	}

}