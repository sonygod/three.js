import ChainMap from './ChainMap.hx';
import RenderObject from './RenderObject.hx';

class RenderObjects {
    public var renderer:Renderer;
    public var nodes:Nodes;
    public var geometries:Geometries;
    public var pipelines:Pipelines;
    public var bindings:Bindings;
    public var info:Info;
    public var chainMaps:Map<String, ChainMap>;

    public function new(renderer:Renderer, nodes:Nodes, geometries:Geometries, pipelines:Pipelines, bindings:Bindings, info:Info) {
        this.renderer = renderer;
        this.nodes = nodes;
        this.geometries = geometries;
        this.pipelines = pipelines;
        this.bindings = bindings;
        this.info = info;
        this.chainMaps = Map();
    }

    public function get(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String = 'default'):RenderObject {
        var chainMap = this.getChainMap(passId);
        var chainArray = [object, material, renderContext, lightsNode];

        var renderObject = chainMap.get(chainArray);
        if (renderObject == null) {
            renderObject = this.createRenderObject(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext, passId);
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

    public function getChainMap(passId:String):ChainMap {
        return this.chainMaps.get(passId).or({
            default: function() {
                var map = ChainMap.new();
                this.chainMaps.set(passId, map);
                return map;
            }
        });
    }

    public function dispose():Void {
        this.chainMaps = Map();
    }

    public function createRenderObject(nodes:Nodes, geometries:Geometries, renderer:Renderer, object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, renderContext:Dynamic, passId:String):RenderObject {
        var chainMap = this.getChainMap(passId);
        var renderObject = RenderObject.new(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext);
        renderObject.onDispose = function() {
            pipelines.delete(renderObject);
            bindings.delete(renderObject);
            nodes.delete(renderObject);
            chainMap.delete(renderObject.getChainArray());
        };
        return renderObject;
    }
}