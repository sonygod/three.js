class WebGLExtensions {
	public var backend:Dynamic;
	public var gl:Dynamic;
	public var availableExtensions:Array<String>;
	public var extensions:Map<String,Dynamic>;

	public function new(backend:Dynamic) {
		this.backend = backend;
		this.gl = backend.gl;
		this.availableExtensions = gl.getSupportedExtensions();
		this.extensions = new Map<String,Dynamic>();
	}

	public function get(name:String):Dynamic {
		if (!extensions.exists(name)) {
			extensions.set(name, gl.getExtension(name));
		}
		return extensions.get(name);
	}

	public function has(name:String):Bool {
		return availableExtensions.contains(name);
	}
}