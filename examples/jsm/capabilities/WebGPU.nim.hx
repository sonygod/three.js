import js.html.navigator.GPU;
import js.html.navigator.GPUAdapter;
import js.html.Element;
import js.html.HTMLDivElement;

class WebGPU {
    public static var isAvailable:Bool;
    public static var GPUShaderStage:Dynamic;

    public static function main() {
        if (GPUShaderStage == null) {
            GPUShaderStage = { VERTEX: 1, FRAGMENT: 2, COMPUTE: 4 };
        }

        isAvailable = (typeof(GPU) != 'undefined');

        if (typeof(window) != 'undefined' && isAvailable) {
            isAvailable = js.Browser.global.navigator.gpu.requestAdapter();
        }
    }

    public static function isAvailable():Bool {
        return isAvailable;
    }

    public static function getStaticAdapter():Dynamic {
        return isAvailable;
    }

    public static function getErrorMessage():HTMLDivElement {
        var message:String = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
        var element:HTMLDivElement = js.Browser.document.createElement('div');
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