import three.data.DataTextureLoader;
import three.textures.LinearMipmapLinearFilter;

class TGALoader extends DataTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function parse(buffer:ArrayBufferView):Dynamic {

		// reference from vthibault, https://github.com/vthibault/roBrowser/blob/master/src/Loaders/Targa.js

		function tgaCheckHeader(header:Dynamic) {
			// check indexed type
			switch (header.image_type) {
				// check indexed type
				case 1:
				case 9:
					if (header.colormap_length > 256 || header.colormap_size !== 24 || header.colormap_type !== 1) {
						throw new Error('THREE.TGALoader: Invalid type colormap data for indexed type.');
					}
					break;

				// check colormap type
				case 2:
				case 3:
				case 10:
				case 11:
					if (header.colormap_type) {
						throw new Error('THREE.TGALoader: Invalid type colormap data for colormap type.');
					}
					break;

				// What the need of a file without data ?
				case 0:
					throw new Error('THREE.TGALoader: No data.');

				// Invalid type ?
				default:
					throw new Error('THREE.TGALoader: Invalid type ' + header.image_type);
			}

			// check image width and height
			if (header.width <= 0 || header.height <= 0) {
				throw new Error('THREE.TGALoader: Invalid image size.');
			}

			// check image pixel size
			if (header.pixel_size !== 8 && header.pixel_size !== 16 && header.pixel_size !== 24 && header.pixel_size !== 32) {
				throw new Error('THREE.TGALoader: Invalid pixel size ' + header.pixel_size);
			}
		}

		// parse tga image buffer
		function tgaParse(use_rle:Bool, use_pal:Bool, header:Dynamic, offset:Int, data:ArrayBufferView):Dynamic {
			// implementation here
		}

		// implementation of other functions here

		// TGA constants
		const TGA_TYPE_NO_DATA:Int = 0;
		const TGA_TYPE_INDEXED:Int = 1;
		const TGA_TYPE_RGB:Int = 2;
		const TGA_TYPE_GREY:Int = 3;
		const TGA_TYPE_RLE_INDEXED:Int = 9;
		const TGA_TYPE_RLE_RGB:Int = 10;
		const TGA_TYPE_RLE_GREY:Int = 11;
		const TGA_ORIGIN_MASK:Int = 0x30;
		const TGA_ORIGIN_SHIFT:Int = 0x04;
		const TGA_ORIGIN_BL:Int = 0x00;
		const TGA_ORIGIN_BR:Int = 0x01;
		const TGA_ORIGIN_UL:Int = 0x02;
		const TGA_ORIGIN_UR:Int = 0x03;

		if (buffer.byteLength < 19) throw new Error('THREE.TGALoader: Not enough data to contain header.');

		let offset:Int = 0;

		const content:ArrayBufferView = new Uint8Array(buffer);
		const header:Dynamic = {
			id_length: content[offset++],
			colormap_type: content[offset++],
			image_type: content[offset++],
			colormap_index: content[offset++] | content[offset++] << 8,
			colormap_length: content[offset++] | content[offset++] << 8,
			colormap_size: content[offset++],
			origin: [
				content[offset++],
				content[offset++],
				content[offset++],
				content[offset++]
			],
			width: content[offset++] | content[offset++] << 8,
			height: content[offset++] | content[offset++] << 8,
			pixel_size: content[offset++],
			flags: content[offset++]
		};

		// check tga if it is valid format
		tgaCheckHeader(header);

		if (header.id_length + offset > buffer.byteLength) {
			throw new Error('THREE.TGALoader: No data.');
		}

		// skip the needn't data
		offset += header.id_length;

		// get targa information about RLE compression and palette
		let use_rle:Bool = false;
		let use_pal:Bool = false;
		let use_grey:Bool = false;

		switch (header.image_type) {
			case 9:
				use_rle = true;
				use_pal = true;
				break;

			case 1:
				use_pal = true;
				break;

			case 10:
				use_rle = true;
				break;

			case 2:
				break;

			case 11:
				use_rle = true;
				use_grey = true;
				break;

			case 3:
				use_grey = true;
				break;
		}

		// implementation here

		return {
			data: imageData,
			width: header.width,
			height: header.height,
			flipY: true,
			generateMipmaps: true,
			minFilter: LinearMipmapLinearFilter,
		};
	}
}