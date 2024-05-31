import js.html.webgl.WebGLRenderingContext;

class WebGLExtensions {

    public var backend;
    public var gl:WebGLRenderingContext;
    public var availableExtensions:Array<String>;
    public var extensions:Map<String, Dynamic>;

    public function new(backend:Dynamic) {

        this.backend = backend;

        this.gl = this.backend.gl;
        this.availableExtensions = this.gl.getSupportedExtensions();

        this.extensions = new Map<String, Dynamic>();

    }

    public function get(name:String):Dynamic {

        var extension = this.extensions.get(name);

        if (extension == null) {

            extension = this.gl.getExtension(name);

        }

        return extension;

    }

    public function has(name:String):Bool {

        return this.availableExtensions.indexOf(name) != -1;

    }

}