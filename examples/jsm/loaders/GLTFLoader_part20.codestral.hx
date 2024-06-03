class GLTFBinaryExtension {
    var name:String;
    var content:String;
    var body:haxe.io.Bytes;
    var header:Dynamic;

    public function new(data:haxe.io.Bytes) {
        this.name = EXTENSIONS.KHR_BINARY_GLTF;
        this.content = null;
        this.body = null;

        var headerView = data.get(0, BINARY_EXTENSION_HEADER_LENGTH);
        var magic = haxe.io.Bytes.readString(headerView, 0, 4);
        var version = headerView.getUInt32(4, true);
        var length = headerView.getUInt32(8, true);

        this.header = {
            magic: magic,
            version: version,
            length: length
        };

        if (this.header.magic !== BINARY_EXTENSION_HEADER_MAGIC) {
            throw new js.Error('THREE.GLTFLoader: Unsupported glTF-Binary header.');
        } else if (this.header.version < 2.0) {
            throw new js.Error('THREE.GLTFLoader: Legacy binary file detected.');
        }

        var chunkContentsLength = this.header.length - BINARY_EXTENSION_HEADER_LENGTH;
        var chunkView = data.get(BINARY_EXTENSION_HEADER_LENGTH, chunkContentsLength);
        var chunkIndex = 0;

        while (chunkIndex < chunkContentsLength) {
            var chunkLength = chunkView.getUInt32(chunkIndex, true);
            chunkIndex += 4;

            var chunkType = chunkView.getUInt32(chunkIndex, true);
            chunkIndex += 4;

            if (chunkType === BINARY_EXTENSION_CHUNK_TYPES.JSON) {
                var contentArray = data.get(BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, chunkLength);
                this.content = haxe.io.Bytes.readString(contentArray, 0, chunkLength);
            } else if (chunkType === BINARY_EXTENSION_CHUNK_TYPES.BIN) {
                var byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
                this.body = data.get(byteOffset, chunkLength);
            }

            chunkIndex += chunkLength;
        }

        if (this.content === null) {
            throw new js.Error('THREE.GLTFLoader: JSON content not found.');
        }
    }
}