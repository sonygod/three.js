package three.js.examples.jm;

import js.html.Document;
import js.html.Navigator;
import js.html.Window;

class WebGPU {
    static var GPUShaderStage = {
        VERTEX: 1,
        FRAGMENT: 2,
        COMPUTE: 4
    };

    static var isAvailable:Bool = untyped __js__('navigator.gpu') != null;

    static function new() {}

    static function isAvailable():Bool {
        if (untyped __js__('window') != null && isAvailable) {
            isAvailable = untyped __js__('navigator.gpu.requestAdapter()');
        }
        return isAvailable;
    }

    static function getStaticAdapter():Dynamic {
        return isAvailable;
    }

    static function getErrorMessage():js.html.Element {
        var message:String = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
        var element:js.html.Element = untyped __js__('document.createElement')('div');
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
}