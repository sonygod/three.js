class WebGLCapabilities {
	public var maxAnisotropy:Int;
	public function new(backend:Dynamic) {
		this.maxAnisotropy = null;
	}
	public function getMaxAnisotropy():Int {
		if (this.maxAnisotropy != null) {
			return this.maxAnisotropy;
		}
		var gl = backend.gl;
		var extensions = backend.extensions;
		if (extensions.has("EXT_texture_filter_anisotropic")) {
			var extension = extensions.get("EXT_texture_filter_anisotropic");
			this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		} else {
			this.maxAnisotropy = 0;
		}
		return this.maxAnisotropy;
	}
}