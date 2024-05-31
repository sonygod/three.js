import js.Browser;

class WebGL {

    public static function isWebGLAvailable():Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createCanvas();
            return (cast Browser.window.WebGLRenderingContext != null) && 
                   (canvas.getContext("webgl") != null || canvas.getContext("experimental-webgl") != null);
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function isWebGL2Available():Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createCanvas();
            return (cast Browser.window.WebGL2RenderingContext != null) && (canvas.getContext("webgl2") != null);
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function isColorSpaceAvailable(colorSpace:String):Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createCanvas();
            var ctx:js.html.CanvasRenderingContext2D = 
                (cast Browser.window.WebGL2RenderingContext != null) ? 
                    cast canvas.getContext("webgl2") : 
                    null;
            if (ctx != null) {
                Reflect.setProperty(ctx, "drawingBufferColorSpace", colorSpace);
                return Reflect.getProperty(ctx, "drawingBufferColorSpace") == colorSpace;
            }
            return false; 
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function getWebGLErrorMessage():js.html.Element {
        return getErrorMessage(1);
    }

    public static function getWebGL2ErrorMessage():js.html.Element {
        return getErrorMessage(2);
    }

    private static function getErrorMessage(version:Int):js.html.Element {
        var names:Map<Int, String> = [
            1 => "WebGL",
            2 => "WebGL 2"
        ];

        var contexts:Map<Int, Dynamic> = [
            1 => Browser.window.WebGLRenderingContext,
            2 => Browser.window.WebGL2RenderingContext
        ];

        var message:String = "Your $0 does not seem to support <a href=\"http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation\" style=\"color:#000\">$1</a>";

        var element:js.html.DivElement = cast Browser.document.createDivElement();
        element.id = "webglmessage";
        element.style.fontFamily = "monospace";
        element.style.fontSize = "13px";
        element.style.fontWeight = "normal";
        element.style.textAlign = "center";
        element.style.backgroundColor = "#fff";
        element.style.color = "#000";
        element.style.padding = "1.5em";
        element.style.width = "400px";
        element.style.margin = "5em auto 0";

        if (contexts.exists(version)) {
            message = StringTools.replace(message, "$0", "graphics card");
        } else {
            message = StringTools.replace(message, "$0", "browser");
        }

        message = StringTools.replace(message, "$1", names.get(version));
        element.innerHTML = message;

        return element;
    }
}