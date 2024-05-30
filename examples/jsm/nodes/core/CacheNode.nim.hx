import Node, { addNodeClass } from './Node.js';
import NodeCache from './NodeCache.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class CacheNode extends Node {

	public var isCacheNode:Bool = true;
	public var node:Node;
	public var cache:NodeCache;

	public function new(node:Node, cache:NodeCache = new NodeCache()) {
		super();
		this.node = node;
		this.cache = cache;
	}

	public function getNodeType(builder:NodeBuilder):NodeType {
		return this.node.getNodeType(builder);
	}

	public function build(builder:NodeBuilder, params:Array<Dynamic>):Dynamic {
		var previousCache:NodeCache = builder.getCache();
		var cache:NodeCache = this.cache ?? builder.globalCache;

		builder.setCache(cache);

		var data:Dynamic = this.node.build(builder, params);

		builder.setCache(previousCache);

		return data;
	}
}

export default CacheNode;

export var cache:NodeProxy = nodeProxy(CacheNode);
export var globalCache:NodeProxy = (node:Node) => cache(node, null);

addNodeElement('cache', cache);
addNodeElement('globalCache', globalCache);

addNodeClass('CacheNode', CacheNode);