import js.html.CanvasElement;
import js.html.Window;
import js.html.HTMLElement;
import js.html.Element;

class WebGL {

	static function isWebGLAvailable():Bool {
		try {
			var canvas = new CanvasElement();
			return (Window.get().WebGLRenderingContext != null && (canvas.getContext('webgl') != null || canvas.getContext('experimental-webgl') != null));
		} catch (e:Dynamic) {
			return false;
		}
	}

	static function isWebGL2Available():Bool {
		try {
			var canvas = new CanvasElement();
			return (Window.get().WebGL2RenderingContext != null && canvas.getContext('webgl2') != null);
		} catch (e:Dynamic) {
			return false;
		}
	}

	static function isColorSpaceAvailable(colorSpace:String):Bool {
		try {
			var canvas = new CanvasElement();
			var ctx = Window.get().WebGL2RenderingContext != null ? canvas.getContext('webgl2') : null;
			if (ctx != null) {
				ctx.drawingBufferColorSpace = colorSpace;
				return ctx.drawingBufferColorSpace == colorSpace;
			}
			return false;
		} catch (e:Dynamic) {
			return false;
		}
	}

	static function getWebGLErrorMessage():Element {
		return getErrorMessage(1);
	}

	static function getWebGL2ErrorMessage():Element {
		return getErrorMessage(2);
	}

	static function getErrorMessage(version:Int):Element {
		var names = {
			1: 'WebGL',
			2: 'WebGL 2'
		};
		var contexts = {
			1: Window.get().WebGLRenderingContext,
			2: Window.get().WebGL2RenderingContext
		};

		var message = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

		var element = new HTMLElement();
		element.id = 'webglmessage';
		element.style.fontFamily = 'monospace';
		element.style.fontSize = '13px';
		element.style.fontWeight = 'normal';
		element.style.textAlign = 'center';
		element.style.background = '#fff';
		element.style.color = '#000';
		element.style.padding = '1.5em';
		element.style.width = '400px';
		element.style.margin = '5em auto 0';

		if (contexts.get(version) != null) {
			message = message.replace('$0', 'graphics card');
		} else {
			message = message.replace('$0', 'browser');
		}

		message = message.replace('$1', names.get(version));

		element.innerHTML = message;

		return element;
	}
}