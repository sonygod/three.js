class WebGLExtensions {

	var backend:Backend;
	var gl:WebGLRenderingContext;
	var availableExtensions:Array<String>;
	var extensions:Map<String,Dynamic>;

	public function new(backend:Backend) {
		this.backend = backend;
		this.gl = this.backend.gl;
		this.availableExtensions = js.Browser.cast(this.gl.getSupportedExtensions());
		this.extensions = new Map();
	}

	public function get(name:String):Dynamic {
		var extension = this.extensions.get(name);
		if (extension == null) {
			extension = this.gl.getExtension(name);
			this.extensions.set(name, extension);
		}
		return extension;
	}

	public function has(name:String):Bool {
		return this.availableExtensions.indexOf(name) != -1;
	}
}