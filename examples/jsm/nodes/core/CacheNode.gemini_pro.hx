import Node from "./Node";
import NodeCache from "./NodeCache";
import ShaderNode from "../shadernode/ShaderNode";

class CacheNode extends Node {

	public var isCacheNode:Bool = true;
	public var node:Node;
	public var cache:NodeCache;

	public function new(node:Node, cache:NodeCache = new NodeCache()) {
		super();
		this.node = node;
		this.cache = cache;
	}

	public function getNodeType(builder:Dynamic):String {
		return this.node.getNodeType(builder);
	}

	public function build(builder:Dynamic, ...params:Dynamic):Dynamic {
		var previousCache = builder.getCache();
		var cache = this.cache != null ? this.cache : builder.globalCache;
		builder.setCache(cache);
		var data = this.node.build(builder, ...params);
		builder.setCache(previousCache);
		return data;
	}

}

class CacheNodeProxy {
	public static function cache(node:Node, cache:NodeCache = null):CacheNode {
		return new CacheNode(node, cache);
	}

	public static function globalCache(node:Node):CacheNode {
		return cache(node, null);
	}
}

var cache = ShaderNode.nodeProxy(CacheNodeProxy);
var globalCache = CacheNodeProxy.globalCache;

ShaderNode.addNodeElement("cache", cache);
ShaderNode.addNodeElement("globalCache", globalCache);
ShaderNode.addNodeClass("CacheNode", CacheNode);