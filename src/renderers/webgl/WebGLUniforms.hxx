package three.renderers.webgl;

import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.constants.LessEqualCompare;

class WebGLUniforms {
    private var seq:Array<Dynamic>;
    private var map:Map<String, Dynamic>;

    public function new(gl:WebGLRenderingContext, program:WebGLProgram) {
        seq = [];
        map = new Map();

        var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

        for (i in 0...n) {
            var info = gl.getActiveUniform(program, i);
            var addr = gl.getUniformLocation(program, info.name);

            parseUniform(info, addr, this);
        }
    }

    public function setValue(gl:WebGLRenderingContext, name:String, value:Dynamic, textures:Dynamic) {
        var u = map[name];

        if (u !== undefined) u.setValue(gl, value, textures);
    }

    public function setOptional(gl:WebGLRenderingContext, object:Dynamic, name:String) {
        var v = object[name];

        if (v !== undefined) this.setValue(gl, name, v);
    }

    static function upload(gl:WebGLRenderingContext, seq:Array<Dynamic>, values:Dynamic, textures:Dynamic) {
        for (i in 0...seq.length) {
            var u = seq[i];
            var v = values[u.id];

            if (v.needsUpdate !== false) {
                u.setValue(gl, v.value, textures);
            }
        }
    }

    static function seqWithValue(seq:Array<Dynamic>, values:Dynamic):Array<Dynamic> {
        var r = [];

        for (i in 0...seq.length) {
            var u = seq[i];
            if (u.id in values) r.push(u);
        }

        return r;
    }

    private function parseUniform(activeInfo:Dynamic, addr:Dynamic, container:Dynamic) {
        var path = activeInfo.name;
        var pathLength = path.length;

        var RePathPart = /(\w+)(\])?(\[|\.)?/g;
        RePathPart.lastIndex = 0;

        while (true) {
            var match = RePathPart.exec(path);
            var matchEnd = RePathPart.lastIndex;

            var id = match[1];
            var idIsIndex = match[2] === ']';
            var subscript = match[3];

            if (idIsIndex) id = Std.parseInt(id);

            if (subscript === undefined || subscript === '[' && matchEnd + 2 === pathLength) {
                addUniform(container, subscript === undefined ?
                    new SingleUniform(id, activeInfo, addr) :
                    new PureArrayUniform(id, activeInfo, addr));

                break;
            } else {
                var map = container.map;
                var next = map[id];

                if (next === undefined) {
                    next = new StructuredUniform(id);
                    addUniform(container, next);
                }

                container = next;
            }
        }
    }

    private function addUniform(container:Dynamic, uniformObject:Dynamic) {
        container.seq.push(uniformObject);
        container.map[uniformObject.id] = uniformObject;
    }
}

class SingleUniform {
    public var id:Int;
    public var addr:Int;
    public var cache:Array<Float>;
    public var type:Int;
    public var setValue:Dynamic;

    public function new(id:Int, activeInfo:Dynamic, addr:Int) {
        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.setValue = getSingularSetter(activeInfo.type);
    }
}

class PureArrayUniform {
    public var id:Int;
    public var addr:Int;
    public var cache:Array<Float>;
    public var type:Int;
    public var size:Int;
    public var setValue:Dynamic;

    public function new(id:Int, activeInfo:Dynamic, addr:Int) {
        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.size = activeInfo.size;
        this.setValue = getPureArraySetter(activeInfo.type);
    }
}

class StructuredUniform {
    public var id:Int;
    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(id:Int) {
        this.id = id;
        this.seq = [];
        this.map = new Map();
    }

    public function setValue(gl:WebGLRenderingContext, value:Dynamic, textures:Dynamic) {
        var seq = this.seq;

        for (i in 0...seq.length) {
            var u = seq[i];
            u.setValue(gl, value[u.id], textures);
        }
    }
}

// 其他辅助函数和类...