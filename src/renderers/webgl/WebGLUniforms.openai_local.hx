import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.DepthTexture;
import three.constants.LessEqualCompare;

class WebGLUniforms {
    public static var emptyTexture = new Texture();
    public static var emptyShadowTexture:DepthTexture = (function() {
        var texture = new DepthTexture(1, 1);
        texture.compareFunction = LessEqualCompare;
        return texture;
    })();
    public static var emptyArrayTexture = new DataArrayTexture();
    public static var empty3dTexture = new Data3DTexture();
    public static var emptyCubeTexture = new CubeTexture();

    // --- Utilities ---

    // Array Caches (provide typed arrays for temporary by size)
    public static var arrayCacheF32:Array<Float32Array> = [];
    public static var arrayCacheI32:Array<Int32Array> = [];

    // Float32Array caches used for uploading Matrix uniforms
    public static var mat4array:Float32Array = new Float32Array(16);
    public static var mat3array:Float32Array = new Float32Array(9);
    public static var mat2array:Float32Array = new Float32Array(4);

    // Flattening for arrays of vectors and matrices
    public static function flatten(array:Array<Dynamic>, nBlocks:Int, blockSize:Int):Float32Array {
        var firstElem = array[0];
        if (firstElem <= 0 || firstElem > 0) return array;
        
        var n = nBlocks * blockSize;
        var r = arrayCacheF32[n];
        if (r == null) {
            r = new Float32Array(n);
            arrayCacheF32[n] = r;
        }

        if (nBlocks != 0) {
            firstElem.toArray(r, 0);
            for (i in 1...nBlocks) {
                var offset = blockSize * i;
                array[i].toArray(r, offset);
            }
        }
        return r;
    }

    public static function arraysEqual(a:Array<Dynamic>, b:Array<Dynamic>):Bool {
        if (a.length != b.length) return false;
        for (i in 0...a.length) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    public static function copyArray(a:Array<Dynamic>, b:Array<Dynamic>):Void {
        for (i in 0...b.length) {
            a[i] = b[i];
        }
    }

    // Texture unit allocation
    public static function allocTexUnits(textures:Dynamic, n:Int):Int32Array {
        var r = arrayCacheI32[n];
        if (r == null) {
            r = new Int32Array(n);
            arrayCacheI32[n] = r;
        }
        for (i in 0...n) {
            r[i] = textures.allocateTextureUnit();
        }
        return r;
    }

    // --- Setters ---

    // Single scalar
    public static function setValueV1f(gl:Dynamic, v:Float):Void {
        var cache = this.cache;
        if (cache[0] == v) return;
        gl.uniform1f(this.addr, v);
        cache[0] = v;
    }

    // Single float vector (from flat array or THREE.VectorN)
    public static function setValueV2f(gl:Dynamic, v:Dynamic):Void {
        var cache = this.cache;
        if (v.x != null) {
            if (cache[0] != v.x || cache[1] != v.y) {
                gl.uniform2f(this.addr, v.x, v.y);
                cache[0] = v.x;
                cache[1] = v.y;
            }
        } else {
            if (arraysEqual(cache, v)) return;
            gl.uniform2fv(this.addr, v);
            copyArray(cache, v);
        }
    }

    // Other setter methods follow the same pattern...
}