import Color4.Color4;
import Vector2.Vector2;
import Vector4.Vector4;
import WeakMap.WeakMap;
import three.REVISION;
import three.createCanvasElement;

class Backend {
    var vector2:Null<Vector2>;
    var vector4:Null<Vector4>;
    var color4:Null<Color4>;
    var parameters:Dynamic;
    var data:WeakMap<Dynamic, Dynamic>;
    var renderer:Null<Dynamic>;
    var domElement:Null<Dynamic>;

    public function new(parameters:Dynamic = {}) {
        this.parameters = parameters;
        this.data = new WeakMap<Dynamic, Dynamic>();
        this.renderer = null;
        this.domElement = null;
    }

    public async function init(renderer:Dynamic) {
        this.renderer = renderer;
    }

    public function begin(renderContext:Dynamic) { }

    public function finish(renderContext:Dynamic) { }

    public function draw(renderObject:Dynamic, info:Dynamic) { }

    public function createProgram(program:Dynamic) { }

    public function destroyProgram(program:Dynamic) { }

    public function createBindings(renderObject:Dynamic) { }

    public function updateBindings(renderObject:Dynamic) { }

    public function createRenderPipeline(renderObject:Dynamic) { }

    public function createComputePipeline(computeNode:Dynamic, pipeline:Dynamic) { }

    public function destroyPipeline(pipeline:Dynamic) { }

    public function needsRenderUpdate(renderObject:Dynamic):Bool { }

    public function getRenderCacheKey(renderObject:Dynamic):String { }

    public function createNodeBuilder(renderObject:Dynamic) { }

    public function createSampler(texture:Dynamic) { }

    public function createDefaultTexture(texture:Dynamic) { }

    public function createTexture(texture:Dynamic) { }

    public function copyTextureToBuffer(texture:Dynamic, x:Float, y:Float, width:Float, height:Float) { }

    public function createAttribute(attribute:Dynamic) { }

    public function createIndexAttribute(attribute:Dynamic) { }

    public function updateAttribute(attribute:Dynamic) { }

    public function destroyAttribute(attribute:Dynamic) { }

    public function getContext() { }

    public function updateSize() { }

    public function resolveTimestampAsync(renderContext:Dynamic, type:Dynamic) { }

    public function hasFeatureAsync(name:String):Bool { }

    public function hasFeature(name:String):Bool { }

    public function getInstanceCount(renderObject:Dynamic):Int {
        var object = renderObject.object;
        var geometry = renderObject.geometry;

        return if (geometry.isInstancedBufferGeometry) geometry.instanceCount else if (object.isInstancedMesh) object.count else 1;
    }

    public function getDrawingBufferSize():Vector2 {
        if (this.vector2 == null) this.vector2 = new Vector2();

        return this.renderer.getDrawingBufferSize(this.vector2);
    }

    public function getScissor():Vector4 {
        if (this.vector4 == null) this.vector4 = new Vector4();

        return this.renderer.getScissor(this.vector4);
    }

    public function setScissorTest(boolean:Bool) { }

    public function getClearColor():Color4 {
        var renderer = this.renderer;

        if (this.color4 == null) this.color4 = new Color4();

        renderer.getClearColor(this.color4);
        this.color4.getRGB(this.color4, this.renderer.currentColorSpace);

        return this.color4;
    }

    public function getDomElement():Dynamic {
        if (this.domElement == null) {
            this.domElement = if (this.parameters.canvas != null) this.parameters.canvas else createCanvasElement();

            if ("setAttribute" in this.domElement) this.domElement.setAttribute("data-engine", `three.js r${REVISION} webgpu`);
        }

        return this.domElement;
    }

    public function set(object:Dynamic, value:Dynamic) {
        this.data.set(object, value);
    }

    public function get(object:Dynamic):Dynamic {
        var map = this.data.get(object);

        if (map == null) {
            map = {};
            this.data.set(object, map);
        }

        return map;
    }

    public function has(object:Dynamic):Bool {
        return this.data.has(object);
    }

    public function delete(object:Dynamic) {
        this.data.delete(object);
    }
}