class WebGL {

    static function isWebGLAvailable():Bool {

        try {

            var canvas = js.Browser.document.createElement( 'canvas' );
            return !! ( js.Browser.window.WebGLRenderingContext && ( canvas.getContext( 'webgl' ) || canvas.getContext( 'experimental-webgl' ) ) );

        } catch (e:Dynamic) {

            return false;

        }

    }

    static function isWebGL2Available():Bool {

        try {

            var canvas = js.Browser.document.createElement( 'canvas' );
            return !! ( js.Browser.window.WebGL2RenderingContext && canvas.getContext( 'webgl2' ) );

        } catch (e:Dynamic) {

            return false;

        }

    }

    static function isColorSpaceAvailable(colorSpace:String):Bool {

        try {

            var canvas = js.Browser.document.createElement( 'canvas' );
            var ctx = js.Browser.window.WebGL2RenderingContext && canvas.getContext( 'webgl2' );
            ctx.drawingBufferColorSpace = colorSpace;
            return ctx.drawingBufferColorSpace === colorSpace;

        } catch (e:Dynamic) {

            return false;

        }

    }

    static function getWebGLErrorMessage():js.html.Element {

        return getErrorMessage(1);

    }

    static function getWebGL2ErrorMessage():js.html.Element {

        return getErrorMessage(2);

    }

    static function getErrorMessage(version:Int):js.html.Element {

        var names = {
            1: 'WebGL',
            2: 'WebGL 2'
        };

        var contexts = {
            1: js.Browser.window.WebGLRenderingContext,
            2: js.Browser.window.WebGL2RenderingContext
        };

        var message = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

        var element = js.Browser.document.createElement( 'div' );
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

        if (contexts[version]) {

            message = message.replace('$0', 'graphics card');

        } else {

            message = message.replace('$0', 'browser');

        }

        message = message.replace('$1', names[version]);

        element.innerHTML = message;

        return element;

    }

}