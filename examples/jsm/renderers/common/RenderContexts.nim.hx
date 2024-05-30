import ChainMap;
import RenderContext;

class RenderContexts {

	public var chainMaps:Map<String, ChainMap>;

	public function new() {
		this.chainMaps = new Map();
	}

	public function get(scene:Dynamic, camera:Dynamic, renderTarget:Dynamic?):RenderContext {
		var chainKey:Array<Dynamic> = [scene, camera];
		var attachmentState:String;

		if (renderTarget == null) {
			attachmentState = 'default';
		} else {
			var format = renderTarget.texture.format;
			var count = renderTarget.count;

			attachmentState = "${count}:${format}:${renderTarget.samples}:${renderTarget.depthBuffer}:${renderTarget.stencilBuffer}";
		}

		var chainMap = this.getChainMap(attachmentState);

		var renderState:RenderContext = chainMap.get(chainKey);

		if (renderState == null) {
			renderState = new RenderContext();
			chainMap.set(chainKey, renderState);
		}

		if (renderTarget != null) renderState.sampleCount = renderTarget.samples == 0 ? 1 : renderTarget.samples;

		return renderState;
	}

	public function getChainMap(attachmentState:String):ChainMap {
		return this.chainMaps.get(attachmentState) ?? (this.chainMaps.set(attachmentState, new ChainMap()), this.chainMaps.get(attachmentState));
	}

	public function dispose() {
		this.chainMaps = new Map();
	}
}