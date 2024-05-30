import ChainMap from './ChainMap.hx';
import RenderContext from './RenderContext.hx';

class RenderContexts {

	var chainMaps:Map<String, ChainMap>;

	public function new() {

		chainMaps = new Map();

	}

	public function get(scene:Dynamic, camera:Dynamic, renderTarget:Dynamic = null):RenderContext {

		var chainKey:Array<Dynamic> = [scene, camera];

		var attachmentState:String;

		if (renderTarget == null) {

			attachmentState = 'default';

		} else {

			var format:String = Reflect.field(renderTarget, 'texture').format;
			var count:Int = Reflect.field(renderTarget, 'count');

			attachmentState = `${count}:${format}:${Reflect.field(renderTarget, 'samples')}:${Reflect.field(renderTarget, 'depthBuffer')}:${Reflect.field(renderTarget, 'stencilBuffer')}`;

		}

		var chainMap:ChainMap = this.getChainMap(attachmentState);

		var renderState:RenderContext = chainMap.get(chainKey);

		if (renderState == null) {

			renderState = new RenderContext();

			chainMap.set(chainKey, renderState);

		}

		if (renderTarget != null) renderState.sampleCount = (Reflect.field(renderTarget, 'samples') == 0) ? 1 : Reflect.field(renderTarget, 'samples');

		return renderState;

	}

	public function getChainMap(attachmentState:String):ChainMap {

		var chainMap:ChainMap = chainMaps.get(attachmentState);

		if (chainMap == null) {

			chainMap = new ChainMap();

			chainMaps.set(attachmentState, chainMap);

		}

		return chainMap;

	}

	public function dispose():Void {

		chainMaps = new Map();

	}

}

typedef RenderContexts_ChainMap = Map<String, ChainMap>;