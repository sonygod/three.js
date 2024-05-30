class WebGLCapabilities {

	var backend:Backend;
	var maxAnisotropy:Null<Float>;

	public function new(backend:Backend) {
		this.backend = backend;
		this.maxAnisotropy = null;
	}

	public function getMaxAnisotropy():Float {
		if (this.maxAnisotropy !== null) return this.maxAnisotropy;

		var gl = this.backend.gl;
		var extensions = this.backend.extensions;

		if (extensions.has('EXT_texture_filter_anisotropic') == true) {
			var extension = extensions.get('EXT_texture_filter_anisotropic');
			this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		} else {
			this.maxAnisotropy = 0;
		}

		return this.maxAnisotropy;
	}
}