package three.js.examples.jm;

@:native("self")
extern class Self {
    // this will be filled in if it doesn't exist
    static var GPUShaderStage: {
        VERTEX: Int,
        FRAGMENT: Int,
        COMPUTE: Int
    };
}

class WebGPU {
    static var isAvailable: Bool;

    static function new() {}

    static function isAvailable(): Bool {
        return isAvailable;
    }

    static function getStaticAdapter(): Bool {
        return isAvailable;
    }

    static function getErrorMessage(): HtmlDom {
        var message = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
        var element = js.Browser.document.createElement("div");
        element.id = 'webgpumessage';
        element.style.fontFamily = 'monospace';
        element.style.fontSize = '13px';
        element.style.fontWeight = 'normal';
        element.style.textAlign = 'center';
        element.style.background = '#fff';
        element.style.color = '#000';
        element.style.padding = '1.5em';
        element.style.maxWidth = '400px';
        element.style.margin = '5em auto 0';
        element.innerHTML = message;
        return element;
    }

    static function __init__() {
        if (Self.GPUShaderStage == null) {
            Self.GPUShaderStage = {
                VERTEX: 1,
                FRAGMENT: 2,
                COMPUTE: 4
            };
        }

        isAvailable = js.Browser.navigator.gpu != null;

        if (js.Browser.window != null && isAvailable) {
            isAvailable = js.Browser.navigator.gpu.requestAdapter() != null;
        }
    }
}