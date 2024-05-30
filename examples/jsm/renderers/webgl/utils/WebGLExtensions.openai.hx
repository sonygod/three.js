package three.js.examples.jsm.renderers.webgl.utils;

class WebGLExtensions {
    public var backend:Dynamic;
    public var gl:Dynamic;
    public var availableExtensions:Array<String>;
    public var extensions:Map<String, Dynamic>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.availableExtensions = this.gl.getSupportedExtensions();
        this.extensions = new Map();
    }

    public function get(name:String):Dynamic {
        var extension:Dynamic = this.extensions.get(name);
        if (extension == null) {
            extension = this.gl.getExtension(name);
            this.extensions.set(name, extension);
        }
        return extension;
    }

    public function has(name:String):Bool {
        return Lambda.has(this.availableExtensions, name);
    }
}

Note that I've used the `Dynamic` type to represent the `gl` and `backend` variables, as their types are not explicitly defined in the JavaScript code. In Haxe, `Dynamic` is a type that can hold any value, similar to `Object` in JavaScript.

I've also used the `Map` class to implement the `extensions` object, which is similar to a JavaScript object with string keys.

Additionally, I've used the `Lambda.has` function to implement the `has` method, which is similar to the `includes` method in JavaScript.

You can use this class in your Haxe code like this:

var webGlExtensions = new WebGLExtensions(backend);
var extension = webGlExtensions.get("some_extension");
if (webGlExtensions.has("some_extension")) {
    // do something
}