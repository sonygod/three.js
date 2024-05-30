package three.js.loaders;

import three.data.BufferGeometry;
import three.data.Data3DTexture;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.MeshStandardMaterial;
import three.math.Color;

class VOXLoader extends Loader {
    override public function load(url:String, onLoad:(Any->Void), onProgress:(Float->Void), onError:(String->Void)) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(this.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    console.error(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer:ArrayBuffer):Array<Dynamic> {
        var data:Bytes = Bytes.ofData(buffer);
        var id:Int = data.getUInt32(0, true);
        var version:Int = data.getUInt32(4, true);

        if (id != 542658390) {
            console.error('THREE.VOXLoader: Invalid VOX file.');
            return;
        }

        if (version != 150) {
            console.error('THREE.VOXLoader: Invalid VOX file. Unsupported version: ' + version);
            return;
        }

        var DEFAULT_PALETTE:Array<Int> = [
            0x00000000, 0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff, 0xffffccff,
            // ...
        ];

        var chunks:Array<Dynamic> = [];

        var i:Int = 8;

        while (i < data.length) {
            var id:String = '';
            for (j in 0...4) {
                id += String.fromCharCode(data.getUInt8(i++));
            }

            var chunkSize:Int = data.getUInt32(i, true);
            i += 4; // childChunks

            if (id == 'SIZE') {
                var x:Int = data.getUInt32(i, true);
                i += 4;
                var y:Int = data.getUInt32(i, true);
                i += 4;
                var z:Int = data.getUInt32(i, true);
                i += 4;

                var chunk:Dynamic = {
                    palette: DEFAULT_PALETTE,
                    size: { x: x, y: y, z: z }
                };

                chunks.push(chunk);

                i += chunkSize - (3 * 4);
            } else if (id == 'XYZI') {
                var numVoxels:Int = data.getUInt32(i, true);
                i += 4;
                chunk.data = new Uint8Array(buffer, i, numVoxels * 4);

                i += numVoxels * 4;
            } else if (id == 'RGBA') {
                var palette:Array<Int> = [0];

                for (j in 0...256) {
                    palette[j + 1] = data.getUInt32(i, true);
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

        // ...

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        // ...

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.computeVertexNormals();

        var material:MeshStandardMaterial = new MeshStandardMaterial();

        // ...

        super(geometry, material);
    }
}

class VOXData3DTexture extends Data3DTexture {
    public function new(chunk:Dynamic) {
        var data:Bytes = chunk.data;
        var size:Dynamic = chunk.size;

        var offsety:Int = size.x;
        var offsetz:Int = size.x * size.y;

        var array:Bytes = Bytes.alloc(size.x * size.y * size.z);

        for (j in 0...data.length) {
            var x:Int = data[j + 0];
            var y:Int = data[j + 1];
            var z:Int = data[j + 2];

            var index:Int = x + (y * offsety) + (z * offsetz);

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