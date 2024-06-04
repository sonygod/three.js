import ClippingContext from "./ClippingContext";

class RenderObject {

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
	public var attributes:Array<Dynamic>;
	public var pipeline:Dynamic;
	public var vertexBuffers:Array<Dynamic>;
	public var clippingContext:ClippingContext;
	public var clippingContextVersion:Int;
	public var initialNodesCacheKey:String;
	public var initialCacheKey:String;
	public var _nodeBuilderState:Dynamic;
	public var _bindings:Dynamic;
	public var onDispose:Dynamic;
	public var isRenderObject:Bool = true;
	public var onMaterialDispose:Dynamic;

	public function new(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic) {
		this._nodes = nodes;
		this._geometries = geometries;

		this.id = id++;

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

		this.onMaterialDispose = function() {
			this.dispose();
		};

		material.addEventListener('dispose', this.onMaterialDispose);
	}

	public function updateClipping(parent:ClippingContext) {
		var material = this.material;

		var clippingContext = this.clippingContext;

		if (Std.is(material.clippingPlanes, Array)) {
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
		if (this.clippingContext.version == this.clippingContextVersion) return false;

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
		if (this.attributes != null) return this.attributes;

		var nodeAttributes = this.getNodeBuilderState().nodeAttributes;
		var geometry = this.geometry;

		var attributes = new Array<Dynamic>();
		var vertexBuffers = new haxe.ds.Set();

		for (nodeAttribute in nodeAttributes) {
			var attribute = nodeAttribute.node && nodeAttribute.node.attribute ? nodeAttribute.node.attribute : geometry.getAttribute(nodeAttribute.name);

			if (attribute == null) continue;

			attributes.push(attribute);

			var bufferAttribute = attribute.isInterleavedBufferAttribute ? attribute.data : attribute;
			vertexBuffers.add(bufferAttribute);
		}

		this.attributes = attributes;
		this.vertexBuffers = haxe.ds.Vector.fromSet(vertexBuffers);

		return attributes;
	}

	public function getVertexBuffers():Array<Dynamic> {
		if (this.vertexBuffers == null) this.getAttributes();

		return this.vertexBuffers;
	}

	public function getMaterialCacheKey():String {
		var object = this.object;
		var material = this.material;

		var cacheKey = material.customProgramCacheKey();

		var keys = Reflect.fields(material);

		for (key in keys) {
			if (key.startsWith("is") || key.startsWith("_") || key == "visible" || key == "version" || key == "uuid" || key == "name" || key == "opacity" || key == "userData") continue;

			var value = Reflect.field(material, key);

			if (value != null) {
				var type = Type.typeof(value);

				if (type == TFloat || type == TInt) value = value != 0 ? "1" : "0"; // Convert to on/off, important for clearcoat, transmission, etc
				else if (type == TObject) value = "{}";
			}

			cacheKey += /*property + ':' +*/ value + ",";
		}

		cacheKey += this.clippingContextVersion + ",";

		if (object.skeleton != null) {
			cacheKey += object.skeleton.bones.length + ",";
		}

		if (object.morphTargetInfluences != null) {
			cacheKey += object.morphTargetInfluences.length + ",";
		}

		if (object.isBatchedMesh) {
			cacheKey += object._matricesTexture.uuid + ",";
			cacheKey += object._colorsTexture.uuid + ",";
		}

		return cacheKey;
	}

	public function get needsUpdate():Bool {
		return this.initialNodesCacheKey != this.getNodesCacheKey() || this.clippingNeedsUpdate;
	}

	public function getNodesCacheKey():String {
		// Environment Nodes Cache Key

		return this._nodes.getCacheKey(this.scene, this.lightsNode);
	}

	public function getCacheKey():String {
		return this.getMaterialCacheKey() + "," + this.getNodesCacheKey();
	}

	public function dispose() {
		this.material.removeEventListener('dispose', this.onMaterialDispose);

		this.onDispose();
	}

	private var _nodes:Dynamic;
	private var _geometries:Dynamic;

	static var id:Int = 0;
}