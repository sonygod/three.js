class WebGPU {

    static var GPUShaderStage:{ VERTEX:Int, FRAGMENT:Int, COMPUTE:Int } = { VERTEX: 1, FRAGMENT: 2, COMPUTE: 4 };

    static var isAvailable:Bool = js.Browser.navigator.gpu !== undefined;

    static var staticAdapter:Bool = isAvailable;

    static function isAvailable():Bool {
        return isAvailable;
    }

    static function getStaticAdapter():Bool {
        return staticAdapter;
    }

    static function getErrorMessage():js.html.Element {
        var message = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';

        var element = js.Browser.document.createElement('div');
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