package;

class Backend {
    var parameters: { default, null } = { null };
    var data: WeakMap<Dynamic, Map<String, Dynamic>>;
    var renderer: null;
    var domElement: null;

    public function new(parameters: { default, null } = { null }) {
        this.parameters = parameters ? parameters : { null };
        this.data = new WeakMap<Dynamic, Map<String, Dynamic>>();
        this.renderer = null;
        this.domElement = null;
    }

    async function init(renderer: { default, null }) {
        this.renderer = renderer;
    }

    function begin(renderContext: Dynamic) { }

    function finish(renderContext: Dynamic) { }

    function draw(renderObject: Dynamic, info: Dynamic) { }

    function createProgram(program: Dynamic) { }

    function destroyProgram(program: Dynamic) { }

    function createBindings(renderObject: Dynamic) { }

    function updateBindings(renderObject: Dynamic) { }

    function createRenderPipeline(renderObject: Dynamic) { }

    function createComputePipeline(computeNode: Dynamic, pipeline: Dynamic) { }

    function destroyPipeline(pipeline: Dynamic) { }

    function needsRenderUpdate(renderObject: Dynamic): Bool {
        return false;
    }

    function getRenderCacheKey(renderObject: Dynamic): String {
        return "";
    }

    function createNodeBuilder(renderObject: Dynamic): Dynamic {
        return null;
    }

    function createSampler(texture: Dynamic) { }

    function createDefaultTexture(texture: Dynamic) { }

    function createTexture(texture: Dynamic) { }

    function copyTextureToBuffer(texture: Dynamic, x: Int, y: Int, width: Int, height: Int) { }

    function createAttribute(attribute: Dynamic) { }

    function createIndexAttribute(attribute: Dynamic) { }

    function updateAttribute(attribute: Dynamic) { }

    function destroyAttribute(attribute: Dynamic) { }

    function getContext(): Dynamic {
        return null;
    }

    function updateSize() { }

    function resolveTimestampAsync(renderContext: Dynamic, type: Dynamic) { }

    async function hasFeatureAsync(name: String): Bool {
        return false;
    }

    function hasFeature(name: String): Bool {
        return false;
    }

    function getInstanceCount(renderObject: Dynamic): Int {
        var object = renderObject.object;
        var geometry = renderObject.geometry;
        if (geometry.isInstancedBufferGeometry) {
            return geometry.instanceCount;
        } else if (object.isInstancedMesh) {
            return object.count;
        } else {
            return 1;
        }
    }

    function getDrawingBufferSize(): Dynamic {
        var vector2 = new Vector2();
        return this.renderer.getDrawingBufferSize(vector2);
    }

    function getScissor(): Dynamic {
        var vector4 = new Vector4();
        return this.renderer.getScissor(vector4);
    }

    function setScissorTest(boolean: Bool) { }

    function getClearColor(): Dynamic {
        var renderer = this.renderer;
        var color4 = new Color4();
        renderer.getClearColor(color4);
        color4.getRGB(color4, renderer.currentColorSpace);
        return color4;
    }

    function getDomElement(): Dynamic {
        if (this.domElement == null) {
            this.domElement = if (this.parameters.canvas != null) this.parameters.canvas else createCanvasElement();
            if (Reflect.hasField(this.domElement, "setAttribute")) {
                this.domElement.setAttribute("data-engine", "three.js r" + REVISION + " webgpu");
            }
            this.domElement;
        }
    }

    function set(object: Dynamic, value: Dynamic) {
        this.data.set(object, value);
    }

    function get(object: Dynamic): Map<String, Dynamic> {
        var map = this.data.get(object);
        if (map == null) {
            map = new Map();
            this.data.set(object, map);
        }
        return map;
    }

    function has(object: Dynamic): Bool {
        return this.data.has(object);
    }

    function delete(object: Dynamic) {
        this.data.delete(object);
    }
}