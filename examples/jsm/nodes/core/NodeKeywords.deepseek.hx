class NodeKeywords {

	var keywords:Array<String>;
	var nodes:Map<String, Dynamic>;
	var keywordsCallback:Map<String, Dynamic->Dynamic>;

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

	public function addKeyword(name:String, callback:Dynamic->Dynamic):NodeKeywords {

		this.keywords.push(name);
		this.keywordsCallback.set(name, callback);

		return this;

	}

	public function parse(code:String):Array<Dynamic> {

		var keywordNames = this.keywords;

		var regExp = new EReg("\\b" + keywordNames.join("\\b|\\b") + "\\b", "g");

		var codeKeywords = EReg.matches(regExp, code);

		var keywordNodes = [];

		if (codeKeywords != null) {

			for (keyword in codeKeywords) {

				var node = this.getNode(keyword);

				if (node != null && keywordNodes.indexOf(node) == -1) {

					keywordNodes.push(node);

				}

			}

		}

		return keywordNodes;

	}

	public function include(builder:Dynamic, code:String):Void {

		var keywordNodes = this.parse(code);

		for (keywordNode in keywordNodes) {

			keywordNode.build(builder);

		}

	}

}