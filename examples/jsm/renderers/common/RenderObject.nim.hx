import ClippingContext from './ClippingContext.hx';

var id = 0;

function getKeys(obj: Dynamic): Array<String> {
  var keys = Reflect.fields(obj);
  var proto = Reflect.getProperty(obj, '__proto__');
  while (proto != null) {
    for (key in Reflect.fields(proto)) {
      if (Reflect.hasField(proto, key) && Reflect.isFunction(Reflect.field(proto, key))) {
        keys.push(key);
      }
    }
    proto = Reflect.getProperty(proto, '__proto__');
  }
  return keys;
}

class RenderObject {
  var _nodes: Dynamic;
  var _geometries: Dynamic;
  var renderer: Dynamic;
  var object: Dynamic;
  var material: Dynamic;
  var scene: Dynamic;
  var camera: Dynamic;
  var lightsNode: Dynamic;
  var context: Dynamic;
  var geometry: Dynamic;
  var version: Dynamic;
  var drawRange: Null<Dynamic>;
  var attributes: Null<Array<Dynamic>>;
  var pipeline: Null<Dynamic>;
  var vertexBuffers: Null<Array<Dynamic>>;
  var clippingContext: ClippingContext;
  var clippingContextVersion: Int;
  var initialNodesCacheKey: String;
  var initialCacheKey: String;
  var _nodeBuilderState: Null<Dynamic>;
  var _bindings: Null<Dynamic>;
  var onDispose: Null<Dynamic>;
  var isRenderObject: Bool;
  var onMaterialDispose: Void->Void;

  public function new(nodes: Dynamic, geometries: Dynamic, renderer: Dynamic, object: Dynamic, material: Dynamic, scene: Dynamic, camera: Dynamic, lightsNode: Dynamic, renderContext: Dynamic) {
    this._nodes = nodes;
    this._geometries = geometries;
    this.id = id++;
    this.renderer = renderer;
    this.object = object;
    this.material = material;
    this.scene = scene;
    this.camera = camera;
    this.lightsNode = lightsNode;
    this.context = renderContext;
    this.geometry = object.geometry;
    this.version = material.version;
    this.drawRange = null;
    this.attributes = null;
    this.pipeline = null;
    this.vertexBuffers = null;
    this.updateClipping(renderContext.clippingContext);
    this.clippingContextVersion = this.clippingContext.version;
    this.initialNodesCacheKey = this.getNodesCacheKey();
    this.initialCacheKey = this.getCacheKey();
    this._nodeBuilderState = null;
    this._bindings = null;
    this.onDispose = null;
    this.isRenderObject = true;
    this.onMaterialDispose = function() {
      this.dispose();
    };
    material.addEventListener('dispose', this.onMaterialDispose);
  }

  public function updateClipping(parent: ClippingContext): Void {
    var material = this.material;
    var clippingContext = this.clippingContext;
    if (Type.getClassName(material.clippingPlanes) == 'Array') {
      if (clippingContext == parent || clippingContext == null) {
        clippingContext = new ClippingContext();
        this.clippingContext = clippingContext;
      }
      clippingContext.update(parent, material);
    } else if (this.clippingContext != parent) {
      this.clippingContext = parent;
    }
  }

  public function get clippingNeedsUpdate(): Bool {
    if (this.clippingContext.version == this.clippingContextVersion) return false;
    this.clippingContextVersion = this.clippingContext.version;
    return true;
  }

  public function getNodeBuilderState(): Dynamic {
    return this._nodeBuilderState ?? (this._nodeBuilderState = this._nodes.getForRender(this));
  }

  public function getBindings(): Dynamic {
    return this._bindings ?? (this._bindings = this.getNodeBuilderState().createBindings());
  }

  public function getIndex(): Dynamic {
    return this._geometries.getIndex(this);
  }

  public function getChainArray(): Array<Dynamic> {
    return [this.object, this.material, this.context, this.lightsNode];
  }

  public function getAttributes(): Array<Dynamic> {
    if (this.attributes != null) return this.attributes;
    var nodeAttributes = this.getNodeBuilderState().nodeAttributes;
    var geometry = this.geometry;
    var attributes = [];
    var vertexBuffers = new Set<Dynamic>();
    for (attribute in nodeAttributes) {
      var nodeAttribute = attribute;
      var attribute = nodeAttribute.node && nodeAttribute.node.attribute ? nodeAttribute.node.attribute : geometry.getAttribute(nodeAttribute.name);
      if (attribute == null) continue;
      attributes.push(attribute);
      var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
      vertexBuffers.add(bufferAttribute);
    }
    this.attributes = attributes;
    this.vertexBuffers = Array.from(vertexBuffers.values());
    return attributes;
  }

  public function getVertexBuffers(): Array<Dynamic> {
    if (this.vertexBuffers == null) this.getAttributes();
    return this.vertexBuffers;
  }

  public function getMaterialCacheKey(): String {
    var object = this.object;
    var material = this.material;
    var cacheKey = material.customProgramCacheKey();
    for (property in getKeys(material)) {
      var key = property;
      if (/^(is[A-Z]|_)|^(visible|version|uuid|name|opacity|userData)$/.test(key)) continue;
      var value = material[key];
      if (value != null) {
        var type = Type.typeof(value);
        if (type == 'number') value = value != 0 ? '1' : '0';
        else if (type == 'object') value = '{}';
      }
      cacheKey += /*property + ':' +*/ value + ',';
    }
    cacheKey += this.clippingContextVersion + ',';
    if (object.skeleton) {
      cacheKey += object.skeleton.bones.length + ',';
    }
    if (object.morphTargetInfluences) {
      cacheKey += object.morphTargetInfluences.length + ',';
    }
    if (object.isBatchedMesh) {
      cacheKey += object._matricesTexture.uuid + ',';
      cacheKey += object._colorsTexture.uuid + ',';
    }
    return cacheKey;
  }

  public function get needsUpdate(): Bool {
    return this.initialNodesCacheKey != this.getNodesCacheKey() || this.clippingNeedsUpdate;
  }

  public function getNodesCacheKey(): String {
    return this._nodes.getCacheKey(this.scene, this.lightsNode);
  }

  public function getCacheKey(): String {
    return this.getMaterialCacheKey() + ',' + this.getNodesCacheKey();
  }

  public function dispose(): Void {
    this.material.removeEventListener('dispose', this.onMaterialDispose);
    this.onDispose();
  }
}