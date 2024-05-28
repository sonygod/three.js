import js.Browser.Window;

class WebGLExtensions {
    static var extensions:Array<String> = [];
    static inline function getExtension(gl:WebGLRenderer, name:String):Dynamic {
        if (extensions.indexOf(name) >= 0) {
            return null;
        }
        extensions.push(name);
        var extension:Dynamic;
        switch (name) {
            case "WEBGL_depth_texture":
                extension = gl.getExtension("WEBGL_depth_texture") || gl.getExtension("MOZ_WEBGL_depth_texture") || gl.getExtension("WEBKIT_WEBGL_depth_texture");
                break;
            case "EXT_texture_filter_anisotropic":
                extension = gl.getExtension("EXT_texture_filter_anisotropic") || gl.getExtension("MOZ_EXT_texture_filter_anisotropic") || gl.getExtension("WEBKIT_EXT_texture_filter_anisotropic");
                break;
            case "WEBGL_compressed_texture_s3tc":
                extension = gl.getExtension("WEBGL_compressed_texture_s3tc") || gl.getExtension("MOZ_WEBGL_compressed_texture_s3tc") || gl.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");
                break;
            case "WEBGL_compressed_texture_pvrtc":
                extension = gl.getExtension("WEBGL_compressed_texture_pvrtc") || gl.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");
                break;
            default:
                extension = gl.getExtension(name);
        }
        return extension;
    }
    static function has(name:String):Bool {
        return getExtension(Window.context, name) != null;
    }
    static function init():Void {
        getExtension(Window.context, "EXT_color_buffer_float");
        getExtension(Window.context, "WEBGL_clip_cull_distance");
        getExtension(Window.context, "OES_texture_float_linear");
        getExtension(Window.context, "EXT_color_buffer_half_float");
        getExtension(Window.context, "WEBGL_multisampled_render_to_texture");
        getExtension(Window.context, "WEBGL_render_shared_exponent");
    }
    static function get(name:String):Dynamic {
        var extension:Dynamic = getExtension(Window.context, name);
        if (extension == null) {
            trace("THREE.WebGLRenderer: " + name + " extension not supported.");
        }
        return extension;
    }
}