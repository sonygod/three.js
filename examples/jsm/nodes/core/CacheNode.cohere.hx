import Node from './Node.hx';
import NodeCache from './NodeCache.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class CacheNode extends Node {
	public isCacheNode: Bool;
	public node: Node;
	public cache: NodeCache;

	public function new(node: Node, cache: NodeCache = new NodeCache()) {
		super();
		this.isCacheNode = true;
		this.node = node;
		this.cache = cache;
	}

	public function getNodeType(builder: Dynamic): Dynamic {
		return this.node.getNodeType(builder);
	}

	public function build(builder: Dynamic, ...params): Dynamic {
		var previousCache = builder.getCache();
		var cacheToUse = if (this.cache != null) this.cache else builder.globalCache;
		builder.setCache(cacheToUse);
		var data = this.node.build(builder, ...params);
		builder.setCache(previousCache);
		return data;
	}
}

@:enum(false)
class CacheNodeEnums {
	public static inline var CacheNode: CacheNode = nodeProxy(CacheNode);
	public static inline var globalCache(node: Node): Dynamic = CacheNode(node, null);
}

addNodeElement('cache', CacheNodeEnums.CacheNode);
addNodeElement('globalCache', CacheNodeEnums.globalCache);
addNodeClass('CacheNode', CacheNode);