import three.CompressedTextureLoader;

class KTXLoader extends CompressedTextureLoader {

	public function new(manager) {
		super(manager);
	}

	public function parse(buffer:haxe.io.Bytes, loadMipmaps:Bool):Dynamic {
		var ktx = new KhronosTextureContainer(buffer, 1);
		return {
			mipmaps: ktx.mipmaps(loadMipmaps),
			width: ktx.pixelWidth,
			height: ktx.pixelHeight,
			format: ktx.glInternalFormat,
			isCubemap: ktx.numberOfFaces === 6,
			mipmapCount: ktx.numberOfMipmapLevels
		};
	}
}

class KhronosTextureContainer {

	var arrayBuffer:haxe.io.Bytes;
	var glType:Int;
	var glTypeSize:Int;
	var glFormat:Int;
	var glInternalFormat:Int;
	var glBaseInternalFormat:Int;
	var pixelWidth:Int;
	var pixelHeight:Int;
	var pixelDepth:Int;
	var numberOfArrayElements:Int;
	var numberOfFaces:Int;
	var numberOfMipmapLevels:Int;
	var bytesOfKeyValueData:Int;
	var loadType:Int;

	public function new(arrayBuffer:haxe.io.Bytes, facesExpected:Int) {
		this.arrayBuffer = arrayBuffer;
		var identifier = arrayBuffer.getBytes(0, 12);
		if (identifier[0] != 0xAB ||
			identifier[1] != 0x4B ||
			identifier[2] != 0x54 ||
			identifier[3] != 0x58 ||
			identifier[4] != 0x20 ||
			identifier[5] != 0x31 ||
			identifier[6] != 0x31 ||
			identifier[7] != 0xBB ||
			identifier[8] != 0x0D ||
			identifier[9] != 0x0A ||
			identifier[10] != 0x1A ||
			identifier[11] != 0x0A) {
			trace('texture missing KTX identifier');
			return;
		}
		var headerDataView = arrayBuffer.getBytes(12, 13 * 4);
		var endianness = headerDataView.getInt32(0);
		var littleEndian = endianness == 0x04030201;
		this.glType = headerDataView.getInt32(1 * 4, littleEndian);
		this.glTypeSize = headerDataView.getInt32(2 * 4, littleEndian);
		this.glFormat = headerDataView.getInt32(3 * 4, littleEndian);
		this.glInternalFormat = headerDataView.getInt32(4 * 4, littleEndian);
		this.glBaseInternalFormat = headerDataView.getInt32(5 * 4, littleEndian);
		this.pixelWidth = headerDataView.getInt32(6 * 4, littleEndian);
		this.pixelHeight = headerDataView.getInt32(7 * 4, littleEndian);
		this.pixelDepth = headerDataView.getInt32(8 * 4, littleEndian);
		this.numberOfArrayElements = headerDataView.getInt32(9 * 4, littleEndian);
		this.numberOfFaces = headerDataView.getInt32(10 * 4, littleEndian);
		this.numberOfMipmapLevels = headerDataView.getInt32(11 * 4, littleEndian);
		this.bytesOfKeyValueData = headerDataView.getInt32(12 * 4, littleEndian);
		if (this.glType != 0) {
			trace('only compressed formats currently supported');
			return;
		} else {
			this.numberOfMipmapLevels = Math.max(1, this.numberOfMipmapLevels);
		}
		if (this.pixelHeight == 0 || this.pixelDepth != 0) {
			trace('only 2D textures currently supported');
			return;
		}
		if (this.numberOfArrayElements != 0) {
			trace('texture arrays not currently supported');
			return;
		}
		if (this.numberOfFaces != facesExpected) {
			trace('number of faces expected ' + facesExpected + ', but found ' + this.numberOfFaces);
			return;
		}
		this.loadType = 0;
	}

	public function mipmaps(loadMipmaps:Bool):Array<Dynamic> {
		var mipmaps = [];
		var dataOffset = 12 + this.bytesOfKeyValueData;
		var width = this.pixelWidth;
		var height = this.pixelHeight;
		var mipmapCount = loadMipmaps ? this.numberOfMipmapLevels : 1;
		for (level in 0...mipmapCount) {
			var imageSize = this.arrayBuffer.getInt32(dataOffset);
			dataOffset += 4;
			for (face in 0...this.numberOfFaces) {
				var byteArray = this.arrayBuffer.getBytes(dataOffset, imageSize);
				mipmaps.push({'data': byteArray, 'width': width, 'height': height});
				dataOffset += imageSize;
				dataOffset += 3 - ((imageSize + 3) % 4);
			}
			width = Math.max(1.0, width * 0.5);
			height = Math.max(1.0, height * 0.5);
		}
		return mipmaps;
	}
}