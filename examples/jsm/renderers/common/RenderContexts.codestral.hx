import js.Browser.document;
import ChainMap from './ChainMap';
import RenderContext from './RenderContext';

class RenderContexts {

    public var chainMaps:haxe.ds.StringMap<ChainMap> = new haxe.ds.StringMap();

    public function new() {
        // constructor
    }

    public function get(scene:Dynamic, camera:Dynamic, renderTarget:Dynamic = null):RenderContext {

        var chainKey:Array<Dynamic> = [scene, camera];

        var attachmentState:String;

        if (renderTarget === null) {

            attachmentState = 'default';

        } else {

            var format:String = renderTarget.texture.format;
            var count:Int = renderTarget.count;

            attachmentState = "${count}:${format}:${renderTarget.samples}:${renderTarget.depthBuffer}:${renderTarget.stencilBuffer}";

        }

        var chainMap:ChainMap = this.getChainMap(attachmentState);

        var renderState:RenderContext = chainMap.get(chainKey);

        if (renderState === null) {

            renderState = new RenderContext();

            chainMap.set(chainKey, renderState);

        }

        if (renderTarget !== null) renderState.sampleCount = renderTarget.samples === 0 ? 1 : renderTarget.samples;

        return renderState;
    }

    public function getChainMap(attachmentState:String):ChainMap {

        if (this.chainMaps.exists(attachmentState)) {
            return this.chainMaps.get(attachmentState);
        } else {
            var chainMap:ChainMap = new ChainMap();
            this.chainMaps.set(attachmentState, chainMap);
            return chainMap;
        }
    }

    public function dispose():Void {

        this.chainMaps = new haxe.ds.StringMap();

    }
}