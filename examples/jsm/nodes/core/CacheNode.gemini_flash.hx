import Node from "./Node";
import NodeCache from "./NodeCache";
import ShaderNode from "../shadernode/ShaderNode";

class CacheNode extends Node {
  public isCacheNode:Bool = true;
  public node:Node;
  public cache:NodeCache;

  public function new(node:Node, cache:NodeCache = new NodeCache()) {
    super();
    this.node = node;
    this.cache = cache;
  }

  public function getNodeType(builder:Dynamic):Dynamic {
    return this.node.getNodeType(builder);
  }

  public function build(builder:Dynamic, params:Array<Dynamic>):Dynamic {
    var previousCache = builder.getCache();
    var cache = this.cache != null ? this.cache : builder.globalCache;

    builder.setCache(cache);
    var data = this.node.build(builder, params);
    builder.setCache(previousCache);

    return data;
  }
}

class CacheNodeProxy extends ShaderNode {
  public function new(node:Node, cache:NodeCache = null) {
    super(new CacheNode(node, cache));
  }
}

var cache = new CacheNodeProxy;
var globalCache = function(node:Node):ShaderNode {
  return new CacheNodeProxy(node, null);
};

ShaderNode.addNodeElement("cache", cache);
ShaderNode.addNodeElement("globalCache", globalCache);

ShaderNode.addNodeClass("CacheNode", CacheNode);