class GLTFBinaryExtension {

    public var name:String;
    public var content:String;
    public var body:haxe.io.Bytes;

    public function new(data:haxe.io.Bytes) {

        this.name = EXTENSIONS.KHR_BINARY_GLTF;
        this.content = null;
        this.body = null;

        var headerView = new haxe.io.BytesInput(data);
        var textDecoder = haxe.io.Bytes.ofString("");

        this.header = {
            magic: textDecoder.getString(headerView.readBytes(4), 0, 4),
            version: headerView.readInt32(true),
            length: headerView.readInt32(true)
        };

        if (this.header.magic != BINARY_EXTENSION_HEADER_MAGIC) {

            throw new Error("THREE.GLTFLoader: Unsupported glTF-Binary header.");

        } else if (this.header.version < 2.0) {

            throw new Error("THREE.GLTFLoader: Legacy binary file detected.");

        }

        var chunkContentsLength = this.header.length - BINARY_EXTENSION_HEADER_LENGTH;
        var chunkView = new haxe.io.BytesInput(data);
        var chunkIndex = 0;

        while (chunkIndex < chunkContentsLength) {

            var chunkLength = chunkView.readInt32(true);
            chunkIndex += 4;

            var chunkType = chunkView.readInt32(true);
            chunkIndex += 4;

            if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.JSON) {

                var contentArray = new haxe.io.BytesInput(data);
                contentArray.position = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
                this.content = textDecoder.getString(contentArray.readBytes(chunkLength), 0, chunkLength);

            } else if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.BIN) {

                var byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
                this.body = data.sub(byteOffset, byteOffset + chunkLength);

            }

            // Clients must ignore chunks with unknown types.

            chunkIndex += chunkLength;

        }

        if (this.content == null) {

            throw new Error("THREE.GLTFLoader: JSON content not found.");

        }

    }

}