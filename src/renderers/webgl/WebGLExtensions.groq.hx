package three.js.src.renderers.webgl;

import three.utils.warnOnce;

class WebGLExtensions {
    private var gl:Dynamic;
    private var extensions:Map<String, Dynamic>;

    public function new(gl:Dynamic) {
        this.gl = gl;
        this.extensions = new Map<String, Dynamic>();
    }

    private function getExtension(name:String):Dynamic {
        if (extensions.exists(name)) {
            return extensions.get(name);
        }

        var extension:Dynamic;
        switch (name) {
            case 'WEBGL_depth_texture':
                extension = gl.getExtension('WEBGL_depth_texture') || gl.getExtension('MOZ_WEBGL_depth_texture') || gl.getExtension('WEBKIT_WEBGL_depth_texture');
            case 'EXT_texture_filter_anisotropic':
                extension = gl.getExtension('EXT_texture_filter_anisotropic') || gl.getExtension('MOZ_EXT_texture_filter_anisotropic') || gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic');
            case 'WEBGL_compressed_texture_s3tc':
                extension = gl.getExtension('WEBGL_compressed_texture_s3tc') || gl.getExtension('MOZ_WEBGL_compressed_texture_s3tc') || gl.getExtension('WEBKIT_WEBGL_compressed_texture_s3tc');
            case 'WEBGL_compressed_texture_pvrtc':
                extension = gl.getExtension('WEBGL_compressed_texture_pvrtc') || gl.getExtension('WEBKIT_WEBGL_compressed_texture_pvrtc');
            default:
                extension = gl.getExtension(name);
        }

        extensions.set(name, extension);
        return extension;
    }

    public function has(name:String):Bool {
        return getExtension(name) != null;
    }

    public function init():Void {
        getExtension('EXT_color_buffer_float');
        getExtension('WEBGL_clip_cull_distance');
        getExtension('OES_texture_float_linear');
        getExtension('EXT_color_buffer_half_float');
        getExtension('WEBGL_multisampled_render_to_texture');
        getExtension('WEBGL_render_shared_exponent');
    }

    public function get(name:String):Dynamic {
        var extension:Dynamic = getExtension(name);
        if (extension == null) {
            warnOnce('THREE.WebGLRenderer: ' + name + ' extension not supported.');
        }
        return extension;
    }
}