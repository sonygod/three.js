class WebGL {
    static function isWebGLAvailable():Bool {
        var canvas = window.document.createElement('canvas');
        try {
            return window.WebGLRenderingContext != null && (canvas.getContext('webgl') != null || canvas.getContext('experimental-webgl') != null);
        } catch (_) {
            return false;
        }
    }

    static function isWebGL2Available():Bool {
        var canvas = window.document.createElement('canvas');
        try {
            return window.WebGL2RenderingContext != null && canvas.getContext('webgl2') != null;
        } catch (_) {
            return false;
        }
    }

    static function isColorSpaceAvailable(colorSpace:String):Bool {
        var canvas = window.document.createElement('canvas');
        var ctx:Dynamic;
        try {
            ctx = window.WebGL2RenderingContext != null ? canvas.getContext('webgl2') : null;
            ctx.drawingBufferColorSpace = colorSpace;
            return ctx.drawingBufferColorSpace == colorSpace;
        } catch (_) {
            return false;
        }
    }

    static function getWebGLErrorMessage():HtmlElement {
        return getErrorMessage(1);
    }

    static function getWebGL2ErrorMessage():HtmlElement {
        return getErrorMessage(2);
    }

    static function getErrorMessage(version:Int):HtmlElement {
        var names = {
            1: 'WebGL',
            2: 'WebGL 2'
        };
        var contexts = {
            1: window.WebGLRenderingContext,
            2: window.WebGL2RenderingContext
        };
        var message = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';
        var element = window.document.createElement('div');
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
        if (contexts[version] != null) {
            message = message.replace('$0', 'graphics card');
        } else {
            message = message.replace('$0', 'browser');
        }
        message = message.replace('$1', names[version]);
        element.innerHTML = message;
        return element;
    }
}