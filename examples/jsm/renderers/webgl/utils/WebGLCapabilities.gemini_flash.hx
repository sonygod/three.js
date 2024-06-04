class WebGLCapabilities {

	public var backend:Dynamic;
	public var maxAnisotropy:Null<Int> = null;

	public function new(backend:Dynamic) {
		this.backend = backend;
	}

	public function getMaxAnisotropy():Int {
		if (maxAnisotropy != null) {
			return maxAnisotropy;
		}

		var gl = backend.gl;
		var extensions = backend.extensions;

		if (extensions.has('EXT_texture_filter_anisotropic')) {
			var extension = extensions.get('EXT_texture_filter_anisotropic');
			maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
		} else {
			maxAnisotropy = 0;
		}

		return maxAnisotropy;
	}

}