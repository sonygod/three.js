import haxe.Serializer;

class RenderObject {
    private _nodes:Nodes;
    private _geometries:Geometries;
    private _nodeBuilderState:NodeBuilderState;
    private _bindings:Bindings;
    private id:Int;
    private renderer:Renderer;
    private object:Dynamic;
    private material:Dynamic;
    private scene:Dynamic;
    private camera:Dynamic;
    private lightsNode:Dynamic;
    private context:RenderContext;
    private geometry:Dynamic;
    private version:Dynamic;
    private drawRange:Dynamic;
    private attributes:Array<Dynamic>;
    private pipeline:Dynamic;
    private vertexBuffers:Array<Dynamic>;
    private clippingContext:ClippingContext;
    private clippingContextVersion:Dynamic;
    private initialNodesCacheKey:String;
    private initialCacheKey:String;
    private onDispose:Dynamic;
    private onMaterialDispose:Dynamic->Void;
    private isRenderObject:Bool;

    public function new(nodes:Nodes, geometries:Geometries, renderer:Renderer, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, context:RenderContext) {
        _nodes = nodes;
        _geometries = geometries;
        id = ++id;
        renderer = renderer;
        object = object;
        material = material;
        scene = scene;
        camera = camera;
        lightsNode = lightsNode;
        context = context;
        geometry = object.geometry;
        version = material.version;
        drawRange = null;
        attributes = null;
        pipeline = null;
        vertexBuffers = null;
        clippingContext = context.clippingContext;
        clippingContextVersion = clippingContext.version;
        initialNodesCacheKey = getNodesCacheKey();
        initialCacheKey = getCacheKey();
        _nodeBuilderState = null;
        _bindings = null;
        onDispose = null;
        isRenderObject = true;
        onMaterialDispose = function() {
            dispose();
        };
        material.addEventListener('dispose', onMaterialDispose);
    }

    public function updateClipping(parent:Dynamic) {
        var material = this.material;
        var clippingContext = this.clippingContext;

        if (material.clippingPlanes != null) {
            if (clippingContext == parent || clippingContext == null) {
                clippingContext = new ClippingContext();
                this.clippingContext = clippingContext;
            }

            clippingContext.update(parent, material);
        } else if (this.clippingContext != parent) {
            this.clippingContext = parent;
        }
    }

    public function get clippingNeedsUpdate():Bool {
        if (clippingContextVersion == clippingContext.version) {
            return false;
        }

        clippingContextVersion = clippingContext.version;
        return true;
    }

    public function getNodeBuilderState():NodeBuilderState {
        if (_nodeBuilderState == null) {
            _nodeBuilderState = _nodes.getForRender(this);
        }

        return _nodeBuilderState;
    }

    public function getBindings():Bindings {
        if (_bindings == null) {
            _bindings = getNodeBuilderState().createBindings();
        }

        return _bindings;
    }

    public function getIndex():Int {
        return _geometries.getIndex(this);
    }

    public function getChainArray():Array<Dynamic> {
        return [object, material, context, lightsNode];
    }

    public function getAttributes():Array<Dynamic> {
        if (attributes != null) {
            return attributes;
        }

        var nodeAttributes = getNodeBuilderState().nodeAttributes;
        var geometry = this.geometry;
        var attributes = [];
        var vertexBuffers = new Set();

        for (nodeAttribute in nodeAttributes) {
            var attribute = nodeAttribute.node.attribute != null ? nodeAttribute.node.attribute : geometry.getAttribute(nodeAttribute.name);

            if (attribute == null) {
                continue;
            }

            attributes.push(attribute);

            var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
            vertexBuffers.add(bufferAttribute);
        }

        this.attributes = attributes;
        this.vertexBuffers = Array.from(vertexBuffers.values());
        return attributes;
    }

    public function getVertexBuffers():Array<Dynamic> {
        if (vertexBuffers == null) {
            getAttributes();
        }

        return vertexBuffers;
    }

    public function getMaterialCacheKey():String {
        var object = this.object;
        var material = this.material;
        var cacheKey = material.customProgramCacheKey();

        var keys = getKeys(material);
        for (key in keys) {
            if (key.match(/^(is[A-Z]|_)|^(visible|version|uuid|name|opacity|userData)$/) != null) {
                continue;
            }

            var value = material[$key];

            if (value != null) {
                var type = typeof(value);

                if (type == 'Number') {
                    value = value != 0 ? '1' : '0';
                } else if (type == 'Object') {
                    value = '{}';
                }
            }

            cacheKey += $key + ':' + value + ',';
        }

        cacheKey += clippingContextVersion + ',';

        if (object.skeleton != null) {
            cacheKey += object.skeleton.bones.length + ',';
        }

        if (object.morphTargetInfluences != null) {
            cacheKey += object.morphTargetInfluences.length + ',';
        }

        if (object.isBatchedMesh != null) {
            cacheKey += object._matricesTexture.uuid + ',';
            cacheKey += object._colorsTexture.uuid + ',';
        }

        return cacheKey;
    }

    public function get needsUpdate():Bool {
        return initialNodesCacheKey != getNodesCacheKey() || clippingNeedsUpdate;
    }

    public function getNodesCacheKey():String {
        return _nodes.getCacheKey(scene, lightsNode);
    }

    public function getCacheKey():String {
        return getMaterialCacheKey() + ',' + getNodesCacheKey();
    }

    public function dispose() {
        material.removeEventListener('dispose', onMaterialDispose);
        onDispose();
    }
}

function getKeys(obj:Dynamic):Array<String> {
    var keys = Reflect.fields(obj);
    var proto = Reflect.field(obj, '__proto__');

    while (proto != null) {
        var descriptors = Reflect.fields(proto);
        for (descriptor in descriptors) {
            if (descriptors[$descriptor] != null && descriptors[$descriptor].get != null) {
                keys.push($descriptor);
            }
        }

        proto = Reflect.field(proto, '__proto__');
    }

    return keys;
}