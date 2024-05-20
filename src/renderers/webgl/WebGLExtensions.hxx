import js.Browser;
import js.Lib;

class WebGLExtensions {

    var extensions:Map<String, Dynamic>;
    var gl:Dynamic;

    public function new(gl:Dynamic) {
        this.gl = gl;
        this.extensions = new Map();
    }

    private function getExtension(name:String):Dynamic {
        if (this.extensions.exists(name)) {
            return this.extensions.get(name);
        }

        var extension:Dynamic;

        switch (name) {
            case 'WEBGL_depth_texture':
                extension = this.gl.getExtension('WEBGL_depth_texture') || this.gl.getExtension('MOZ_WEBGL_depth_texture') || this.gl.getExtension('WEBKIT_WEBGL_depth_texture');
                break;
            case 'EXT_texture_filter_anisotropic':
                extension = this.gl.getExtension('EXT_texture_filter_anisotropic') || this.gl.getExtension('MOZ_EXT_texture_filter_anisotropic') || this.gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic');
                break;
            case 'WEBGL_compressed_texture_s3tc':
                extension = this.gl.getExtension('WEBGL_compressed_texture_s3tc') || this.gl.getExtension('MOZ_WEBGL_compressed_texture_s3tc') || this.gl.getExtension('WEBKIT_WEBGL_compressed_texture_s3tc');
                break;
            case 'WEBGL_compressed_texture_pvrtc':
                extension = this.gl.getExtension('WEBGL_compressed_texture_pvrtc') || this.gl.getExtension('WEBKIT_WEBGL_compressed_texture_pvrtc');
                break;
            default:
                extension = this.gl.getExtension(name);
        }

        this.extensions.set(name, extension);
        return extension;
    }

    public function has(name:String):Bool {
        return this.getExtension(name) !== null;
    }

    public function init():Void {
        this.getExtension('EXT_color_buffer_float');
        this.getExtension('WEBGL_clip_cull_distance');
        this.getExtension('OES_texture_float_linear');
        this.getExtension('EXT_color_buffer_half_float');
        this.getExtension('WEBGL_multisampled_render_to_texture');
        this.getExtension('WEBGL_render_shared_exponent');
    }

    public function get(name:String):Dynamic {
        var extension = this.getExtension(name);
        if (extension === null) {
            js.Lib.warnOnce('THREE.WebGLRenderer: ' + name + ' extension not supported.');
        }
        return extension;
    }
}