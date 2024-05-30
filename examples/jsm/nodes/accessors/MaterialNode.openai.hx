package three.js.examples.jsm.nodes.accessors;

import Node from '../core/Node.hx';
import ReferenceNode from './ReferenceNode.hx';
import MaterialReferenceNode from './MaterialReferenceNode.hx';
import NormalNode from './NormalNode.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import UniformNode from '../core/UniformNode.hx';
import Vector2 from 'three';

class MaterialNode extends Node {
  private var _propertyCache:Map<String, Node>;

  public function new(scope:Dynamic) {
    super();
    this.scope = scope;
    _propertyCache = new Map<String, Node>();
  }

  public function getCache(property:String, type:String):Node {
    var node:Node = _propertyCache.get(property);
    if (node == null) {
      node = materialReference(property, type);
      _propertyCache.set(property, node);
    }
    return node;
  }

  public function getFloat(property:String):Node {
    return getCache(property, 'float');
  }

  public function getColor(property:String):Node {
    return getCache(property, 'color');
  }

  public function getTexture(property:String):Node {
    return getCache(property == 'map' ? 'map' : property + 'Map', 'texture');
  }

  public function setup(builder:Dynamic):Node {
    var material:Dynamic = builder.context.material;
    var scope:Dynamic = this.scope;
    var node:Node = null;

    // ... (rest of the setup function remains the same)

    return node;
  }
}

// static constants
MaterialNode.ALPHA_TEST = 'alphaTest';
MaterialNode.COLOR = 'color';
MaterialNode.OPACITY = 'opacity';
// ... (rest of the static constants remain the same)

// exported nodes
var materialAlphaTest:Node = nodeImmutable(MaterialNode, MaterialNode.ALPHA_TEST);
var materialColor:Node = nodeImmutable(MaterialNode, MaterialNode.COLOR);
// ... (rest of the exported nodes remain the same)

// add node class
Node.addNodeClass('MaterialNode', MaterialNode);