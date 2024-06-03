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
    public function new () {
        super();
    }

    public function load(url: String, onLoad: Null<(chunks: Array<Dynamic>) -> Void>, onProgress: Null<(event: ProgressEvent) -> Void>, onError: Null<(event: ErrorEvent) -> Void>) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.load(url, function (buffer: ArrayBuffer) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e: Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace("Error: " + e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(buffer: ArrayBuffer): Array<Dynamic> {
        var data = new haxe.io.Bytes(buffer);
        var id = data.readInt32();
        var version = data.readInt32();

        if (id !== 542658390) {
            trace("Invalid VOX file.");
            return [];
        }

        if (version !== 150) {
            trace("Invalid VOX file. Unsupported version: " + version);
            return [];
        }

        var DEFAULT_PALETTE = [
            // ... rest of the palette
        ];

        var i = 8;
        var chunk: Dynamic;
        var chunks: Array<Dynamic> = [];

        while (i < data.length) {
            var id = data.readString(i, 4);
            i += 4;
            var chunkSize = data.readInt32();
            i += 4; // childChunks

            if (id === 'SIZE') {
                var x = data.readInt32();
                i += 4;
                var y = data.readInt32();
                i += 4;
                var z = data.readInt32();
                i += 4;

                chunk = {
                    palette: DEFAULT_PALETTE,
                    size: { x: x, y: y, z: z },
                };

                chunks.push(chunk);
                i += chunkSize - (3 * 4);
            } else if (id === 'XYZI') {
                var numVoxels = data.readInt32();
                i += 4;
                chunk.data = data.sub(i, numVoxels * 4);
                i += numVoxels * 4;
            } else if (id === 'RGBA') {
                var palette = [0];
                for (var j = 0; j < 256; j++) {
                    palette[j + 1] = data.readInt32();
                    i += 4;
                }
                chunk.palette = palette;
            } else {
                i += chunkSize;
            }
        }

        return chunks;
    }
}

class VOXMesh extends Mesh {
    public function new(chunk: Dynamic) {
        var data = chunk.data;
        var size = chunk.size;
        var palette = chunk.palette;

        // ... rest of the VOXMesh class
    }
}

class VOXData3DTexture extends Data3DTexture {
    public function new(chunk: Dynamic) {
        var data = chunk.data;
        var size = chunk.size;

        // ... rest of the VOXData3DTexture class
    }
}

export { VOXLoader, VOXMesh, VOXData3DTexture };