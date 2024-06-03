import three.RGBA_ASTC_4x4_Format;
import three.RGBA_ASTC_5x4_Format;
// ... and other imports ...
import three.UnsignedByteType;
import three.NoColorSpace;

class WebGLUtils {

    public var backend:Backend;
    public var gl:WebGLRenderingContext;
    public var extensions:Map<String, any>;

    public function new(backend:Backend) {
        this.backend = backend;
        this.gl = this.backend.gl;
        this.extensions = backend.extensions;
    }

    public function convert(p:Dynamic, colorSpace:Int = NoColorSpace):Dynamic {

        var extension:Dynamic = null;

        switch(p) {
            case UnsignedByteType:
                return gl.UNSIGNED_BYTE;
            // ... and other cases ...
            case HalfFloatType:
                return gl.HALF_FLOAT;
            // ... and other cases ...
            case RGBA_S3TC_DXT1_Format:
            case RGBA_S3TC_DXT3_Format:
            case RGBA_S3TC_DXT5_Format:
                if (colorSpace == SRGBColorSpace) {
                    // ... and the rest of the S3TC cases ...
                }
            // ... and other cases ...
            case RGBA_ASTC_4x4_Format:
            case RGBA_ASTC_5x4_Format:
            // ... and the rest of the ASTC cases ...
                if (colorSpace == SRGBColorSpace) {
                    // ... and the rest of the ASTC cases ...
                }
            // ... and other cases ...
            default:
                return (gl[p] != null) ? gl[p] : null;
        }
    }

    public function _clientWaitAsync():Promise<Void> {

        var sync = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0);
        gl.flush();

        return new Promise<Void>((resolve, reject) => {

            function test() {
                var res = gl.clientWaitSync(sync, gl.SYNC_FLUSH_COMMANDS_BIT, 0);
                if (res == gl.WAIT_FAILED) {
                    gl.deleteSync(sync);
                    reject(null);
                    return;
                }
                if (res == gl.TIMEOUT_EXPIRED) {
                    js.Browser.requestAnimationFrame(test);
                    return;
                }
                gl.deleteSync(sync);
                resolve(null);
            }

            test();
        });
    }
}