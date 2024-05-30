package three.js.examples.javascript.backends;

import js.dom.renderers.webgpu.Color4;
import js.three.Vector2;
import js.three.Vector4;
import js.three.REVISION;
import js.three.createCanvasElement;

class Backend {
    var parameters:Dynamic;
    var data:WeakMap<Dynamic, Dynamic>;
    var renderer:js.three.Renderer;
    var domElement:js.html.CanvasElement;

    public function new(?parameters:Dynamic = {}) {
        this.parameters = parameters;
        this.data = new WeakMap();
        this.renderer = null;
        this.domElement = null;
    }

    public function init(renderer:js.three.Renderer):Promise<Void> {
        this.renderer = renderer;
        return Promise.resolve();
    }

    // render context

    public function begin(?renderContext:Dynamic):Void {}

    public function finish(?renderContext:Dynamic):Void {}

    // render object

    public function draw(?renderObject:Dynamic, ?info:Dynamic):Void {}

    // program

    public function createProgram(?program:Dynamic):Void {}

    public function destroyProgram(?program:Dynamic):Void {}

    // bindings

    public function createBindings(?renderObject:Dynamic):Void {}

    public function updateBindings(?renderObject:Dynamic):Void {}

    // pipeline

    public function createRenderPipeline(?renderObject:Dynamic):Void {}

    public function createComputePipeline(?computeNode:Dynamic, ?pipeline:Dynamic):Void {}

    public function destroyPipeline(?pipeline:Dynamic):Void {}

    // cache key

    public function needsRenderUpdate(?renderObject:Dynamic):Bool {
        return false; // default implementation
    }

    public function getRenderCacheKey(?renderObject:Dynamic):String {
        return ""; // default implementation
    }

    // node builder

    public function createNodeBuilder(?renderObject:Dynamic):Dynamic {
        // TODO: implement NodeBuilder
        return null;
    }

    // textures

    public function createSampler(?texture:Dynamic):Void {}

    public function createDefaultTexture(?texture:Dynamic):Void {}

    public function createTexture(?texture:Dynamic):Void {}

    public function copyTextureToBuffer(?texture:Dynamic, x:Int, y:Int, width:Int, height:Int):Void {}

    // attributes

    public function createAttribute(?attribute:Dynamic):Void {}

    public function createIndexAttribute(?attribute:Dynamic):Void {}

    public function updateAttribute(?attribute:Dynamic):Void {}

    public function destroyAttribute(?attribute:Dynamic):Void {}

    // canvas

    public function getContext():js.html.CanvasRenderingContext2D {
        // TODO: implement getContext
        return null;
    }

    public function updateSize():Void {}

    // utils

    public function resolveTimestampAsync(?renderContext:Dynamic, ?type:Dynamic):Promise<Date> {
        return Promise.resolve(new Date());
    }

    public function hasFeatureAsync(?name:Dynamic):Promise<Bool> {
        return Promise.resolve(false); // default implementation
    }

    public function hasFeature(?name:Dynamic):Bool {
        return false; // default implementation
    }

    public function getInstanceCount(?renderObject:Dynamic):Int {
        var object:Dynamic = renderObject.object;
        var geometry:js.three.Geometry = renderObject.geometry;
        return geometry.isInstancedBufferGeometry ? geometry.instanceCount : (object.isInstancedMesh ? object.count : 1);
    }

    public function getDrawingBufferSize():{ width:Int, height:Int } {
        var vector2:js.three.Vector2 = vector2 != null ? vector2 : new js.three.Vector2();
        return this.renderer.getDrawingBufferSize(vector2);
    }

    public function getScissor():{ x:Int, y:Int, width:Int, height:Int } {
        var vector4:js.three.Vector4 = vector4 != null ? vector4 : new js.three.Vector4();
        return this.renderer.getScissor(vector4);
    }

    public function setScissorTest(value:Bool):Void {}

    public function getClearColor():js.three.Color {
        var color4:js.three.Color4 = color4 != null ? color4 : new js.three.Color4();
        this.renderer.getClearColor(color4);
        color4.getRGB(color4, this.renderer.currentColorSpace);
        return color4;
    }

    public function getDomElement():js.html.CanvasElement {
        if (this.domElement == null) {
            this.domElement = this.parameters.canvas != null ? this.parameters.canvas : createCanvasElement();
            if (js.html.SetAttributeExists(this.domElement)) {
                this.domElement.setAttribute('data-engine', 'three.js r${REVISION} webgpu');
            }
        }
        return this.domElement;
    }

    // resource properties

    public function set(?object:Dynamic, ?value:Dynamic):Void {
        this.data.set(object, value);
    }

    public function get(?object:Dynamic):Dynamic {
        var map:Dynamic = this.data.get(object);
        if (map == null) {
            map = {};
            this.data.set(object, map);
        }
        return map;
    }

    public function has(?object:Dynamic):Bool {
        return this.data.has(object);
    }

    public function delete(?object:Dynamic):Void {
        this.data.delete(object);
    }
}