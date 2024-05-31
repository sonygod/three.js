import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLExtension;
import js.html.webgl.WebGLTextureFilterAnisotropicExtension;
import js.html.Map;

class WebGLCapabilities {

    var backend:WebGLRenderingContext;
    var maxAnisotropy:Null<Float>;

    public function new(backend:WebGLRenderingContext) {
        this.backend = backend;
        this.maxAnisotropy = null;
    }

    public function getMaxAnisotropy():Float {
        if (this.maxAnisotropy != null) return this.maxAnisotropy;

        var gl:WebGLRenderingContext = this.backend;
        var extensions:Map<String, WebGLExtension> = this.backend.getSupportedExtensions();

        if (extensions.exists('EXT_texture_filter_anisotropic')) {
            var extension:WebGLTextureFilterAnisotropicExtension = cast extensions.get('EXT_texture_filter_anisotropic');
            this.maxAnisotropy = gl.getParameter(extension.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        } else {
            this.maxAnisotropy = 0;
        }

        return this.maxAnisotropy;
    }

}