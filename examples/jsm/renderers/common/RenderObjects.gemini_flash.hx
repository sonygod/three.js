import ChainMap from "./ChainMap";
import RenderObject from "./RenderObject";

class RenderObjects {

	public renderer:Dynamic;
	public nodes:Dynamic;
	public geometries:Dynamic;
	public pipelines:Dynamic;
	public bindings:Dynamic;
	public info:Dynamic;

	public chainMaps:Map<String, ChainMap> = new Map();

	public function new(renderer:Dynamic, nodes:Dynamic, geometries:Dynamic, pipelines:Dynamic, bindings:Dynamic, info:Dynamic) {
		this.renderer = renderer;
		this.nodes = nodes;
		this.geometries = geometries;
		this.pipelines = pipelines;
		this.bindings = bindings;
		this.info = info;
	}

	public function get(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String = "default"):RenderObject {
		var chainMap = this.getChainMap(passId);
		var chainArray = [object, material, renderContext, lightsNode];

		var renderObject = chainMap.get(chainArray);

		if (renderObject == null) {
			renderObject = this.createRenderObject(this.nodes, this.geometries, this.renderer, object, material, scene, camera, lightsNode, renderContext, passId);

			chainMap.set(chainArray, renderObject);
		} else {
			renderObject.updateClipping(renderContext.clippingContext);

			if (renderObject.version != material.version || renderObject.needsUpdate) {
				if (renderObject.initialCacheKey != renderObject.getCacheKey()) {
					renderObject.dispose();

					renderObject = this.get(object, material, scene, camera, lightsNode, renderContext, passId);
				} else {
					renderObject.version = material.version;
				}
			}
		}

		return renderObject;
	}

	public function getChainMap(passId:String = "default"):ChainMap {
		return this.chainMaps.get(passId) || (this.chainMaps.set(passId, new ChainMap()), this.chainMaps.get(passId));
	}

	public function dispose() {
		this.chainMaps = new Map();
	}

	public function createRenderObject(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String):RenderObject {
		var chainMap = this.getChainMap(passId);

		var renderObject = new RenderObject(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext);

		renderObject.onDispose = function() {
			this.pipelines.delete(renderObject);
			this.bindings.delete(renderObject);
			this.nodes.delete(renderObject);

			chainMap.delete(renderObject.getChainArray());
		};

		return renderObject;
	}
}

export default RenderObjects;