package three.js.examples.javascript;

import js.Browser;
import js.html.CanvasRenderingContext;

class WebGL {

    public static function isWebGLAvailable():Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createElement("canvas");
            return (window.WebGLRenderingContext != null && (canvas.getContext("webgl") != null || canvas.getContext("experimental-webgl") != null));
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function isWebGL2Available():Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createElement("canvas");
            return (window.WebGL2RenderingContext != null && canvas.getContext("webgl2") != null);
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function isColorSpaceAvailable(colorSpace:String):Bool {
        try {
            var canvas:js.html.CanvasElement = Browser.document.createElement("canvas");
            var ctx:js.html.webgl.RenderingContext = (window.WebGL2RenderingContext != null) ? canvas.getContext("webgl2") : null;
            ctx.drawingBufferColorSpace = colorSpace;
            return ctx.drawingBufferColorSpace == colorSpace;
        } catch (e:Dynamic) {
            return false;
        }
    }

    public static function getWebGLErrorMessage():js.html.DivElement {
        return getErrorMessage(1);
    }

    public static function getWebGL2ErrorMessage():js.html.DivElement {
        return getErrorMessage(2);
    }

    public static function getErrorMessage(version:Int):js.html.DivElement {
        var names:Array<String> = ["WebGL", "WebGL 2"];
        var contexts:Array<Dynamic> = [window.WebGLRenderingContext, window.WebGL2RenderingContext];

        var message:String = 'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

        var element:js.html.DivElement = Browser.document.createElement("div");
        element.id = "webglmessage";
        element.style.fontFamily = "monospace";
        element.style.fontSize = "13px";
        element.style.fontWeight = "normal";
        element.style.textAlign = "center";
        element.style.background = "#fff";
        element.style.color = "#000";
        element.style.padding = "1.5em";
        element.style.width = "400px";
        element.style.margin = "5em auto 0";

        if (contexts[version - 1] != null) {
            message = message.replace("$0", "graphics card");
        } else {
            message = message.replace("$0", "browser");
        }

        message = message.replace("$1", names[version - 1]);

        element.innerHTML = message;

        return element;
    }

}