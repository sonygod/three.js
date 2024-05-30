import ChainMap from './ChainMap';
import RenderObject from './RenderObject';

class RenderObjects {

	var renderer:Dynamic;
	var nodes:Dynamic;
	var geometries:Dynamic;
	var pipelines:Dynamic;
	var bindings:Dynamic;
	var info:Dynamic;
	var chainMaps:Dynamic;

	public function new(renderer:Dynamic, nodes:Dynamic, geometries:Dynamic, pipelines:Dynamic, bindings:Dynamic, info:Dynamic) {
		this.renderer = renderer;
		this.nodes = nodes;
		this.geometries = geometries;
		this.pipelines = pipelines;
		this.bindings = bindings;
		this.info = info;
		this.chainMaps = {};
	}

	public function get(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:Dynamic):Dynamic {
		var chainMap = this.getChainMap(passId);
		var chainArray = [object, material, renderContext, lightsNode];
		var renderObject = chainMap.get(chainArray);
		if (renderObject == null) {
			renderObject = this.createRenderObject(this.nodes, this.geometries, this.renderer, object, material, scene, camera, lightsNode, renderContext, passId);
			chainMap.set(chainArray, renderObject);
		} else {
			renderObject.updateClipping(renderContext.clippingContext);
			if (renderObject.version !== material.version || renderObject.needsUpdate) {
				if (renderObject.initialCacheKey !== renderObject.getCacheKey()) {
					renderObject.dispose();
					renderObject = this.get(object, material, scene, camera, lightsNode, renderContext, passId);
				} else {
					renderObject.version = material.version;
				}
			}
		}
		return renderObject;
	}

	public function getChainMap(passId:Dynamic = 'default'):Dynamic {
		return this.chainMaps[passId] ?? (this.chainMaps[passId] = new ChainMap());
	}

	public function dispose():Void {
		this.chainMaps = {};
	}

	public function createRenderObject(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:Dynamic):Dynamic {
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