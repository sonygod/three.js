package three.js.examples.jsc.nodes.core;

import Node;
import NodeCache;
import ShaderNode;

class CacheNode extends Node {

    public var isCacheNode:Bool = true;

    public var node:Node;
    public var cache:NodeCache;

    public function new(node:Node, ?cache:NodeCache) {
        super();
        this.node = node;
        this.cache = cache != null ? cache : new NodeCache();
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return node.getNodeType(builder);
    }

    public function build(builder:Dynamic, params:Array<Dynamic>):Dynamic {
        var previousCache:NodeCache = builder.getCache();
        var cache:NodeCache = this.cache != null ? this.cache : builder.globalCache;
        builder.setCache(cache);
        var data:Dynamic = node.build(builder, params);
        builder.setCache(previousCache);
        return data;
    }

    public static var cache:Node->NodeCache->CacheNode = nodeProxy(CacheNode);
    public static var globalCache:Node->CacheNode = function(node:Node) return cache(node, null);

    static function init() {
        ShaderNode.addNodeElement('cache', cache);
        ShaderNode.addNodeElement('globalCache', globalCache);
        Node.addNodeClass('CacheNode', CacheNode);
    }
}