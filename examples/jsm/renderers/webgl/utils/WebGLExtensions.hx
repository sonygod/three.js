package three.js.examples.jm.renderers.webgl.utils;

class WebGLExtensions {
    public var backend:Dynamic;
    public var gl:Dynamic;
    public var availableExtensions:Array<String>;
    public var extensions:Map<String, Dynamic>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.gl = backend.gl;
        this.availableExtensions = this.gl.getSupportedExtensions();
        this.extensions = new Map<String, Dynamic>();
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