// Haxe does not have a direct equivalent of JavaScript's import statement,
// so you will need to include the necessary classes in your project or compile them with this file.

// ... include or import necessary classes here ...

class WebGLUniforms {
    public var seq:Array<Dynamic> = [];
    public var map:haxe.ds.StringMap = new haxe.ds.StringMap();

    public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
        var n:Int = gl.getProgramParameter(program, WebGLRenderingContext.ACTIVE_UNIFORMS);

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

    public function setOptional(gl:WebGLRenderingContext, obj:Dynamic, prop:String) {
        var v:Dynamic = Reflect.field(obj, prop);
        if (v != null) this.setValue(gl, prop, v);
    }

    public static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:Dynamic, textures:Dynamic) {
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            var v:Dynamic = Reflect.field(values, u.id);
            if (v.needsUpdate == null || v.needsUpdate == true) {
                u.setValue(gl, v.value, textures);
            }
        }
    }

    public static function seqWithValue(seq:Array<Dynamic>, values:Dynamic):Array<Dynamic> {
        var r:Array<Dynamic> = [];
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            if (Reflect.hasField(values, u.id)) r.push(u);
        }
        return r;
    }
}

// Helper methods and classes such as flatten, arraysEqual, copyArray, allocTexUnits,
// SingleUniform, PureArrayUniform, StructuredUniform, parseUniform, and getSingularSetter,
// getPureArraySetter would also need to be translated to Haxe.

// ... include helper methods and classes here ...