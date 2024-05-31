import js.lib.DataView;
import js.lib.Uint8Array;
import js.lib.TextDecoder;

class GLTFBinaryExtension {

    public var name: String;
    public var content: String;
    public var body: js.lib.ArrayBuffer;
    public var header: { magic: String, version: Int, length: Int };

    public function new(data: js.lib.ArrayBuffer) {

        name = EXTENSIONS.KHR_BINARY_GLTF;
        content = null;
        body = null;

        final headerView = new DataView(data, 0, BINARY_EXTENSION_HEADER_LENGTH);
        final textDecoder = new TextDecoder();

        header = {
            magic: textDecoder.decode(new Uint8Array(data.slice(0, 4))),
            version: headerView.getUint32(4, true),
            length: headerView.getUint32(8, true)
        };

        if (header.magic != BINARY_EXTENSION_HEADER_MAGIC) {

            throw new Error("THREE.GLTFLoader: Unsupported glTF-Binary header.");

        } else if (header.version < 2) {

            throw new Error("THREE.GLTFLoader: Legacy binary file detected.");

        }

        final chunkContentsLength = header.length - BINARY_EXTENSION_HEADER_LENGTH;
        final chunkView = new DataView(data, BINARY_EXTENSION_HEADER_LENGTH);
        var chunkIndex = 0;

        while (chunkIndex < chunkContentsLength) {

            final chunkLength = chunkView.getUint32(chunkIndex, true);
            chunkIndex += 4;

            final chunkType = chunkView.getUint32(chunkIndex, true);
            chunkIndex += 4;

            if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.JSON) {

                final contentArray = new Uint8Array(data, BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, chunkLength);
                content = textDecoder.decode(contentArray);

            } else if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.BIN) {

                final byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
                body = data.slice(byteOffset, byteOffset + chunkLength);

            }

            // Clients must ignore chunks with unknown types.

            chunkIndex += chunkLength;

        }

        if (content == null) {

            throw new Error("THREE.GLTFLoader: JSON content not found.");

        }
    }
}