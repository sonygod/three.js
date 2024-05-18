package three.js.examples.jsm.renderers.webgl.utils;

import js.html.webgl.RenderingContext;

class WebGLCapabilities {
    public var backend:Dynamic;
    public var maxAnisotropy:Null<Float>;

    public function new(backend:Dynamic) {
        this.backend = backend;
        this.maxAnisotropy = null;
    }

    public function getMaxAnisotropy():Float {
        if (this.maxAnisotropy != null) return this.maxAnisotropy;

        var gl:RenderingContext = backend.gl;
        var extensions:Dynamic = backend.extensions;

        if (extensions.has('EXT_texture_filter_anisotropic')) {
            var extension:Dynamic = extensions.get('EXT_texture_filter_anisotropic');
            this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else {
            this.maxAnisotropy = 0;
        }

        return this.maxAnisotropy;
    }
}