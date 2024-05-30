import ChainMap from './ChainMap.hx';
import RenderContext from './RenderContext.hx';

class RenderContexts {
    public var chainMaps: { [attachmentState: String]: ChainMap } = { };

    public function get(scene: Scene, camera: Camera, renderTarget: RenderTarget = null): RenderContext {
        var chainKey = [scene, camera];
        var attachmentState: String;

        if (renderTarget == null) {
            attachmentState = 'default';
        } else {
            var format = renderTarget.texture.format;
            var count = renderTarget.count;
            attachmentState = `${count}:${format}:${renderTarget.samples}:${renderTarget.depthBuffer}:${renderTarget.stencilBuffer}`;
        }

        var chainMap = this.getChainMap(attachmentState);
        var renderState = chainMap.get(chainKey);

        if (renderState == null) {
            renderState = new RenderContext();
            chainMap.set(chainKey, renderState);
        }

        if (renderTarget != null) {
            renderState.sampleCount = if (renderTarget.samples == 0) 1 else renderTarget.samples;
        }

        return renderState;
    }

    public function getChainMap(attachmentState: String): ChainMap {
        return this.chainMaps.get(attachmentState).or({ }, () -> {
            var chainMap = new ChainMap();
            this.chainMaps[attachmentState] = chainMap;
            return chainMap;
        });
    }

    public function dispose(): Void {
        this.chainMaps = { };
    }
}

class Scene { }
class Camera { }
class RenderTarget {
    public var texture: Texture;
    public var count: Int;
    public var samples: Int;
    public var depthBuffer: Bool;
    public var stencilBuffer: Bool;
}
class Texture {
    public var format: String;
}