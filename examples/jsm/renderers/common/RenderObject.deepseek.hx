import ClippingContext from './ClippingContext.js';

@:keep
class RenderObject {

    static var id:Int = 0;

    var _nodes:Dynamic;
    var _geometries:Dynamic;

    var id:Int;

    var renderer:Dynamic;
    var object:Dynamic;
    var material:Dynamic;
    var scene:Dynamic;
    var camera:Dynamic;
    var lightsNode:Dynamic;
    var context:Dynamic;

    var geometry:Dynamic;
    var version:Dynamic;

    var drawRange:Dynamic;

    var attributes:Dynamic;
    var pipeline:Dynamic;
    var vertexBuffers:Dynamic;

    var clippingContext:ClippingContext;
    var clippingContextVersion:Dynamic;

    var initialNodesCacheKey:Dynamic;
    var initialCacheKey:Dynamic;

    var _nodeBuilderState:Dynamic;
    var _bindings:Dynamic;

    var onDispose:Dynamic;

    var isRenderObject:Bool = true;

    var onMaterialDispose:Dynamic;

    public function new(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic) {

        this._nodes = nodes;
        this._geometries = geometries;

        this.id = id ++;

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

        this.onMaterialDispose = () -> {
            this.dispose();
        };

        this.material.addEventListener('dispose', this.onMaterialDispose);
    }

    public function updateClipping(parent:Dynamic):Void {

        var material = this.material;

        var clippingContext = this.clippingContext;

        if (Std.is(material.clippingPlanes, Array)) {

            if (clippingContext === parent || !clippingContext) {

                clippingContext = new ClippingContext();
                this.clippingContext = clippingContext;

            }

            clippingContext.update(parent, material);

        } else if (this.clippingContext !== parent) {

            this.clippingContext = parent;

        }
    }

    public function get clippingNeedsUpdate():Bool {

        if (this.clippingContext.version === this.clippingContextVersion) return false;

        this.clippingContextVersion = this.clippingContext.version;

        return true;

    }

    public function getNodeBuilderState():Dynamic {

        return this._nodeBuilderState || (this._nodeBuilderState = this._nodes.getForRender(this));

    }

    public function getBindings():Dynamic {

        return this._bindings || (this._bindings = this.getNodeBuilderState().createBindings());

    }

    public function getIndex():Dynamic {

        return this._geometries.getIndex(this);

    }

    public function getChainArray():Array<Dynamic> {

        return [this.object, this.material, this.context, this.lightsNode];

    }

    public function getAttributes():Array<Dynamic> {

        if (this.attributes !== null) return this.attributes;

        var nodeAttributes = this.getNodeBuilderState().nodeAttributes;
        var geometry = this.geometry;

        var attributes = [];
        var vertexBuffers = new Set();

        for (nodeAttribute in nodeAttributes) {

            var attribute = nodeAttribute.node && nodeAttribute.node.attribute ? nodeAttribute.node.attribute : geometry.getAttribute(nodeAttribute.name);

            if (attribute === undefined) continue;

            attributes.push(attribute);

            var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
            vertexBuffers.add(bufferAttribute);

        }

        this.attributes = attributes;
        this.vertexBuffers = Array.from(vertexBuffers.values());

        return attributes;

    }

    public function getVertexBuffers():Array<Dynamic> {

        if (this.vertexBuffers === null) this.getAttributes();

        return this.vertexBuffers;

    }

    public function getMaterialCacheKey():String {

        var object = this.object;
        var material = this.material;

        var cacheKey = material.customProgramCacheKey();

        for (property in Reflect.fields(material)) {

            if (property.match(/^(is[A-Z]|_)|^(visible|version|uuid|name|opacity|userData)$/)) continue;

            var value = material[property];

            if (value !== null) {

                var type = Std.string(Std.typeof(value));

                if (type === 'number') value = value !== 0 ? '1' : '0'; // Convert to on/off, important for clearcoat, transmission, etc
                else if (type === 'object') value = '{}';

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

    public function get needsUpdate():Bool {

        return this.initialNodesCacheKey !== this.getNodesCacheKey() || this.clippingNeedsUpdate;

    }

    public function getNodesCacheKey():String {

        // Environment Nodes Cache Key

        return this._nodes.getCacheKey(this.scene, this.lightsNode);

    }

    public function getCacheKey():String {

        return this.getMaterialCacheKey() + ',' + this.getNodesCacheKey();

    }

    public function dispose():Void {

        this.material.removeEventListener('dispose', this.onMaterialDispose);

        this.onDispose();

    }

}