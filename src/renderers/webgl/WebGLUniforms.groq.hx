package three.js.src.renderers.webgl;

import haxe.io.Float32Array;
import haxe.io.Int32Array;
import haxe.io.UInt32Array;
import three.Texture;
import three.CubeTexture;
import three.DataArrayTexture;
import three.Data3DTexture;
import three.DepthTexture;

class WebGLUniforms {
    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
        seq = [];
        map = new Map<String, Dynamic>();

        var n:Int = gl.getParameter(gl.ACTIVE_UNIFORMS);

        for (i in 0...n) {
            var info:WebGLActiveInfo = gl.getActiveUniform(program, i);
            var addr:WebGLUniformLocation = gl.getUniformLocation(program, info.name);

            parseUniform(info, addr, this);
        }
    }

    public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:TextureCollector) {
        var u:Dynamic = map.get(name);
        if (u != null) u.setValue(gl, value, textures);
    }

    public function setOptional(gl:WebGLRenderingContext, object:Dynamic, name:String) {
        var v:Dynamic = object.get(name);
        if (v != null) setValue(gl, name, v, null);
    }

    public static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:Dynamic, textures:TextureCollector) {
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            var v:Dynamic = values.get(u.id);
            if (v.needsUpdate != false) {
                u.setValue(gl, v.value, textures);
            }
        }
    }

    public static function seqWithValue(seq:Array<Dynamic>, values:Dynamic) {
        var r:Array<Dynamic> = [];

        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            if (values.exists(u.id)) r.push(u);
        }

        return r;
    }
}

class Uniform {
    public var id:String;
    public var addr:WebGLUniformLocation;
    public var cache:Array<Float>;
    public var type:Int;
    public var setValue:Dynamic->Void;

    public function new(id:String, activeInfo:WebGLActiveInfo, addr:WebGLUniformLocation) {
        this.id = id;
        this.addr = addr;
        cache = [];
        type = activeInfo.type;
        setValue = getSetter(type);
    }
}

class PureArrayUniform extends Uniform {
    public var size:Int;

    public function new(id:String, activeInfo:WebGLActiveInfo, addr:WebGLUniformLocation) {
        super(id, activeInfo, addr);
        size = activeInfo.size;
        setValue = getPureArraySetter(type);
    }
}

class StructuredUniform {
    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(id:String) {
        this.seq = [];
        this.map = new Map<String, Dynamic>();
    }

    public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:TextureCollector) {
        for (i in 0...seq.length) {
            var u:Dynamic = seq[i];
            u.setValue(gl, value[u.id], textures);
        }
    }
}

class TextureCollector {
    public var textures:Array<Texture>;

    public function new() {
        textures = [];
    }

    public function allocateTextureUnit():Int {
        return textures.length;
    }

    public function setTexture2D(texture:Texture, unit:Int) {
        textures[unit] = texture;
    }

    public function setTexture3D(texture:Texture, unit:Int) {
        textures[unit] = texture;
    }

    public function setTextureCube(texture:CubeTexture, unit:Int) {
        textures[unit] = texture;
    }

    public function setTexture2DArray(texture:DataArrayTexture, unit:Int) {
        textures[unit] = texture;
    }
}

function getSetter(type:Int):Dynamic->Void {
    switch (type) {
        case 0x1406: return setValueV1f;
        case 0x8b50: return setValueV2f;
        case 0x8b51: return setValueV3f;
        case 0x8b52: return setValueV4f;
        // ...
    }
}

function getPureArraySetter(type:Int):Dynamic->Void {
    switch (type) {
        case 0x1406: return setValueV1fArray;
        case 0x8b50: return setValueV2fArray;
        case 0x8b51: return setValueV3fArray;
        case 0x8b52: return setValueV4fArray;
        // ...
    }
}

// Helper functions
function flatten(array:Array<Dynamic>, nBlocks:Int, blockSize:Int):Float32Array {
    // ...
}

function arraysEqual(a:Array<Dynamic>, b:Array<Dynamic>):Bool {
    // ...
}

function copyArray(a:Array<Dynamic>, b:Array<Dynamic>):Void {
    // ...
}

function allocTexUnits(textures:TextureCollector, n:Int):Int32Array {
    // ...
}

function setValueV1f(gl:WebGLRenderingContext, v:Float) {
    // ...
}

function setValueV2f(gl:WebGLRenderingContext, v:Array<Float>) {
    // ...
}

// ...