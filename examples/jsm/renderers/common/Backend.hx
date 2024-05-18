package three.js.examples.jvm.renderers.common;

import js.html.CanvasElement;
import js.html.webgl.GL;
import three.js.Color4;
import three.js.Vector2;
import three.js.Vector4;

class Backend {
    private var parameters:Dynamic;
    private var data:WeakMap<Dynamic, Dynamic>;
    private var renderer:Null<GL>;
    private var domElement:Null<CanvasElement>;

    public function new(?parameters:Dynamic) {
        this.parameters = parameters != null ? parameters : {};
        this.data = new WeakMap<Dynamic, Dynamic>();
        this.renderer = null;
        this.domElement = null;
    }

    public function init(renderer:GL):Void {
        this.renderer = renderer;
    }

    // render context
    public function begin(renderContext:Dynamic):Void {}

    public function finish(renderContext:Dynamic):Void {}

    // render object
    public function draw(renderObject:Dynamic, info:Dynamic):Void {}

    // program
    public function createProgram(program:Dynamic):Void {}

    public function destroyProgram(program:Dynamic):Void {}

    // bindings
    public function createBindings(renderObject:Dynamic):Void {}

    public function updateBindings(renderObject:Dynamic):Void {}

    // pipeline
    public function createRenderPipeline(renderObject:Dynamic):Void {}

    public function createComputePipeline(computeNode:Dynamic, pipeline:Dynamic):Void {}

    public function destroyPipeline(pipeline:Dynamic):Void {}

    // cache key
    public function needsRenderUpdate(renderObject:Dynamic):Bool {
        return false;
    }

    public function getRenderCacheKey(renderObject:Dynamic):String {
        return "";
    }

    // node builder
    public function createNodeBuilder(renderObject:Dynamic):NodeBuilder {
        // Add implementation
        return null;
    }

    // textures
    public function createSampler(texture:Dynamic):Void {}

    public function createDefaultTexture(texture:Dynamic):Void {}

    public function createTexture(texture:Dynamic):Void {}

    public function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int):Void {}

    // attributes
    public function createAttribute(attribute:Dynamic):Void {}

    public function createIndexAttribute(attribute:Dynamic):Void {}

    public function updateAttribute(attribute:Dynamic):Void {}

    public function destroyAttribute(attribute:Dynamic):Void {}

    // canvas
    public function getContext():GL {
        return null;
    }

    public function updateSize():Void {}

    // utils
    public function resolveTimestampAsync(renderContext:Dynamic, type:Dynamic):Void {}

    public function hasFeatureAsync(name:String):Bool {
        return false;
    }

    public function hasFeature(name:String):Bool {
        return false;
    }

    public function getInstanceCount(renderObject:Dynamic):Int {
        var object:Dynamic = renderObject.object;
        var geometry:Dynamic = renderObject.geometry;
        return geometry.isInstancedBufferGeometry ? geometry.instanceCount : (object.isInstancedMesh ? object.count : 1);
    }

    public function getDrawingBufferSize():Vector2 {
        var vector2:Vector2 = vector2 != null ? vector2 : new Vector2();
        return this.renderer.getDrawingBufferSize(vector2);
    }

    public function getScissor():Vector4 {
        var vector4:Vector4 = vector4 != null ? vector4 : new Vector4();
        return this.renderer.getScissor(vector4);
    }

    public function setScissorTest(boolean:Bool):Void {}

    public function getClearColor():Color4 {
        var renderer:GL = this.renderer;
        var color4:Color4 = color4 != null ? color4 : new Color4();
        renderer.getClearColor(color4);
        color4.getRGB(color4, this.renderer.currentColorSpace);
        return color4;
    }

    public function getDomElement():CanvasElement {
        var domElement:CanvasElement = this.domElement;
        if (domElement == null) {
            domElement = parameters.canvas != null ? parameters.canvas : createCanvasElement();
            // OffscreenCanvas does not have setAttribute, see #22811
            if (Std.is(domElement, { setAttribute: _ })) domElement.setAttribute('data-engine', 'three.js r${REVISION} webgpu');
            this.domElement = domElement;
        }
        return domElement;
    }

    // resource properties
    public function set(object:Dynamic, value:Dynamic):Void {
        this.data.set(object, value);
    }

    public function get(object:Dynamic):Dynamic {
        var map:Dynamic = this.data.get(object);
        if (map == null) {
            map = {};
            this.data.set(object, map);
        }
        return map;
    }

    public function has(object:Dynamic):Bool {
        return this.data.has(object);
    }

    public function delete(object:Dynamic):Void {
        this.data.delete(object);
    }
}

// Note: You need to implement the NodeBuilder class and createCanvasElement function
typedef NodeBuilder = Dynamic;
function createCanvasElement():CanvasElement {
    // Add implementation
    return null;
}