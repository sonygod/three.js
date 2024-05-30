class GLTFMeshoptCompression {

    public var name:String;
    public var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.name = EXTENSIONS.EXT_MESHOPT_COMPRESSION;
        this.parser = parser;
    }

    public function loadBufferView(index:Int):Dynamic {
        var json = this.parser.json;
        var bufferView = json.bufferViews[index];

        if (bufferView.extensions && bufferView.extensions[this.name]) {
            var extensionDef = bufferView.extensions[this.name];
            var buffer = this.parser.getDependency('buffer', extensionDef.buffer);
            var decoder = this.parser.options.meshoptDecoder;

            if (!decoder || !decoder.supported) {
                if (json.extensionsRequired && json.extensionsRequired.indexOf(this.name) >= 0) {
                    throw 'THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files';
                } else {
                    // Assumes that the extension is optional and that fallback buffer data is present
                    return null;
                }
            }

            return buffer.then(function(res) {
                var byteOffset = extensionDef.byteOffset || 0;
                var byteLength = extensionDef.byteLength || 0;
                var count = extensionDef.count;
                var stride = extensionDef.byteStride;
                var source = new Uint8Array(res, byteOffset, byteLength);

                if (decoder.decodeGltfBufferAsync) {
                    return decoder.decodeGltfBufferAsync(count, stride, source, extensionDef.mode, extensionDef.filter).then(function(res) {
                        return res.buffer;
                    });
                } else {
                    // Support for MeshoptDecoder 0.18 or earlier, without decodeGltfBufferAsync
                    return decoder.ready.then(function() {
                        var result = new ArrayBuffer(count * stride);
                        decoder.decodeGltfBuffer(new Uint8Array(result), count, stride, source, extensionDef.mode, extensionDef.filter);
                        return result;
                    });
                }
            });
        } else {
            return null;
        }
    }
}