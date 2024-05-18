package renderers.webgl;

import haxe.ds.StringMap;

class WebGLUtils {
    private var gl:GL;
    private var extensions:StringMap<GLExtension>;

    public function new(gl:GL, extensions:StringMap<GLExtension>) {
        this.gl = gl;
        this.extensions = extensions;
    }

    private function convert(p:Dynamic, ?colorSpace:Int = NoColorSpace):Int {
        var extension:GLExtension;
        var transfer:Int = ColorManagement.getTransfer(colorSpace);

        // ... (rest of the code remains the same)

        // WebGL2 formats.

        if (p == RedFormat) return gl.RED;
        if (p == RedIntegerFormat) return gl.RED_INTEGER;
        if (p == RGFormat) return gl.RG;
        if (p == RGIntegerFormat) return gl.RG_INTEGER;
        if (p == RGBAIntegerFormat) return gl.RGBA_INTEGER;

        // ... (rest of the code remains the same)

        return null;
    }

    public function getConvert():Dynamic {
        return { convert: convert };
    }
}