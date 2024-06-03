import js.Browser;

class WebGLCapabilities {

    private var backend: dynamic;
    private var maxAnisotropy: Null<Float>;

    public function new(backend: dynamic) {
        this.backend = backend;
        this.maxAnisotropy = null;
    }

    public function getMaxAnisotropy(): Float {
        if (this.maxAnisotropy != null) return this.maxAnisotropy;

        var gl: dynamic = this.backend.gl;
        var extensions: dynamic = this.backend.extensions;

        if (js.Boot.dynamicField(extensions, "has")("EXT_texture_filter_anisotropic") == true) {
            var extension: dynamic = js.Boot.dynamicField(extensions, "get")("EXT_texture_filter_anisotropic");
            this.maxAnisotropy = js.Boot.dynamicField(gl, "getParameter")(js.Boot.dynamicField(extension, "MAX_TEXTURE_MAX_ANISOTROPY_EXT"));
        } else {
            this.maxAnisotropy = 0.;
        }

        return this.maxAnisotropy;
    }

}