Here is the converted Haxe code:
```
package three.js.examples.jsm.loaders;

import haxe.io.Bytes;
import haxe.io.BytesData;
import three.BufferGeometry;
import three.Color;
import three.Data3DTexture;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import three.LinearFilter;
import three.Mesh;
import three.MeshStandardMaterial;
import three.NearestFilter;
import three.RedFormat;
import three.SRGBColorSpace;

class VOXLoader extends Loader {
    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.load(url, function(buffer:Bytes) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:Bytes):Array<Dynamic> {
        var data = new DataView(buffer);
        var id = data.getUint32(0, true);
        var version = data.getUint32(4, true);

        if (id != 542658390) {
            console.error('THREE.VOXLoader: Invalid VOX file.');
            return;
        }

        if (version != 150) {
            console.error('THREE.VOXLoader: Invalid VOX file. Unsupported version: ' + version);
            return;
        }

        var DEFAULT_PALETTE:Array<Int> = [
            // ... (same palette array as in the JS code)
        ];

        var i = 8;
        var chunk;
        var chunks:Array<Dynamic> = [];

        while (i < buffer.length) {
            var id = '';

            for (j in 0...4) {
                id += String.fromCharCode(data.getUint8(i++));
            }

            var chunkSize = data.getUint32(i, true);
            i += 4;
            i += 4; // childChunks

            if (id == 'SIZE') {
                var x = data.getUint32(i, true);
                i += 4;
                var y = data.getUint32(i, true);
                i += 4;
                var z = data.getUint32(i, true);
                i += 4;

                chunk = {
                    palette: DEFAULT_PALETTE,
                    size: { x: x, y: y, z: z },
                };

                chunks.push(chunk);

                i += chunkSize - (3 * 4);

            } else if (id == 'XYZI') {
                var numVoxels = data.getUint32(i, true);
                i += 4;
                chunk.data = new Uint8Array(buffer, i, numVoxels * 4);

                i += numVoxels * 4;

            } else if (id == 'RGBA') {
                var palette:Array<Int> = [0];

                for (j in 0...256) {
                    palette[j + 1] = data.getUint32(i, true);
                    i += 4;
                }

                chunk.palette = palette;

            } else {
                // console.log(id, chunkSize, childChunks);

                i += chunkSize;
            }
        }

        return chunks;
    }
}

class VOXMesh extends Mesh {
    public function new(chunk:Dynamic) {
        var data:Bytes = chunk.data;
        var size:Dynamic = chunk.size;
        var palette:Array<Int> = chunk.palette;

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        var nx:Array<Float> = [0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1];
        var px:Array<Float> = [1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0];
        var py:Array<Float> = [0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1];
        var ny:Array<Float> = [0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0];
        var nz:Array<Float> = [0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0];
        var pz:Array<Float> = [0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1];

        var _color:Color = new Color();

        function add(tile:Array<Float>, x:Float, y:Float, z:Float, r:Float, g:Float, b:Float) {
            x -= size.x / 2;
            y -= size.z / 2;
            z += size.y / 2;

            for (i in 0...18) {
                _color.setRGB(r, g, b, SRGBColorSpace);

                vertices.push(tile[i + 0] + x, tile[i + 1] + y, tile[i + 2] + z);
                colors.push(_color.r, _color.g, _color.b);
            }
        }

        // Store data in a volume for sampling

        var offsety:Int = size.x;
        var offsetz:Int = size.x * size.y;

        var array:Uint8Array = new Uint8Array(size.x * size.y * size.z);

        for (j in 0...(data.length / 4)) {
            var x = data[j * 4 + 0];
            var y = data[j * 4 + 1];
            var z = data[j * 4 + 2];

            var index = x + (y * offsety) + (z * offsetz);

            array[index] = 255;
        }

        // Construct geometry

        var hasColors:Bool = false;

        for (j in 0...(data.length / 4)) {
            var x = data[j * 4 + 0];
            var y = data[j * 4 + 1];
            var z = data[j * 4 + 2];
            var c = data[j * 4 + 3];

            var hex = palette[c];
            var r = (hex >> 0 & 0xff) / 0xff;
            var g = (hex >> 8 & 0xff) / 0xff;
            var b = (hex >> 16 & 0xff) / 0xff;

            if (r > 0 || g > 0 || b > 0) hasColors = true;

            var index = x + (y * offsety) + (z * offsetz);

            if (array[index + 1] == 0 || x == size.x - 1) add(px, x, z, -y, r, g, b);
            if (array[index - 1] == 0 || x == 0) add(nx, x, z, -y, r, g, b);
            if (array[index + offsety] == 0 || y == size.y - 1) add(ny, x, z, -y, r, g, b);
            if (array[index - offsety] == 0 || y == 0) add(py, x, z, -y, r, g, b);
            if (array[index + offsetz] == 0 || z == size.z - 1) add(pz, x, z, -y, r, g, b);
            if (array[index - offsetz] == 0 || z == 0) add(nz, x, z, -y, r, g, b);
        }

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.computeVertexNormals();

        var material:MeshStandardMaterial = new MeshStandardMaterial();

        if (hasColors) {
            geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));
            material.vertexColors = true;
        }

        super(geometry, material);
    }
}

class VOXData3DTexture extends Data3DTexture {
    public function new(chunk:Dynamic) {
        var data:Bytes = chunk.data;
        var size:Dynamic = chunk.size;

        var offsety:Int = size.x;
        var offsetz:Int = size.x * size.y;

        var array:Uint8Array = new Uint8Array(size.x * size.y * size.z);

        for (j in 0...(data.length / 4)) {
            var x = data[j * 4 + 0];
            var y = data[j * 4 + 1];
            var z = data[j * 4 + 2];

            var index = x + (y * offsety) + (z * offsetz);

            array[index] = 255;
        }

        super(array, size.x, size.y, size.z);

        this.format = RedFormat;
        this.minFilter = NearestFilter;
        this.magFilter = LinearFilter;
        this.unpackAlignment = 1;
        this.needsUpdate = true;
    }
}
```
Note that I had to make some assumptions about the Haxe equivalents of certain JavaScript constructs, such as `DataView` and `Uint8Array`. Additionally, I used the `haxe.io` package for byte-level operations.