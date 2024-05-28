if (self.GPUShaderStage == null) {
    self.GPUShaderStage = {
        VERTEX: 1,
        FRAGMENT: 2,
        COMPUTE: 4,
    };
}

var isAvailable = false;
if (js.Browser.hasWindow() && js.Browser.navigator.gpu != null) {
    isAvailable = await js.Browser.navigator.gpu.requestAdapter();
}

class WebGPU {
    public static function isAvailable(): Bool {
        return isAvailable;
    }

    public static function getStaticAdapter(): Bool {
        return isAvailable;
    }

    public static function getErrorMessage(): HtmlElement {
        var message = 'Your browser does not support <a href="https://gpuweb.github.io/gpuweb/" style="color:blue">WebGPU</a> yet';
        var element = Html.createDiv();
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

class js__Browser {
    public static var navigator: Dynamic;
    public static function hasWindow(): Bool {
        return window != null;
    }
}

class Html {
    public static function createDiv(): HtmlElement {
        return cast HtmlElement(Std.create('div'));
    }
}

class Std {
    public static function create(tag: String): HtmlElement {
        return cast HtmlElement(js.Browser.window.document.createElement(tag));
    }
}