import ChainMap from "./ChainMap";
import RenderContext from "./RenderContext";

class RenderContexts {

	public chainMaps:Map<String, ChainMap<Array<Dynamic>, RenderContext>> = new Map();

	public get(scene:Dynamic, camera:Dynamic, renderTarget:Dynamic = null):RenderContext {

		const chainKey:Array<Dynamic> = [scene, camera];

		var attachmentState:String;

		if (renderTarget == null) {

			attachmentState = "default";

		} else {

			const format = renderTarget.texture.format;
			const count = renderTarget.count;

			attachmentState = `${count}:${format}:${renderTarget.samples}:${renderTarget.depthBuffer}:${renderTarget.stencilBuffer}`;

		}

		const chainMap:ChainMap<Array<Dynamic>, RenderContext> = this.getChainMap(attachmentState);

		var renderState:RenderContext = chainMap.get(chainKey);

		if (renderState == null) {

			renderState = new RenderContext();

			chainMap.set(chainKey, renderState);

		}

		if (renderTarget != null) renderState.sampleCount = renderTarget.samples == 0 ? 1 : renderTarget.samples;

		return renderState;

	}

	public getChainMap(attachmentState:String):ChainMap<Array<Dynamic>, RenderContext> {

		return this.chainMaps.get(attachmentState) || (this.chainMaps.set(attachmentState, new ChainMap()), this.chainMaps.get(attachmentState));

	}

	public dispose():Void {

		this.chainMaps = new Map();

	}

}

export default RenderContexts;