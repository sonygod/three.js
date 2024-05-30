import haxe.io.Bytes;

class VOXLoader {
    public function load(url:String, onLoad:Void->Void, onProgress:Float->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new haxe.Http(url);
        loader.onData = function(data:Bytes) {
            try {
                onLoad(scope.parse(data));
            } catch(e:Dynamic) {
                if(onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }
        loader.onError = function(status:String, response:String) {
            if(onError != null) {
                onError(response);
            } else {
                trace(response);
            }
            scope.manager.itemError(url);
        }
        loader.onProgress = function(event:ProgressEvent) {
            if(onProgress != null) {
                onProgress(event.loaded / event.total);
            }
        }
        loader.request(true);
    }

    private static DEFAULT_PALETTE:Array<Int> = [
        0x00000000, 0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff, 0xffffccff,
        0xffccccff, 0xff99ccff, 0xff66ccff, 0xff33ccff, 0xff00ccff, 0xffff99ff, 0xffcc99ff, 0xff9999ff,
        0xff6699ff, 0xff3399ff, 0xff0099ff, 0xffff66ff, 0xffcc66ff, 0xff9966ff, 0xff6666ff, 0xff3366ff,
        0xff0066ff, 0xffff33ff, 0xffcc33ff, 0xff9933ff, 0xff6633ff, 0xff3333ff, 0xff0033ff, 0xffff00ff,
        0xffcc00ff, 0xff9900ff, 0xff6600ff, 0xff3300ff, 0xff0000ff, 0xffffffcc, 0xffccffcc, 0xff99ffcc,
        0xff66ffcc, 0xff33ffcc, 0xff00ffcc, 0xffffcccc, 0xffcccccc, 0xff99cccc, 0xff66cccc, 0xff33cccc,
        0xff00cccc, 0xffff99cc, 0xffcc99cc, 0xff9999cc, 0xff6699cc, 0xff3399cc, 0xff0099cc, 0xffff66cc,
        0xffcc66cc, 0xff9966cc, 0xff6666cc, 0xff3366cc, 0xff0066cc, 0xffff33cc, 0xffcc33cc, 0xff9933cc,
        0xff6633cc, 0xff3333cc, 0xff0033cc, 0xffff00cc, 0xffcc00cc, 0xff9900cc, 0xff6600cc, 0xff3300cc,
        0xff0000cc, 0xffffff99, 0xffccff99, 0xff99ff99, 0xff66ff99, 0xff33ff99, 0xff00ff99, 0xffffcc99,
        0xffcccc99, 0xff99cc99, 0xff66cc99, 0xff33cc99, 0xff00cc99, 0xffff9999, 0xffcc9999, 0xff999999,
        0xff669999, 0xff339999, 0xff009999, 0xffff6699, 0xffcc6699, 0xff996699, 0xff666699, 0xff336699,
        0xff006699, 0xffff3399, 0xffcc3399, 0xff993399, 0xff663399, 0xff333399, 0xff003399, 0xffff0099,
        0xffcc0099, 0xff990099, 0xff660099, 0xff330099, 0xff000099, 0xffffff66, 0xffccff66, 0xff99ff66,
        0xff66ff66, 0xff33ff66, 0xff00ff66, 0xffffcc66, 0xffcccc66, 0xff99cc66, 0xff66cc66, 0xff33cc66,
        0xff00cc66, 0xffff9966, 0xffcc9966, 0xff999966, 0xff669966, 0xff339966, 0xff009966, 0xffff6666,
        0xffcc6666, 0xff996666, 0xff666666, 0xff336666, 0xff006666, 0xffff3366, 0xffcc3366, 0xff993366,
        0xff663366, 0xff333366, 0xff003366, 0xffff0066, 0xffcc0066, 0xff990066, 0xff660066, 0xff330066,
        0xff000066, 0xffffff33, 0xffccff33, 0xff99ff33, 0xff66ff33, 0xff33ff33, 0xff00ff33, 0xffffcc33,
        0xffcccc33, 0xff99cc33, 0xff66cc33, 0xff33cc33, 0xff00cc33, 0xffff9933, 0xffcc9933, 0xff999933,
        0xff669933, 0xff339933, 0xff009933, 0xffff6633, 0xffcc6633, 0xff996633, 0xff666633, 0xff336633,
        0xff006633, 0xffff3333, 0xffcc3333, 0xff993333, 0xff663333, 0xff333333, 0xff003333, 0xffff0033,
        0xffcc0033, 0xff990033, 0xff660033, 0xff330033, 0xff000033, 0xffffff00, 0xffccff00, 0xff99ff00,
        0xff66ff00, 0xff33ff00, 0xff00ff00, 0xffffcc00, 0xffcccc00, 0xff99cc00, 0xff66cc00, 0xff33cc00,
        0xff00cc00, 0xffff9900, 0xffcc9900, 0xff999900, 0xff669900, 0xff339900, 0xff009900, 0xffff6600,
        0xffcc6600, 0xff996600, 0xff666600, 0xff336600, 0xff006600, 0xffff3300, 0xffcc3300, 0xff993300,
        0xff663300, 0xff333300, 0xff003300, 0xffff0000, 0xffcc0000, 0xff990000, 0xff660000, 0xff330000,
        0xff0000ee, 0xff0000dd, 0xff0000bb, 0xff0000aa, 0xff000088, 0xff000077, 0xff000055, 0xff000044,
        0xff000022, 0xff000011, 0xff00ee00, 0xff00dd00, 0xff00bb00, 0xff00aa00, 0xff008800, 0xff007700,
        0xff005500, 0xff004400, 0xff002200, 0xff001100, 0xffee0000, 0xffdd0000, 0xffbb0000, 0xffaa0000,
        0xff880000, 0xff770000, 0xff550000, 0xff440000, 0xff220000, 0xff110000, 0xffeeeeee, 0xffdddddd,
        0xffbbbbbb, 0xffaaaaaa, 0xff888888, 0xff777777, 0xff555555, 0xff444444, 0xff222222, 0xff111111
    ];

    private function parse(data:Bytes):Array<VOXChunk> {
        var id = data.readInt32(0);
        var version = data.readInt32(4);

        if(id != 1397359580) {
            throw 'Invalid VOX file';
        }

        if(version != 150) {
            throw 'Invalid VOX file. Unsupported version: ' + version;
        }

        var i = 8;
        var chunks:Array<VOXChunk> = [];
        while(i < data.length) {
            var id = '';
            for(var j = 0; j < 4; j++) {
                id += String.fromCharCode(data.get(i++));
            }

            var chunkSize = data.readInt32(i); i += 4;
            i += 4; // childChunks

            if(id == 'SIZE') {
                var x = data.readInt32(i); i += 4;
                var y = data.readInt32(i); i += 4;
                var z = data.readInt32(i); i += 4;

                var chunk = {
                    palette: DEFAULT_PALETTE,
                    size: { x: x, y: y, z: z }
                };

                chunks.push(chunk);

                i += chunkSize - (3 * 4);
            } else if(id == 'XYZI') {
                var numVoxels = data.readInt32(i); i += 4;
                var chunk = chunks[chunks.length - 1];
                chunk.data = data.slice(i, i + numVoxels * 4);

                i += numVoxels * 4;
            } else if(id == 'RGBA') {
                var palette = [0];
                for(var j = 0; j < 256; j++) {
                    palette[j + 1] = data.readInt32(i); i += 4;
                }

                var chunk = chunks[chunks.length - 1];
                chunk.palette = palette;
            } else {
                i += chunkSize;
            }
        }

        return chunks;
    }
}

class VOXMesh extends Mesh {
    public function new(chunk:VOXChunk) {
        var data = chunk.data;
        var size = chunk.size;
        var palette = chunk.palette;

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        var nx = [0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1];
        var px = [1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0];
        var py = [0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1];
        var ny = [0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0];
        var nz = [0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0];
        var pz = [0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1];

        var _color = new openfl.display.ColorTransform();

        function add(tile:Array<Int>, x:Int, y:Int, z:Int, r:Float, g:Float, b:Float) {
            x -= size.x / 2;
            y -= size.z / 2;
            z += size.y / 2;

            for(i in 0...18) {
                _color.redMultiplier = r;
                _color.greenMultiplier = g;
                _color.blueMultiplier = b;

                vertices.push(tile[i] + x);
                vertices.push(tile[i + 1] + y);
                vertices.push(tile[i + 2] + z);
                colors.push(_color.redMultiplier);
                colors.push(_color.greenMultiplier);
                colors.push(_color.blueMultiplier);
            }
        }

        // Store data in a volume for sampling
        var offsety = size.x;
        var offsetz = size.x * size.y;

        var array = new Bytes(size.x * size.y * size.z);

        for(j in 0...data.length) {
            var x = data.get(j);
            var y = data.get(j + 1);
            var z = data.get(j + 2);

            var index = x + (y * offsety) + (z * offsetz);

            array.set(index, 255);
        }

        // Construct geometry
        var hasColors = false;

        for(j in 0...data.length) {
            var x = data.get(j);
            var y = data.get(j + 1);
            var z = data.get(j + 2);
            var c = data.get(j + 3);

            var hex = palette[c];
            var r = Std.int(Std.uint(hex) >> 0 & 0xff) / 255.0;
            var g = Std.int(Std.uint(hex) >> 8 & 0xff) / 255.0;
            var b = Std.int(Std.uint(hex) >> 16 & 0xff) / 255.0;

            if(r > 0 || g > 0 || b > 0) hasColors = true;

            var index = x + (y * offsety) + (z * offsetz);

            if(array.get(index + 1) == 0 || x == size.x - 1) add(px, x, z, -y, r, g, b);
            if(array.get(index - 1) == 0 ||
            x == 0) add(nx, x, z, -y, r, g, b);
            if(array.get(index + offsety) == 0 || y == size.y - 1) add(ny, x, z, -y, r, g, b);
            if(array.get(index - offsety) == 0 || y == 0) add(py, x, z, -y, r, g, b);
            if(array.get(index + offsetz) == 0 || z == size.z - 1) add(pz, x, z, -y, r, g, b);
            if(array.get(index - offsetz) == 0 || z == 0) add(nz, x, z, -y, r, g, b);
        }

        var geometry = new openfl.display3D.IndexBuffer3D(openfl.display3D.Context3DBufferUsage.VERTEXBUFFER);
        geometry.addAttribute(openfl.display3D.Context3DVertexBufferFormat.FLOAT_3, 3, false, 0, 0);
        if(hasColors) {
            geometry.addAttribute(openfl.display3D.Context3DVertexBufferFormat.FLOAT_3, 3, false, 0, 3);
        }
        geometry.indexCount = vertices.length / 3;

        var material = new MeshStandardMaterial();

        super(geometry, material);
    }
}

class VOXData3DTexture extends Data3DTexture {
    public function new(chunk:VOXChunk) {
        var data = chunk.data;
        var size = chunk.size;

        var offsety = size.x;
        var offsetz = size.x * size.y;

        var array = new Bytes(size.x * size.y * size.z);

        for(j in 0...data.length) {
            var x = data.get(j);
            var y = data.get(j + 1);
            var z = data.get(j + 2);

            var index = x + (y * offsety) + (z * offsetz);

            array.set(index, 255);
        }

        super(array, size.x, size.y, size.z);

        this.format = openfl.display3D.Context3DTextureFormat.RED;
        this.minFilter = openfl.display3D.Context3DTextureFilter.NEAREST;
        this.magFilter = openfl.display3D.Context3DTextureFilter.LINEAR;
        this.unpackAlignment = 1;
        this.needsUpdate = true;
    }
}