import Node from './Node';
import NodeCache from './NodeCache';
import ShaderNode from '../shadernode/ShaderNode';

class CacheNode extends Node {

    public var node: Node;
    public var cache: NodeCache;

    public function new(node: Node, cache: NodeCache = null) {
        super();
        this.isCacheNode = true;
        if (cache == null) cache = new NodeCache();
        this.node = node;
        this.cache = cache;
    }

    public function getNodeType(builder: Builder): String {
        return this.node.getNodeType(builder);
    }

    public function build(builder: Builder, params: Dynamic...): Dynamic {
        var previousCache = builder.getCache();
        var cache = this.cache != null ? this.cache : builder.globalCache;

        builder.setCache(cache);

        var data = this.node.build(builder, params);

        builder.setCache(previousCache);

        return data;
    }

}

function cache(node: Node, cache: NodeCache = null): Node {
    return ShaderNode.nodeProxy(CacheNode, node, cache);
}

function globalCache(node: Node): Node {
    return cache(node, null);
}

ShaderNode.addNodeElement('cache', cache);
ShaderNode.addNodeElement('globalCache', globalCache);

Node.addNodeClass('CacheNode', CacheNode);