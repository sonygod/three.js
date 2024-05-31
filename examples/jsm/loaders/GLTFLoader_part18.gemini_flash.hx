import haxe.Json;
import js.lib.Promise;

class GLTFMeshoptCompression {

    public var name:String;
    public var parser:Dynamic;

    public function new(parser) {
        this.name = "EXT_MESHOPT_COMPRESSION";
        this.parser = parser;
    }

    public function loadBufferView(index:Int):Null<Promise<ArrayBuffer>> {
        var json = this.parser.json;
        var bufferView = json.bufferViews[index];

        if (bufferView.extensions != null && Reflect.hasField(bufferView.extensions, this.name)) {
            var extensionDef = Reflect.field(bufferView.extensions, this.name);

            var buffer:Promise<ArrayBuffer> = this.parser.getDependency('buffer', extensionDef.buffer);
            var decoder = this.parser.options.meshoptDecoder;

            if (decoder == null || !decoder.supported) {
                if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                    throw "THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files";
                } else {
                    // Assumes that the extension is optional and that fallback buffer data is present
                    return null;
                }
            }

            return buffer.then(function(res:ArrayBuffer) {
                var byteOffset:Int = extensionDef.byteOffset != null ? extensionDef.byteOffset : 0;
                var byteLength:Int = extensionDef.byteLength != null ? extensionDef.byteLength : 0;
                var count:Int = extensionDef.count;
                var stride:Int = extensionDef.byteStride;

                var source = new haxe.io.BytesData(byteLength, new haxe.io.Bytes.ofData(res, byteOffset, byteLength));

                if (Reflect.hasField(decoder, 'decodeGltfBufferAsync')) {
                    return (cast(decoder.decodeGltfBufferAsync, Dynamic))(count, stride, source, extensionDef.mode, extensionDef.filter)
                    .then(function(res) {
                        return res.buffer;
                    });
                } else {
                    // Support for MeshoptDecoder 0.18 or earlier, without decodeGltfBufferAsync
                    return decoder.ready.then(function(_) {
                        var result = new ArrayBuffer(count * stride);
                        var resultBytes = new haxe.io.BytesData(result.byteLength, new haxe.io.Bytes.ofData(result));
                        decoder.decodeGltfBuffer(resultBytes, count, stride, source, extensionDef.mode, extensionDef.filter);
                        return result;
                    });
                }
            });
        } else {
            return null;
        }
    }
}