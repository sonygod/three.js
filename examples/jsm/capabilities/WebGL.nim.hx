import js.html.Document;
import js.html.CanvasElement;
import js.html.Window;
import js.html.Element;

class WebGL {

	public static function isWebGLAvailable():Bool {

		try {

			var canvas:CanvasElement = Document.createElement( 'canvas' );
			return (Type.getClass(Window.webGLRenderingContext) != null) && (canvas.getContext( 'webgl' ) != null || canvas.getContext( 'experimental-webgl' ) != null);

		} catch ( e:Dynamic ) {

			return false;

		}

	}

	public static function isWebGL2Available():Bool {

		try {

			var canvas:CanvasElement = Document.createElement( 'canvas' );
			return (Type.getClass(Window.webGL2RenderingContext) != null) && (canvas.getContext( 'webgl2' ) != null);

		} catch ( e:Dynamic ) {

			return false;

		}

	}

	public static function isColorSpaceAvailable( colorSpace:String ):Bool {

		try {

			var canvas:CanvasElement = Document.createElement( 'canvas' );
			var ctx:Dynamic = (Type.getClass(Window.webGL2RenderingContext) != null) && canvas.getContext( 'webgl2' );
			ctx.drawingBufferColorSpace = colorSpace;
			return ctx.drawingBufferColorSpace == colorSpace;

		} catch ( e:Dynamic ) {

			return false;

		}

	}

	public static function getWebGLErrorMessage():Element {

		return this.getErrorMessage( 1 );

	}

	public static function getWebGL2ErrorMessage():Element {

		return this.getErrorMessage( 2 );

	}

	public static function getErrorMessage( version:Int ):Element {

		var names:Map<Int, String> = new Map();
		names.set( 1, 'WebGL' );
		names.set( 2, 'WebGL 2' );

		var contexts:Map<Int, Dynamic> = new Map();
		contexts.set( 1, Window.webGLRenderingContext );
		contexts.set( 2, Window.webGL2RenderingContext );

		var message:String = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

		var element:Element = Document.createElement( 'div' );
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

		if ( contexts.get( version ) != null ) {

			message = message.replace( '$0', 'graphics card' );

		} else {

			message = message.replace( '$0', 'browser' );

		}

		message = message.replace( '$1', names.get( version ) );

		element.innerHTML = message;

		return element;

	}

}