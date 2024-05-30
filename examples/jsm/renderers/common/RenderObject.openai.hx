package three.js.examples.jm.renderers.common;

import ClippingContext;

class RenderObject {
    static var id:Int = 0;

    function getKeys(obj:Dynamic):Array<String> {
        var keys:Array<String> = [];
        var proto:Dynamic = Reflect.GetObjectPrototypeOf(obj);

        while (proto != null) {
            var descriptors:Dynamic = Reflect.GetOwnPropertyDescriptors(proto);

            for (key in descriptors.keys()) {
                if (descriptors[key] != null) {
                    var descriptor:Dynamic = descriptors[key];

                    if (descriptor != null && Reflect.isFunction(descriptor.get)) {
                        keys.push(key);
                    }
                }
            }

            proto = Reflect.GetObjectPrototypeOf(proto);
        }

        return keys;
    }

    public var _nodes:Dynamic;
    public var _geometries:Dynamic;

    public var id:Int;
    public var renderer:Dynamic;
    public var object:Dynamic;
    public var material:Dynamic;
    public var scene:Dynamic;
    public var camera:Dynamic;
    public var lightsNode:Dynamic;
    public var context:Dynamic;

    public var geometry:Dynamic;
    public var version:Dynamic;

    public var drawRange:Dynamic;
    public var attributes:Dynamic;
    public var pipeline:Dynamic;
    public var vertexBuffers:Dynamic;

    public var clippingContext:ClippingContext;
    public var clippingContextVersion:Dynamic;

    public var initialNodesCacheKey:Dynamic;
    public var initialCacheKey:Dynamic;

    public var _nodeBuilderState:Dynamic;
    public var _bindings:Dynamic;

    public var onDispose:Dynamic;

    public var isRenderObject:Bool = true;

    public function new(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic) {
        _nodes = nodes;
        _geometries = geometries;

        id = id++;

        this.renderer = renderer;
        this.object = object;
        this.material = material;
        this.scene = scene;
        this.camera = camera;
        this.lightsNode = lightsNode;
        this.context = renderContext;

        geometry = object.geometry;
        version = material.version;

        drawRange = null;

        attributes = null;
        pipeline = null;
        vertexBuffers = null;

        updateClipping(renderContext.clippingContext);

        clippingContextVersion = clippingContext.version;

        initialNodesCacheKey = getNodesCacheKey();
        initialCacheKey = getCacheKey();

        _nodeBuilderState = null;
        _bindings = null;

        onDispose = null;

        material.addEventListener('dispose', onMaterialDispose);

        function onMaterialDispose() {
            dispose();
        }
    }

    public function updateClipping(parent:Dynamic) {
        var material:Dynamic = this.material;

        var clippingContext:ClippingContext = this.clippingContext;

        if (Std.isOfType(material.clippingPlanes, Array)) {
            if (clippingContext == parent || clippingContext == null) {
                clippingContext = new ClippingContext();
                this.clippingContext = clippingContext;
            }

            clippingContext.update(parent, material);
        } else if (this.clippingContext != parent) {
            this.clippingContext = parent;
        }
    }

    public function get_clippingNeedsUpdate():Bool {
        if (clippingContext.version == clippingContextVersion) return false;

        clippingContextVersion = clippingContext.version;

        return true;
    }

    public function getNodeBuilderState():Dynamic {
        return _nodeBuilderState != null ? _nodeBuilderState : (_nodeBuilderState = _nodes.getForRender(this));
    }

    public function getBindings():Dynamic {
        return _bindings != null ? _bindings : (_bindings = getNodeBuilderState().createBindings());
    }

    public function getIndex():Dynamic {
        return _geometries.getIndex(this);
    }

    public function getChainArray():Array<Dynamic> {
        return [object, material, context, lightsNode];
    }

    public function getAttributes():Array<Dynamic> {
        if (attributes != null) return attributes;

        var nodeAttributes:Array<Dynamic> = getNodeBuilderState().nodeAttributes;
        var geometry:Dynamic = this.geometry;

        var attributes:Array<Dynamic> = [];
        var vertexBuffers:Set<Dynamic> = new Set();

        for (nodeAttribute in nodeAttributes) {
            var attribute:Dynamic = nodeAttribute.node != null && nodeAttribute.node.attribute != null ? nodeAttribute.node.attribute : geometry.getAttribute(nodeAttribute.name);

            if (attribute == null) continue;

            attributes.push(attribute);

            var bufferAttribute:Dynamic = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
            vertexBuffers.add(bufferAttribute);
        }

        this.attributes = attributes;
        this.vertexBuffers = Array.from(vertexBuffers.values());

        return attributes;
    }

    public function getVertexBuffers():Array<Dynamic> {
        if (vertexBuffers == null) getAttributes();

        return vertexBuffers;
    }

    public function getMaterialCacheKey():String {
        var material:Dynamic = this.material;

        var cacheKey:String = material.customProgramCacheKey();

        for (property in getKeys(material)) {
            if (~['is[A-Z]', '_', 'visible', 'version', 'uuid', 'name', 'opacity', 'userData'].map(RegExp => new EReg(RegExp, 'g')).indexOf(new EReg(property, 'g')) != -1) continue;

            var value:Dynamic = material[property];

            if (value != null) {
                var type:Dynamic = Type.getType(value);

                if (type == ValueType.TInt || type == ValueType.TFloat) value = value != 0 ? '1' : '0';
                else if (type == ValueType.TObject) value = '{}';
            }

            cacheKey += /*property + ':' +*/ value + ',';
        }

        cacheKey += clippingContextVersion + ',';

        if (object.skeleton != null) {
            cacheKey += object.skeleton.bones.length + ',';
        }

        if (object.morphTargetInfluences != null) {
            cacheKey += object.morphTargetInfluences.length + ',';
        }

        if (object.isBatchedMesh) {
            cacheKey += object._matricesTexture.uuid + ',';
            cacheKey += object._colorsTexture.uuid + ',';
        }

        return cacheKey;
    }

    public function get_needsUpdate():Bool {
        return initialNodesCacheKey != getNodesCacheKey() || clippingNeedsUpdate;
    }

    public function getNodesCacheKey():Dynamic {
        return _nodes.getCacheKey(scene, lightsNode);
    }

    public function getCacheKey():String {
        return getMaterialCacheKey() + ',' + getNodesCacheKey();
    }

    public function dispose() {
        material.removeEventListener('dispose', onMaterialDispose);

        if (onDispose != null) onDispose();
    }
}