class NodeKeywords {
	private var keywords: Array<String> = [];
	private var nodes: haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap<Dynamic>();
	private var keywordsCallback: haxe.ds.StringMap<(String -> Dynamic)> = new haxe.ds.StringMap<(String -> Dynamic)>();

	public function new() {}

	public function getNode(name: String): Dynamic {
		var node: Dynamic = this.nodes.get(name);

		if (node == null && this.keywordsCallback.exists(name)) {
			node = this.keywordsCallback.get(name)(name);
			this.nodes.set(name, node);
		}

		return node;
	}

	public function addKeyword(name: String, callback: (String -> Dynamic)): NodeKeywords {
		this.keywords.push(name);
		this.keywordsCallback.set(name, callback);

		return this;
	}

	public function parse(code: String): Array<Dynamic> {
		var regExp: EReg = new EReg("\\b" + this.keywords.join("\\b|\\b") + "\\b", "g");

		var codeKeywords: Array<String> = code.match(regExp);

		var keywordNodes: Array<Dynamic> = [];

		if (codeKeywords != null) {
			for (keyword in codeKeywords) {
				var node: Dynamic = this.getNode(keyword);

				if (node != null && !keywordNodes.contains(node)) {
					keywordNodes.push(node);
				}
			}
		}

		return keywordNodes;
	}

	public function include(builder: Dynamic, code: String): Void {
		var keywordNodes: Array<Dynamic> = this.parse(code);

		for (keywordNode in keywordNodes) {
			keywordNode.build(builder);
		}
	}
}