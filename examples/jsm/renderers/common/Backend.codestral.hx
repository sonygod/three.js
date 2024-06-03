import js.Browser.document;
import js.html.CanvasElement;
import js.html.HTMLCanvasElement;

import Color4;
import three.Vector2;
import three.Vector4;
import three.REVISION;
import three.createCanvasElement;

class Backend {

    public var parameters:Dynamic;
    public var data:Map<Dynamic, Dynamic>;
    public var renderer:Dynamic;
    public var domElement:CanvasElement;

    public function new(parameters:Dynamic = null) {
        this.parameters = (parameters != null) ? parameters : {};
        this.data = new Map<Dynamic, Dynamic>();
        this.renderer = null;
        this.domElement = null;
    }

    public function init(renderer:Dynamic) {
        this.renderer = renderer;
    }

    public function begin(renderContext:Dynamic) {}

    public function finish(renderContext:Dynamic) {}

    public function draw(renderObject:Dynamic, info:Dynamic) {}

    public function createProgram(program:Dynamic) {}

    public function destroyProgram(program:Dynamic) {}

    public function createBindings(renderObject:Dynamic) {}

    public function updateBindings(renderObject:Dynamic) {}

    public function createRenderPipeline(renderObject:Dynamic) {}

    public function createComputePipeline(computeNode:Dynamic, pipeline:Dynamic) {}

    public function destroyPipeline(pipeline:Dynamic) {}

    public function needsRenderUpdate(renderObject:Dynamic):Bool {
        return false; // replace with actual implementation
    }

    public function getRenderCacheKey(renderObject:Dynamic):String {
        return ""; // replace with actual implementation
    }

    public function createNodeBuilder(renderObject:Dynamic) {}

    public function createSampler(texture:Dynamic) {}

    public function createDefaultTexture(texture:Dynamic) {}

    public function createTexture(texture:Dynamic) {}

    public function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int) {}

    public function createAttribute(attribute:Dynamic) {}

    public function createIndexAttribute(attribute:Dynamic) {}

    public function updateAttribute(attribute:Dynamic) {}

    public function destroyAttribute(attribute:Dynamic) {}

    public function getContext() {}

    public function updateSize() {}

    public function resolveTimestampAsync(renderContext:Dynamic, type:Dynamic) {}

    public function hasFeatureAsync(name:String):Bool {
        return false; // replace with actual implementation
    }

    public function hasFeature(name:String):Bool {
        return false; // replace with actual implementation
    }

    public function getInstanceCount(renderObject:Dynamic):Int {
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

    public function getDrawingBufferSize():Vector2 {
        return this.renderer.getDrawingBufferSize(new Vector2());
    }

    public function getScissor():Vector4 {
        return this.renderer.getScissor(new Vector4());
    }

    public function setScissorTest(boolean:Bool) {}

    public function getClearColor():Color4 {
        var renderer = this.renderer;
        var color4 = new Color4();

        renderer.getClearColor(color4);
        color4.getRGB(color4, renderer.currentColorSpace);

        return color4;
    }

    public function getDomElement():CanvasElement {
        if (this.domElement == null) {
            this.domElement = (this.parameters.canvas != null) ? this.parameters.canvas : createCanvasElement();

            if (Std.is(this.domElement, HTMLCanvasElement)) {
                this.domElement.setAttribute('data-engine', `three.js r${REVISION} webgpu`);
            }
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
        return this.data.exists(object);
    }

    public function delete(object:Dynamic) {
        this.data.remove(object);
    }

}