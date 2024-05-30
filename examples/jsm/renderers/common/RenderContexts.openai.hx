package three.js.examples.jvm.renderers.common;

import haxe.ds.StringMap;
import three.js.renderers.common.ChainMap;
import three.js.renderers.common.RenderContext;

class RenderContexts {
    private var chainMaps:StringMap<ChainMap>;

    public function new() {
        chainMaps = new StringMap<ChainMap>();
    }

    public function get(scene:Dynamic, camera:Dynamic, ?renderTarget:Dynamic):RenderContext {
        var chainKey:Array<Dynamic> = [scene, camera];

        var attachmentState:String;
        if (renderTarget == null) {
            attachmentState = 'default';
        } else {
            var format:String = renderTarget.texture.format;
            var count:Int = renderTarget.count;
            attachmentState = '$count:$format:${renderTarget.samples}:${renderTarget.depthBuffer}:${renderTarget.stencilBuffer}';
        }

        var chainMap:ChainMap = getChainMap(attachmentState);
        var renderState:RenderContext = chainMap.get(chainKey);

        if (renderState == null) {
            renderState = new RenderContext();
            chainMap.set(chainKey, renderState);
        }

        if (renderTarget != null) renderState.sampleCount = (renderTarget.samples == 0) ? 1 : renderTarget.samples;

        return renderState;
    }

    private function getChainMap(attachmentState:String):ChainMap {
        return chainMaps.get(attachmentState) != null ? chainMaps.get(attachmentState) : (chainMaps.set(attachmentState, new ChainMap()));
    }

    public function dispose() {
        chainMaps = new StringMap<ChainMap>();
    }
}