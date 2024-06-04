import three.Color4;
import three.Vector2;
import three.Vector4;
import three.REVISION;
import three.createCanvasElement;

class Backend {

	public var parameters:Dynamic;
	public var data:WeakMap<Dynamic, Dynamic>;
	public var renderer:Dynamic;
	public var domElement:Dynamic;

	public function new(parameters:Dynamic = {}) {
		this.parameters = parameters;
		this.data = new WeakMap();
		this.renderer = null;
		this.domElement = null;
	}

	public function init(renderer:Dynamic):Void {
		this.renderer = renderer;
	}

	// render context

	public function begin(renderContext:Dynamic):Void { }

	public function finish(renderContext:Dynamic):Void { }

	// render object

	public function draw(renderObject:Dynamic, info:Dynamic):Void { }

	// program

	public function createProgram(program:Dynamic):Void { }

	public function destroyProgram(program:Dynamic):Void { }

	// bindings

	public function createBindings(renderObject:Dynamic):Void { }

	public function updateBindings(renderObject:Dynamic):Void { }

	// pipeline

	public function createRenderPipeline(renderObject:Dynamic):Void { }

	public function createComputePipeline(computeNode:Dynamic, pipeline:Dynamic):Void { }

	public function destroyPipeline(pipeline:Dynamic):Void { }

	// cache key

	public function needsRenderUpdate(renderObject:Dynamic):Bool { return false; } // return Boolean ( fast test )

	public function getRenderCacheKey(renderObject:Dynamic):String { return ""; } // return String

	// node builder

	public function createNodeBuilder(renderObject:Dynamic):Dynamic { return null; } // return NodeBuilder (ADD IT)

	// textures

	public function createSampler(texture:Dynamic):Void { }

	public function createDefaultTexture(texture:Dynamic):Void { }

	public function createTexture(texture:Dynamic):Void { }

	public function copyTextureToBuffer(texture:Dynamic, x:Int, y:Int, width:Int, height:Int):Void {}

	// attributes

	public function createAttribute(attribute:Dynamic):Void { }

	public function createIndexAttribute(attribute:Dynamic):Void { }

	public function updateAttribute(attribute:Dynamic):Void { }

	public function destroyAttribute(attribute:Dynamic):Void { }

	// canvas

	public function getContext():Dynamic { return null; }

	public function updateSize():Void { }

	// utils

	public function resolveTimestampAsync(renderContext:Dynamic, type:Dynamic):Void { }

	public function hasFeatureAsync(name:String):Bool { return false; } // return Boolean

	public function hasFeature(name:String):Bool { return false; } // return Boolean

	public function getInstanceCount(renderObject:Dynamic):Int {
		var object = cast renderObject.object;
		var geometry = cast renderObject.geometry;
		if (geometry.isInstancedBufferGeometry) {
			return geometry.instanceCount;
		} else if (object.isInstancedMesh) {
			return object.count;
		} else {
			return 1;
		}
	}

	public function getDrawingBufferSize():Vector2 {
		var vector2 = Vector2.new();
		this.renderer.getDrawingBufferSize(vector2);
		return vector2;
	}

	public function getScissor():Vector4 {
		var vector4 = Vector4.new();
		this.renderer.getScissor(vector4);
		return vector4;
	}

	public function setScissorTest(boolean:Bool):Void { }

	public function getClearColor():Color4 {
		var renderer = this.renderer;
		var color4 = Color4.new();
		renderer.getClearColor(color4);
		color4.getRGB(color4, renderer.currentColorSpace);
		return color4;
	}

	public function getDomElement():Dynamic {
		var domElement = this.domElement;
		if (domElement == null) {
			domElement = if (this.parameters.canvas != null) this.parameters.canvas else createCanvasElement();
			if ("setAttribute" in domElement) {
				domElement.setAttribute("data-engine", "three.js r${REVISION} webgpu");
			}
			this.domElement = domElement;
		}
		return domElement;
	}

	// resource properties

	public function set(object:Dynamic, value:Dynamic):Void {
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

	public function delete(object:Dynamic):Void {
		this.data.delete(object);
	}

}