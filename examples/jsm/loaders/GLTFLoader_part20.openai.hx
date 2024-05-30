import haxe.io.Bytes;
import haxe.io.BytesDataView;

class GLTFBinaryExtension {
    public var name:String;
    public var content:String;
    public var body:Bytes;

    public function new(data:Bytes) {
        name = EXTENSIONS.KHR_BINARY_GLTF;
        content = null;
        body = null;

        var headerView = new BytesDataView(data, 0, BINARY_EXTENSION_HEADER_LENGTH);
        var textDecoder = new haxe Utf8();

        var header = {
            magic: textDecoder.decode(Bytes.ofString(data.toString(0, 4))),
            version: headerView.getUint32(4, true),
            length: headerView.getUint32(8, true)
        };

        if (header.magic != BINARY_EXTENSION_HEADER_MAGIC) {
            throw new Error('THREE.GLTFLoader: Unsupported glTF-Binary header.');
        } else if (header.version < 2.0) {
            throw new Error('THREE.GLTFLoader: Legacy binary file detected.');
        }

        var chunkContentsLength = header.length - BINARY_EXTENSION_HEADER_LENGTH;
        var chunkView = new BytesDataView(data, BINARY_EXTENSION_HEADER_LENGTH);
        var chunkIndex = 0;

        while (chunkIndex < chunkContentsLength) {
            var chunkLength = chunkView.getUint32(chunkIndex, true);
            chunkIndex += 4;

            var chunkType = chunkView.getUint32(chunkIndex, true);
            chunkIndex += 4;

            if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.JSON) {
                var contentArray = data.sub(BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, chunkLength);
                content = textDecoder.decode(contentArray);
            } else if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.BIN) {
                var byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
                body = data.sub(byteOffset, byteOffset + chunkLength);
            }

            // Clients must ignore chunks with unknown types.

            chunkIndex += chunkLength;
        }

        if (content == null) {
            throw new Error('THREE.GLTFLoader: JSON content not found.');
        }
    }
}