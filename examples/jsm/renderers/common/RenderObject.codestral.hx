import ClippingContext;
import EventDispatcher;

class RenderObject {

    var id: Int;
    var _nodes: Dynamic;
    var _geometries: Dynamic;
    var renderer: Dynamic;
    var object: Dynamic;
    var material: EventDispatcher;
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
    var onDispose: Dynamic;
    var isRenderObject: Bool;
    var onMaterialDispose: Void -> Void;

    public function new(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext) {
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
        this.onMaterialDispose = () => {
            this.dispose();
        };
        this.material.addEventListener('dispose', this.onMaterialDispose);
    }

    public function updateClipping(parent: ClippingContext) {
        if (Array.isArray(this.material.clippingPlanes)) {
            if (this.clippingContext === parent || this.clippingContext == null) {
                this.clippingContext = new ClippingContext();
            }
            this.clippingContext.update(parent, this.material);
        } else if (this.clippingContext !== parent) {
            this.clippingContext = parent;
        }
    }

    public inline function get clippingNeedsUpdate(): Bool {
        if (this.clippingContext.version === this.clippingContextVersion) return false;
        this.clippingContextVersion = this.clippingContext.version;
        return true;
    }

    public function getNodeBuilderState(): Dynamic {
        if (this._nodeBuilderState == null) {
            this._nodeBuilderState = this._nodes.getForRender(this);
        }
        return this._nodeBuilderState;
    }

    public function getBindings(): Dynamic {
        if (this._bindings == null) {
            this._bindings = this.getNodeBuilderState().createBindings();
        }
        return this._bindings;
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
        var vertexBuffers = new haxe.ds.StringMap<Dynamic>();
        for (attribute in nodeAttributes) {
            var attribute1 = attribute.node != null && attribute.node.attribute != null ? attribute.node.attribute : geometry.getAttribute(attribute.name);
            if (attribute1 == null) continue;
            attributes.push(attribute1);
            var bufferAttribute = attribute1.isInterleavedBufferAttribute ? attribute1.data : attribute1;
            vertexBuffers.set(Std.string(bufferAttribute), bufferAttribute);
        }
        this.attributes = attributes;
        this.vertexBuffers = [];
        for (value in vertexBuffers.iterator()) {
            this.vertexBuffers.push(value.value);
        }
        return attributes;
    }

    public function getVertexBuffers(): Array<Dynamic> {
        if (this.vertexBuffers == null) this.getAttributes();
        return this.vertexBuffers;
    }

    public function getMaterialCacheKey(): String {
        var cacheKey = this.material.customProgramCacheKey();
        var properties = Type.getInstanceFields(this.material.getClass());
        for (property in properties) {
            if (new EReg("/^(is[A-Z]|_)|^(visible|version|uuid|name|opacity|userData)$/").match(property)) continue;
            var value = Reflect.field(this.material, property);
            if (value != null) {
                var type = Type.typeof(value);
                if (type == Int || type == Float) value = value != 0 ? '1' : '0';
                else if (type == Class) value = '{}';
            }
            cacheKey += value + ',';
        }
        cacheKey += this.clippingContextVersion + ',';
        if (this.object.skeleton != null) {
            cacheKey += this.object.skeleton.bones.length + ',';
        }
        if (this.object.morphTargetInfluences != null) {
            cacheKey += this.object.morphTargetInfluences.length + ',';
        }
        if (this.object.isBatchedMesh) {
            cacheKey += this.object._matricesTexture.uuid + ',';
            cacheKey += this.object._colorsTexture.uuid + ',';
        }
        return cacheKey;
    }

    public inline function get needsUpdate(): Bool {
        return this.initialNodesCacheKey !== this.getNodesCacheKey() || this.clippingNeedsUpdate;
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

var id = 0;

function getKeys(obj: Dynamic): Array<String> {
    var keys = Reflect.fields(obj);
    var proto = Type.getSuperClass(Type.getClass(obj));
    while (proto != null) {
        var descriptors = Type.getProperties(proto);
        for (key in descriptors) {
            if (Reflect.field(descriptors, key) != null) {
                var descriptor = Reflect.field(descriptors, key);
                if (descriptor != null && descriptor.get != null) {
                    keys.push(key);
                }
            }
        }
        proto = Type.getSuperClass(proto);
    }
    return keys;
}