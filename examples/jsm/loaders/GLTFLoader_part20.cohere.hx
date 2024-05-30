class GLTFBinaryExtension {
	public var content:String;
	public var body:Bytes;
	public var header:GLTFBinaryExtensionHeader;

	public function new(data:Bytes) {
		header = {
			magic: haxe.io.Bytes.ofString(haxe.io.StringTools.byteArrayToString(data.slice(0, 4))),
			version: haxe.io.Bytes.getData(data, 4, haxe.io.Bytes.endian(true)),
			length: haxe.io.Bytes.getData(data, 8, haxe.io.Bytes.endian(true))
		};

		if (header.magic != BINARY_EXTENSION_HEADER_MAGIC) {
			throw "Unsupported glTF-Binary header.";
		} else if (header.version < 2.0) {
			throw "Legacy binary file detected.";
		}

		var chunkContentsLength = header.length - BINARY_EXTENSION_HEADER_LENGTH;
		var chunkView = haxe.io.Bytes.getDataView(data, BINARY_EXTENSION_HEADER_LENGTH);
		var chunkIndex = 0;

		while (chunkIndex < chunkContentsLength) {
			var chunkLength = chunkView.getUint32(chunkIndex, true);
			chunkIndex += 4;

			var chunkType = chunkView.getUint32(chunkIndex, true);
			chunkIndex += 4;

			if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.JSON) {
				var contentArray = data.slice(BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, BINARY_EXTENSION_HEADER_LENGTH + chunkIndex + chunkLength);
				content = haxe.io.StringTools.byteArrayToString(contentArray);
			} else if (chunkType == BINARY_EXTENSION_CHUNK_TYPES.BIN) {
				var byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
				body = data.slice(byteOffset, byteOffset + chunkLength);
			}

			// Clients must ignore chunks with unknown types.

			chunkIndex += chunkLength;
		}

		if (content == null) {
			throw "JSON content not found.";
		}
	}
}

type GLTFBinaryExtensionHeader = { magic:String, version:Int, length:Int };

class BINARY_EXTENSION {
	public static var EXTENSIONS:String = "KHR_binary_glTF";
	public static var HEADER_LENGTH:Int = 12;
	public static var CHUNK_HEADER_LENGTH:Int = 8;
	public static var HEADER_MAGIC:String = "glTF";
	public static var VERSION:Int = 2;
	public static var CHUNK_TYPES:String = "JSONBIN";
}

alias BINARY_EXTENSION_HEADER_MAGIC = BINARY_EXTENSION.HEADER_MAGIC;
alias BINARY_EXTENSION_HEADER_LENGTH = BINARY_EXTENSION.HEADER_LENGTH;

class BINARY_EXTENSION_CHUNK_TYPES {
	public static var JSON:Int = 0;
	public static var BIN:Int = 1;
}