import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.constants.LessEqualCompare;

class WebGLUniforms {
    public var seq: Array<Dynamic>;
    public var map: Map<Dynamic, Dynamic>;

    public function new(gl: WebGLRenderingContext, program: WebGLProgram) {
        this.seq = [];
        this.map = new Map();

        var n = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

        for (i in 0...n) {
            var info = gl.getActiveUniform(program, i);
            var addr = gl.getUniformLocation(program, info.name);

            parseUniform(info, addr, this);
        }
    }

    public function setValue(gl: WebGLRenderingContext, name: String, value: Dynamic, textures: Map<Dynamic, Dynamic>) {
        var u = this.map[name];

        if (u != null) u.setValue(gl, value, textures);
    }

    public function setOptional(gl: WebGLRenderingContext, object: Dynamic, name: String) {
        var v = Reflect.field(object, name);

        if (v != null) this.setValue(gl, name, v);
    }

    public static function upload(gl: WebGLRenderingContext, seq: Array<Dynamic>, values: Map<Dynamic, Dynamic>, textures: Map<Dynamic, Dynamic>) {
        for (i in 0...seq.length) {
            var u = seq[i];
            var v = values[u.id];

            if (v.needsUpdate != false) {
                u.setValue(gl, v.value, textures);
            }
        }
    }

    public static function seqWithValue(seq: Array<Dynamic>, values: Map<Dynamic, Dynamic>): Array<Dynamic> {
        var r = [];

        for (i in 0...seq.length) {
            var u = seq[i];
            if (u.id in values) r.push(u);
        }

        return r;
    }
}

class SingleUniform {
    public var id: Dynamic;
    public var addr: WebGLUniformLocation;
    public var cache: Array<Dynamic>;
    public var type: Int;
    public var setValue: Dynamic;

    public function new(id: Dynamic, activeInfo: Dynamic, addr: WebGLUniformLocation) {
        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.setValue = getSingularSetter(activeInfo.type);
    }
}

class PureArrayUniform {
    public var id: Dynamic;
    public var addr: WebGLUniformLocation;
    public var cache: Array<Dynamic>;
    public var type: Int;
    public var size: Int;
    public var setValue: Dynamic;

    public function new(id: Dynamic, activeInfo: Dynamic, addr: WebGLUniformLocation) {
        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.size = activeInfo.size;
        this.setValue = getPureArraySetter(activeInfo.type);
    }
}

class StructuredUniform {
    public var id: Dynamic;
    public var seq: Array<Dynamic>;
    public var map: Map<Dynamic, Dynamic>;

    public function new(id: Dynamic) {
        this.id = id;
        this.seq = [];
        this.map = new Map();
    }

    public function setValue(gl: WebGLRenderingContext, value: Dynamic, textures: Map<Dynamic, Dynamic>) {
        for (i in 0...this.seq.length) {
            var u = this.seq[i];
            u.setValue(gl, value[u.id], textures);
        }
    }
}

function parseUniform(activeInfo: Dynamic, addr: WebGLUniformLocation, container: Dynamic) {
    var path = activeInfo.name,
        pathLength = path.length;

    while (true) {
        var match = RePathPart.match(path),
            matchEnd = RePathPart.pos;

        var id = match[1];
        var idIsIndex = match[2] == ']';
        var subscript = match[3];

        if (idIsIndex) id = Std.int(id);

        if (subscript == null || subscript == '[' && matchEnd + 2 == pathLength) {
            addUniform(container, subscript == null ?
                new SingleUniform(id, activeInfo, addr) :
                new PureArrayUniform(id, activeInfo, addr));

            break;
        } else {
            var map = container.map;
            var next = map[id];

            if (next == null) {
                next = new StructuredUniform(id);
                addUniform(container, next);
            }

            container = next;
        }
    }
}

function addUniform(container: Dynamic, uniformObject: Dynamic) {
    container.seq.push(uniformObject);
    container.map[uniformObject.id] = uniformObject;
}