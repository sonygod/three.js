class GLTFMeshoptCompression {
    public var name:String;
    public var parser:Dynamic;

    public function new(parser:Dynamic) {
        name = EXTENSIONS.EXT_MESHOPT_COMPRESSION;
        this.parser = parser;
    }

    public function loadBufferView(index:Int):Null<Dynamic> {
        var json = parser.json;
        var bufferView = json.bufferViews[index];

        if (bufferView.extensions != null && bufferView.extensions.exists(name)) {
            var extensionDef = bufferView.extensions[name];
            var buffer = parser.getDependency("buffer", extensionDef.buffer);
            var decoder = parser.options.meshoptDecoder;

            if (decoder == null || !decoder.supported) {
                if (json.extensionsRequired != null && json.extensionsRequired.indexOf(name) >= 0) {
                    throw $hxExceptions.EInvalidOperation("THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files");
                } else {
                    // Assumes that the extension is optional and that fallback buffer data is present
                    return null;
                }
            }

            var byteOffset = extensionDef.byteOffset.default(0);
            var byteLength = extensionDef.byteLength.default(0);
            var count = extensionDef.count;
            var stride = extensionDef.byteStride;
            var source = buffer.slice(byteOffset, byteOffset + byteLength);

            if (decoder.decodeGltfBufferAsync != null) {
                return decoder.decodeGltfBufferAsync(count, stride, source, extensionDef.mode, extensionDef.filter).then( ($value:Dynamic) -> {
                    return $value.buffer;
                });
            } else {
                // Support for MeshoptDecoder 0.18 or earlier, without decodeGltfBufferAsync
                return decoder.ready.then( ($value:Dynamic) -> {
                    var result = new haxe.io.Bytes(count * stride);
                    decoder.decodeGltfBuffer(result, count, stride, source, extensionDef.mode, extensionDef.filter);
                    return result;
                });
            }
        } else {
            return null;
        }
    }
}