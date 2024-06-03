class WebGLExtensions {

    private var backend: Backend;
    private var gl: WebGLRenderingContext;
    private var availableExtensions: Array<String>;
    private var extensions: haxe.ds.StringMap<dynamic>;

    public function new(backend: Backend) {
        this.backend = backend;
        this.gl = this.backend.gl;
        this.availableExtensions = this.gl.getSupportedExtensions();
        this.extensions = new haxe.ds.StringMap<dynamic>();
    }

    public function get(name: String): dynamic {
        var extension = this.extensions.get(name);

        if (extension == null) {
            extension = this.gl.getExtension(name);
            this.extensions.set(name, extension);
        }

        return extension;
    }

    public function has(name: String): Bool {
        return this.availableExtensions.indexOf(name) != -1;
    }

}