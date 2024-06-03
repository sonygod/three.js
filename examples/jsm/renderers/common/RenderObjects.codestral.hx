import js.Browser;
import ChainMap from './ChainMap';
import RenderObject from './RenderObject';

class RenderObjects {
    var renderer: Dynamic;
    var nodes: Dynamic;
    var geometries: Dynamic;
    var pipelines: Dynamic;
    var bindings: Dynamic;
    var info: Dynamic;
    var chainMaps: haxe.ds.StringMap<ChainMap> = new haxe.ds.StringMap();

    public function new(renderer: Dynamic, nodes: Dynamic, geometries: Dynamic, pipelines: Dynamic, bindings: Dynamic, info: Dynamic) {
        this.renderer = renderer;
        this.nodes = nodes;
        this.geometries = geometries;
        this.pipelines = pipelines;
        this.bindings = bindings;
        this.info = info;
    }

    public function get(object: Dynamic, material: Dynamic, scene: Dynamic, camera: Dynamic, lightsNode: Dynamic, renderContext: Dynamic, passId: String = 'default'): RenderObject {
        var chainMap: ChainMap = this.getChainMap(passId);
        var chainArray: Array<Dynamic> = [object, material, renderContext, lightsNode];
        var renderObject: RenderObject = chainMap.get(chainArray);

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

    public function getChainMap(passId: String = 'default'): ChainMap {
        if (this.chainMaps.exists(passId)) {
            return this.chainMaps.get(passId);
        } else {
            var chainMap: ChainMap = new ChainMap();
            this.chainMaps.set(passId, chainMap);
            return chainMap;
        }
    }

    public function dispose(): Void {
        this.chainMaps = new haxe.ds.StringMap();
    }

    public function createRenderObject(nodes: Dynamic, geometries: Dynamic, renderer: Dynamic, object: Dynamic, material: Dynamic, scene: Dynamic, camera: Dynamic, lightsNode: Dynamic, renderContext: Dynamic, passId: String): RenderObject {
        var chainMap: ChainMap = this.getChainMap(passId);
        var renderObject: RenderObject = new RenderObject(nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext);

        renderObject.onDispose = () -> {
            this.pipelines.delete(renderObject);
            this.bindings.delete(renderObject);
            this.nodes.delete(renderObject);
            chainMap.delete(renderObject.getChainArray());
        };

        return renderObject;
    }
}