package three.js.src.renderers.webgl;

class WebGLUniforms {

    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
        seq = [];
        map = new Map();

        var n:Int = gl.getParameter(program, WebGLRenderingContext.ACTIVE_UNIFORMS);

        for (i in 0...n) {
            var info:WebGLActiveInfo = gl.getActiveUniform(program, i);
            var addr:WebGLUniformLocation = gl.getUniformLocation(program, info.name);
            parseUniform(info, addr, this);
        }
    }

    public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:Dynamic) {
        var u:Dynamic = map.get(name);
        if (u != null) u.setValue(gl, value, textures);
    }

    public function setOptional(gl:WebGLRenderingContext, object:Dynamic, name:String) {
        var v:Dynamic = Reflect.field(object, name);
        if (v != null) setValue(gl, name, v, null); // assuming textures is optional
    }

    public static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:Dynamic, textures:Dynamic) {
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            var v:Dynamic = Reflect.field(values, u.id);
            if (v.needsUpdate != false) { // note: always updating when .needsUpdate is undefined
                u.setValue(gl, v.value, textures);
            }
        }
    }

    public static function seqWithValue(seq:Array<Dynamic>, values:Dynamic) {
        var r:Array<Dynamic> = [];
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            if (Reflect.hasField(values, u.id)) r.push(u);
        }
        return r;
    }
}