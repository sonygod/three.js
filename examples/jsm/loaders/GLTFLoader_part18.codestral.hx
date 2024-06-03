import haxe.remoting.Async;
import haxe.io.Bytes;

class GLTFMeshoptCompression {
    var name:String;
    var parser:Parser;

    public function new(parser:Parser) {
        this.name = EXTENSIONS.EXT_MESHOPT_COMPRESSION;
        this.parser = parser;
    }

    public function loadBufferView(index:Int):Async<Bytes> {
        var json = this.parser.json;
        var bufferView = json.bufferViews[index];

        if (bufferView.extensions != null && bufferView.extensions.exists(this.name)) {
            var extensionDef = bufferView.extensions.get(this.name);

            var buffer = this.parser.getDependency('buffer', extensionDef.buffer);
            var decoder = this.parser.options.meshoptDecoder;

            if (decoder == null || !decoder.supported) {
                if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                    throw new Error('setMeshoptDecoder must be called before loading compressed files');
                } else {
                    // Assumes that the extension is optional and that fallback buffer data is present
                    return null;
                }
            }

            return buffer.then(function(res:Bytes) {
                var byteOffset = Std.parseInt(extensionDef.byteOffset) ?? 0;
                var byteLength = Std.parseInt(extensionDef.byteLength) ?? 0;

                var count = Std.parseInt(extensionDef.count);
                var stride = Std.parseInt(extensionDef.byteStride);

                var source = res.sub(byteOffset, byteLength);

                if (decoder.decodeGltfBufferAsync != null) {
                    return decoder.decodeGltfBufferAsync(count, stride, source, extensionDef.mode, extensionDef.filter).then(function(res:Bytes) {
                        return res;
                    });
                } else {
                    // Support for MeshoptDecoder 0.18 or earlier, without decodeGltfBufferAsync
                    return decoder.ready.then(function() {
                        var result = Bytes.alloc(count * stride);
                        decoder.decodeGltfBuffer(result, count, stride, source, extensionDef.mode, extensionDef.filter);
                        return result;
                    });
                }
            });
        } else {
            return null;
        }
    }
}