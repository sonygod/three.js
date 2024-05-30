class GLTFBinaryExtension {

	var name:String;
	var content:String;
	var body:haxe.io.Bytes;
	var header:GLTFBinaryExtensionHeader;

	public function new(data:haxe.io.Bytes) {

		name = EXTENSIONS.KHR_BINARY_GLTF;
		content = null;
		body = null;

		var headerView = new haxe.io.BytesData(data, 0, BINARY_EXTENSION_HEADER_LENGTH);
		var textDecoder = new haxe.io.BytesToString();

		header = {
			magic: textDecoder.decode(data.sub(0, 4)),
			version: haxe.io.Bytes.readUInt32BE(headerView, 4),
			length: haxe.io.Bytes.readUInt32BE(headerView, 8)
		};

		if (header.magic !== BINARY_EXTENSION_HEADER_MAGIC) {

			throw "THREE.GLTFLoader: Unsupported glTF-Binary header.";

		} else if (header.version < 2.0) {

			throw "THREE.GLTFLoader: Legacy binary file detected.";

		}

		var chunkContentsLength = header.length - BINARY_EXTENSION_HEADER_LENGTH;
		var chunkView = new haxe.io.BytesData(data, BINARY_EXTENSION_HEADER_LENGTH);
		var chunkIndex = 0;

		while (chunkIndex < chunkContentsLength) {

			var chunkLength = haxe.io.Bytes.readUInt32BE(chunkView, chunkIndex);
			chunkIndex += 4;

			var chunkType = haxe.io.Bytes.readUInt32BE(chunkView, chunkIndex);
			chunkIndex += 4;

			if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.JSON) {

				var contentArray = new haxe.io.Bytes(chunkLength);
				haxe.io.Bytes.blit(data, BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, contentArray, 0, chunkLength);
				content = textDecoder.decode(contentArray);

			} else if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.BIN) {

				var byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
				body = new haxe.io.Bytes(chunkLength);
				haxe.io.Bytes.blit(data, byteOffset, body, 0, chunkLength);

			}

			// Clients must ignore chunks with unknown types.

			chunkIndex += chunkLength;

		}

		if (content == null) {

			throw "THREE.GLTFLoader: JSON content not found.";

		}

	}

}

typedef GLTFBinaryExtensionHeader = {
	var magic:String;
	var version:Int;
	var length:Int;
}