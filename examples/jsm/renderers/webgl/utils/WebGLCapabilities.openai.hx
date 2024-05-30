package three.js.examples.javascript.renderers.webgl.utils;

class WebGLCapabilities {
    public var backend:Backend; // assuming Backend is a type
    public var maxAnisotropy:Null<Int>;

    public function new(backend:Backend) {
        this.backend = backend;
        this.maxAnisotropy = null;
    }

    public function getMaxAnisotropy():Int {
        if (this.maxAnisotropy != null) return this.maxAnisotropy;

        var gl = this.backend.gl;
        var extensions = this.backend.extensions;

        if (extensions.exists('EXT_texture_filter_anisotropic')) {
            var extension = extensions.get('EXT_texture_filter_anisotropic');
            this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else {
            this.maxAnisotropy = 0;
        }

        return this.maxAnisotropy;
    }
}