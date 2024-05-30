import Node;
import NodeCache;
import ShaderNode;

class CacheNode extends Node {

	public function new(node:Node, cache:NodeCache = new NodeCache()) {
		super();

		this.isCacheNode = true;

		this.node = node;
		this.cache = cache;
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		return this.node.getNodeType(builder);
	}

	public function build(builder:ShaderNode.Builder, params:Array<Dynamic>):Dynamic {
		var previousCache = builder.getCache();
		var cache = this.cache ? this.cache : builder.globalCache;

		builder.setCache(cache);

		var data = this.node.build(builder, params);

		builder.setCache(previousCache);

		return data;
	}

}

static function cache(node:Node, cache:NodeCache):CacheNode {
	return new CacheNode(node, cache);
}

static function globalCache(node:Node):CacheNode {
	return cache(node, null);
}

ShaderNode.addNodeElement('cache', cache);
ShaderNode.addNodeElement('globalCache', globalCache);

Node.addNodeClass('CacheNode', CacheNode);