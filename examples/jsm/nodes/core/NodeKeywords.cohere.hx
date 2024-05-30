class NodeKeywords {
	public var keywords:Array<String>;
	public var nodes:Map<String, Dynamic>;
	public var keywordsCallback:Map<String, Function>;

	public function new() {
		this.keywords = [];
		this.nodes = new Map();
		this.keywordsCallback = new Map();
	}

	public function getNode(name:String):Dynamic {
		if (!this.nodes.exists(name) && this.keywordsCallback.exists(name)) {
			let node = this.keywordsCallback.get(name).call(null, name);
			this.nodes.set(name, node);
		}
		return this.nodes.get(name);
	}

	public function addKeyword(name:String, callback:Function):Void {
		this.keywords.push(name);
		this.keywordsCallback.set(name, callback);
	}

	public function parse(code:String):Array<Dynamic> {
		var keywordNames = this.keywords.join('|');
		var regExp = ~'\\b' + keywordNames + '\\b';
		var codeKeywords = code.match(regExp);
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
		for (node in keywordNodes) {
			node.build(builder);
		}
	}
}