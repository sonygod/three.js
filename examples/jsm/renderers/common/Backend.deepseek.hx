import three.Vector2;
import three.Vector4;
import three.Color4;
import three.REVISION;
import three.createCanvasElement;

class Backend {

	var parameters:Dynamic;
	var data:WeakMap<Dynamic, Dynamic>;
	var renderer:Dynamic;
	var domElement:Dynamic;
	static var vector2:Vector2;
	static var vector4:Vector4;
	static var color4:Color4;

	public function new(parameters:Dynamic = {}) {
		this.parameters = Std.clone(parameters);
		this.data = new WeakMap();
		this.renderer = null;
		this.domElement = null;
	}

	public async function init(renderer:Dynamic):Void {
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

	public function copyTextureToBuffer(texture:Dynamic, x:Float, y:Float, width:Float, height:Float):Void { }

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
		var object = renderObject.object;
		var geometry = renderObject.geometry;
		return (geometry.isInstancedBufferGeometry ? geometry.instanceCount : (object.isInstancedMesh ? object.count : 1));
	}

	public function getDrawingBufferSize():Vector2 {
		vector2 = vector2 || new Vector2();
		return this.renderer.getDrawingBufferSize(vector2);
	}

	public function getScissor():Vector4 {
		vector4 = vector4 || new Vector4();
		return this.renderer.getScissor(vector4);
	}

	public function setScissorTest(boolean:Bool):Void { }

	public function getClearColor():Color4 {
		color4 = color4 || new Color4();
		this.renderer.getClearColor(color4);
		color4.getRGB(color4, this.renderer.currentColorSpace);
		return color4;
	}

	public function getDomElement():Dynamic {
		var domElement = this.domElement;
		if (domElement === null) {
			domElement = (this.parameters.canvas !== undefined) ? this.parameters.canvas : createCanvasElement();
			if ('setAttribute' in domElement) domElement.setAttribute('data-engine', `three.js r${REVISION} webgpu`);
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
		if (map === undefined) {
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