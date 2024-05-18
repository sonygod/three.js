package three.js.examples.jsm.nodes.core;

import Node;
import NodeCache;

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
        var previousCache = builder.getCache();
        var cache = this.cache != null ? this.cache : builder.globalCache;
        builder.setCache(cache);
        var data = node.build(builder, params);
        builder.setCache(previousCache);
        return data;
    }

}

// exports
var cache = nodeProxy(CacheNode);
var globalCache = function(node:Node) return cache(node, null);

Node.addElement("cache", cache);
Node.addElement("globalCache", globalCache);

Node.addClass("CacheNode", CacheNode);