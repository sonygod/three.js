package three.js.examples.jss.renderers.common;

import ChainMap;
import RenderObject;

class RenderObjects {
    public var renderer:Dynamic;
    public var nodes:Dynamic;
    public var geometries:Dynamic;
    public var pipelines:Dynamic;
    public var bindings:Dynamic;
    public var info:Dynamic;

    public var chainMaps:Map<String, ChainMap>;

    public function new(renderer:Dynamic, nodes:Dynamic, geometries:Dynamic, pipelines:Dynamic, bindings:Dynamic, info:Dynamic) {
        this.renderer = renderer;
        this.nodes = nodes;
        this.geometries = geometries;
        this.pipelines = pipelines;
        this.bindings = bindings;
        this.info = info;

        this.chainMaps = new Map<String, ChainMap>();
    }

    public function get(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String = 'default'):RenderObject {
        var chainMap:ChainMap = getChainMap(passId);
        var chainArray:Array<Dynamic> = [object, material, renderContext, lightsNode];

        var renderObject:RenderObject = chainMap.get(chainArray);

        if (renderObject == null) {
            renderObject = createRenderObject(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext, passId);
            chainMap.set(chainArray, renderObject);
        } else {
            renderObject.updateClipping(renderContext.clippingContext);

            if (renderObject.version != material.version || renderObject.needsUpdate) {
                if (renderObject.initialCacheKey != renderObject.getCacheKey()) {
                    renderObject.dispose();
                    renderObject = get(object, material, scene, camera, lightsNode, renderContext, passId);
                } else {
                    renderObject.version = material.version;
                }
            }
        }

        return renderObject;
    }

    public function getChainMap(passId:String = 'default'):ChainMap {
        if (!chainMaps.exists(passId)) {
            chainMaps.set(passId, new ChainMap());
        }
        return chainMaps.get(passId);
    }

    public function dispose():Void {
        chainMaps = new Map<String, ChainMap>();
    }

    public function createRenderObject(nodes:Dynamic, geometries:Dynamic, renderer:Dynamic, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String):RenderObject {
        var chainMap:ChainMap = getChainMap(passId);
        var renderObject:RenderObject = new RenderObject(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext);

        renderObject.onDispose = function() {
            pipelines.delete(renderObject);
            bindings.delete(renderObject);
            nodes.delete(renderObject);

            chainMap.delete(renderObject.getChainArray());
        };

        return renderObject;
    }
}