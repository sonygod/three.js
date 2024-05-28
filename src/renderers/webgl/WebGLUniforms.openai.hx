package three.js.src.renderers.webgl;

import haxe.Timer;

import three.textures.CubeTexture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.textures.Texture;

class WebGLUniforms {
    public var seq:Array<Dynamic>;
    public var map:Map<String, Dynamic>;

    public function new(gl: WebGLRenderingContext, program: WebGLProgram) {
        seq = [];
        map = new Map<String, Dynamic>();

        var n = gl.getParameter(gl.ACTIVE_UNIFORMS);
        for (i in 0...n) {
            var info = gl.getActiveUniform(program, i);
            var addr = gl.getUniformLocation(program, info.name);
            parseUniform(info, addr, this);
        }
    }

    public function setValue(gl: WebGLRenderingContext, name: String, value: Dynamic, textures: Dynamic) {
        var u = map.get(name);
        if (u != null) u.setValue(gl, value, textures);
    }

    public function setOptional(gl: WebGLRenderingContext, object: Dynamic, name: String) {
        var v = object.get(name);
        if (v != null) setValue(gl, name, v);
    }

    public static function upload(gl: WebGLRenderingContext, seq: Array<Dynamic>, values: Dynamic, textures: Dynamic) {
        for (i in 0...seq.length) {
            var u = seq[i];
            var v = values.get(u.id);
            if (v.needsUpdate != false) {
                // note: always updating when .needsUpdate is undefined
                u.setValue(gl, v.value, textures);
            }
        }
    }

    public static function seqWithValue(seq: Array<Dynamic>, values: Dynamic) {
        var r = [];
        for (i in 0...seq.length) {
            var u = seq[i];
            if (values.exists(u.id)) r.push(u);
        }
        return r;
    }
}

class SingleUniform {
    public var id: String;
    public var addr: WebGLUniformLocation;
    public var cache: Array<Dynamic>;
    public var type: Int;
    public var setValue: (gl: WebGLRenderingContext, value: Dynamic, textures: Dynamic) -> Void;

    public function new(id: String, activeInfo: WebGLActiveInfo, addr: WebGLUniformLocation) {
        this.id = id;
        this.addr = addr;
        cache = [];
        type = activeInfo.type;
        setValue = getSingularSetter(activeInfo.type);
    }
}

class PureArrayUniform {
    public var id: String;
    public var addr: WebGLUniformLocation;
    public var cache: Array<Dynamic>;
    public var type: Int;
    public var size: Int;
    public var setValue: (gl: WebGLRenderingContext, value: Dynamic, textures: Dynamic) -> Void;

    public function new(id: String, activeInfo: WebGLActiveInfo, addr: WebGLUniformLocation) {
        this.id = id;
        this.addr = addr;
        cache = [];
        type = activeInfo.type;
        size = activeInfo.size;
        setValue = getPureArraySetter(activeInfo.type);
    }
}

class StructuredUniform {
    public var id: String;
    public var seq: Array<Dynamic>;
    public var map: Map<String, Dynamic>;

    public function new(id: String) {
        this.id = id;
        seq = [];
        map = new Map<String, Dynamic>();
    }

    public function setValue(gl: WebGLRenderingContext, value: Dynamic, textures: Dynamic) {
        for (u in seq) {
            u.setValue(gl, value[u.id], textures);
        }
    }
}

function parseUniform(activeInfo: WebGLActiveInfo, addr: WebGLUniformLocation, container: StructuredUniform) {
    var path = activeInfo.name;
    var pathLength = path.length;
    var re = ~/(\w+)(\))?(\[|\.)?/g;
    re.lastIndex = 0;

    while (true) {
        var match = re.exec(path);
        var matchEnd = re.lastIndex;
        var id = match[1];
        var idIsIndex = match[2] != null;
        var subscript = match[3];

        if (idIsIndex) id = Std.parseInt(id); // convert to integer

        if (subscript == null || subscript == '[' && matchEnd + 2 == pathLength) {
            // bare name or "pure" bottom-level array "[0]" suffix
            addUniform(container, subscript == null ?
                new SingleUniform(id, activeInfo, addr) :
                new PureArrayUniform(id, activeInfo, addr));
            break;
        } else {
            // step into inner node / create it in case it doesn't exist
            var map = container.map;
            var next = map.get(id);

            if (next == null) {
                next = new StructuredUniform(id);
                addUniform(container, next);
            }

            container = next;
        }
    }
}

function addUniform(container: StructuredUniform, uniformObject: Dynamic) {
    container.seq.push(uniformObject);
    container.map.set(uniformObject.id, uniformObject);
}

function getSingularSetter(type: Int): (gl: WebGLRenderingContext, value: Dynamic, textures: Dynamic) -> Void {
    switch (type) {
        case 0x1406: // FLOAT
            return setValueV1f;
        case 0x8b50: // _VEC2
            return setValueV2f;
        case 0x8b51: // _VEC3
            return setValueV3f;
        case 0x8b52: // _VEC4
            return setValueV4f;
        // ...
    }
    return null;
}

function getPureArraySetter(type: Int): (gl: WebGLRenderingContext, value: Dynamic, textures: Dynamic) -> Void {
    switch (type) {
        case 0x1406: // FLOAT
            return setValueV1fArray;
        case 0x8b50: // _VEC2
            return setValueV2fArray;
        case 0x8b51: // _VEC3
            return setValueV3fArray;
        case 0x8b52: // _VEC4
            return setValueV4fArray;
        // ...
    }
    return null;
}