import three.loaders.DataTextureLoader;
import three.textures.Texture;
import three.textures.TextureFilter;
import three.math.Color;

class TGALoader extends DataTextureLoader {

	public function new(manager:Dynamic = null) {
		super(manager);
	}

	override public function parse(buffer:haxe.io.Bytes):Dynamic {
		// reference from vthibault, https://github.com/vthibault/roBrowser/blob/master/src/Loaders/Targa.js

		function tgaCheckHeader(header:Dynamic):Void {
			switch(header.image_type) {
				// check indexed type
				case TGA_TYPE_INDEXED:
				case TGA_TYPE_RLE_INDEXED:
					if (header.colormap_length > 256 || header.colormap_size != 24 || header.colormap_type != 1) {
						throw new Error("THREE.TGALoader: Invalid type colormap data for indexed type.");
					}
					break;
				// check colormap type
				case TGA_TYPE_RGB:
				case TGA_TYPE_GREY:
				case TGA_TYPE_RLE_RGB:
				case TGA_TYPE_RLE_GREY:
					if (header.colormap_type) {
						throw new Error("THREE.TGALoader: Invalid type colormap data for colormap type.");
					}
					break;
				// What the need of a file without data ?
				case TGA_TYPE_NO_DATA:
					throw new Error("THREE.TGALoader: No data.");
				// Invalid type ?
				default:
					throw new Error("THREE.TGALoader: Invalid type " + header.image_type);
			}
			// check image width and height
			if (header.width <= 0 || header.height <= 0) {
				throw new Error("THREE.TGALoader: Invalid image size.");
			}
			// check image pixel size
			if (header.pixel_size != 8 && header.pixel_size != 16 && header.pixel_size != 24 && header.pixel_size != 32) {
				throw new Error("THREE.TGALoader: Invalid pixel size " + header.pixel_size);
			}
		}

		// parse tga image buffer
		function tgaParse(use_rle:Bool, use_pal:Bool, header:Dynamic, offset:Int, data:haxe.io.Bytes):Dynamic {
			var pixel_data:haxe.io.Bytes, palettes:haxe.io.Bytes;
			var pixel_size = header.pixel_size >> 3;
			var pixel_total = header.width * header.height * pixel_size;
			// read palettes
			if (use_pal) {
				palettes = data.sub(offset, offset + header.colormap_length * (header.colormap_size >> 3));
				offset += header.colormap_length * (header.colormap_size >> 3);
			}
			// read RLE
			if (use_rle) {
				pixel_data = new haxe.io.Bytes(pixel_total);
				var c:Int, count:Int, i:Int;
				var shift:Int = 0;
				var pixels = new haxe.io.Bytes(pixel_size);
				while (shift < pixel_total) {
					c = data.get(offset++);
					count = (c & 0x7f) + 1;
					// RLE pixels
					if (c & 0x80) {
						// bind pixel tmp array
						for (i in 0...pixel_size) {
							pixels.set(i, data.get(offset++));
						}
						// copy pixel array
						for (i in 0...count) {
							pixel_data.blit(shift + i * pixel_size, pixels, 0, pixel_size);
						}
						shift += pixel_size * count;
					} else {
						// raw pixels
						count *= pixel_size;
						for (i in 0...count) {
							pixel_data.set(shift + i, data.get(offset++));
						}
						shift += count;
					}
				}
			} else {
				// raw pixels
				pixel_data = data.sub(offset, offset + (use_pal ? header.width * header.height : pixel_total));
				offset += (use_pal ? header.width * header.height : pixel_total);
			}
			return {
				pixel_data: pixel_data,
				palettes: palettes
			};
		}

		function tgaGetImageData8bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes, palettes:haxe.io.Bytes):haxe.io.Bytes {
			var colormap = palettes;
			var color:Int, i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					color = image.get(i++);
					imageData.set((x + width * y) * 4 + 3, 255);
					imageData.set((x + width * y) * 4 + 2, colormap.get((color * 3) + 0));
					imageData.set((x + width * y) * 4 + 1, colormap.get((color * 3) + 1));
					imageData.set((x + width * y) * 4 + 0, colormap.get((color * 3) + 2));
				}
			}
			return imageData;
		}

		function tgaGetImageData16bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes):haxe.io.Bytes {
			var color:Int, i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					color = image.get(i + 0) + (image.get(i + 1) << 8);
					i += 2;
					imageData.set((x + width * y) * 4 + 0, (color & 0x7C00) >> 7);
					imageData.set((x + width * y) * 4 + 1, (color & 0x03E0) >> 2);
					imageData.set((x + width * y) * 4 + 2, (color & 0x001F) << 3);
					imageData.set((x + width * y) * 4 + 3, (color & 0x8000) ? 0 : 255);
				}
			}
			return imageData;
		}

		function tgaGetImageData24bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes):haxe.io.Bytes {
			var i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					imageData.set((x + width * y) * 4 + 3, 255);
					imageData.set((x + width * y) * 4 + 2, image.get(i + 0));
					imageData.set((x + width * y) * 4 + 1, image.get(i + 1));
					imageData.set((x + width * y) * 4 + 0, image.get(i + 2));
					i += 3;
				}
			}
			return imageData;
		}

		function tgaGetImageData32bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes):haxe.io.Bytes {
			var i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					imageData.set((x + width * y) * 4 + 2, image.get(i + 0));
					imageData.set((x + width * y) * 4 + 1, image.get(i + 1));
					imageData.set((x + width * y) * 4 + 0, image.get(i + 2));
					imageData.set((x + width * y) * 4 + 3, image.get(i + 3));
					i += 4;
				}
			}
			return imageData;
		}

		function tgaGetImageDataGrey8bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes):haxe.io.Bytes {
			var color:Int, i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					color = image.get(i++);
					imageData.set((x + width * y) * 4 + 0, color);
					imageData.set((x + width * y) * 4 + 1, color);
					imageData.set((x + width * y) * 4 + 2, color);
					imageData.set((x + width * y) * 4 + 3, 255);
				}
			}
			return imageData;
		}

		function tgaGetImageDataGrey16bits(imageData:haxe.io.Bytes, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:haxe.io.Bytes):haxe.io.Bytes {
			var i:Int = 0, x:Int, y:Int;
			var width = header.width;
			for (y in y_start...y_end...y_step) {
				for (x in x_start...x_end...x_step) {
					imageData.set((x + width * y) * 4 + 0, image.get(i + 0));
					imageData.set((x + width * y) * 4 + 1, image.get(i + 0));
					imageData.set((x + width * y) * 4 + 2, image.get(i + 0));
					imageData.set((x + width * y) * 4 + 3, image.get(i + 1));
					i += 2;
				}
			}
			return imageData;
		}

		function getTgaRGBA(data:haxe.io.Bytes, width:Int, height:Int, image:haxe.io.Bytes, palette:haxe.io.Bytes):haxe.io.Bytes {
			var x_start:Int, y_start:Int, x_step:Int, y_step:Int, x_end:Int, y_end:Int;
			switch((header.flags & TGA_ORIGIN_MASK) >> TGA_ORIGIN_SHIFT) {
				default:
				case TGA_ORIGIN_UL:
					x_start = 0;
					x_step = 1;
					x_end = width;
					y_start = 0;
					y_step = 1;
					y_end = height;
					break;
				case TGA_ORIGIN_BL:
					x_start = 0;
					x_step = 1;
					x_end = width;
					y_start = height - 1;
					y_step = - 1;
					y_end = - 1;
					break;
				case TGA_ORIGIN_UR:
					x_start = width - 1;
					x_step = - 1;
					x_end = - 1;
					y_start = 0;
					y_step = 1;
					y_end = height;
					break;
				case TGA_ORIGIN_BR:
					x_start = width - 1;
					x_step = - 1;
					x_end = - 1;
					y_start = height - 1;
					y_step = - 1;
					y_end = - 1;
					break;
			}
			if (use_grey) {
				switch (header.pixel_size) {
					case 8:
						tgaGetImageDataGrey8bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
						break;
					case 16:
						tgaGetImageDataGrey16bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
						break;
					default:
						throw new Error("THREE.TGALoader: Format not supported.");
						break;
				}
			} else {
				switch (header.pixel_size) {
					case 8:
						tgaGetImageData8bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image, palette);
						break;
					case 16:
						tgaGetImageData16bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
						break;
					case 24:
						tgaGetImageData24bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
						break;
					case 32:
						tgaGetImageData32bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
						break;
					default:
						throw new Error("THREE.TGALoader: Format not supported.");
						break;
				}
			}
			// Load image data according to specific method
			// let func = 'tgaGetImageData' + (use_grey ? 'Grey' : '') + (header.pixel_size) + 'bits';
			// func(data, y_start, y_step, y_end, x_start, x_step, x_end, width, image, palette );
			return data;
		}

		// TGA constants
		var TGA_TYPE_NO_DATA:Int = 0;
		var TGA_TYPE_INDEXED:Int = 1;
		var TGA_TYPE_RGB:Int = 2;
		var TGA_TYPE_GREY:Int = 3;
		var TGA_TYPE_RLE_INDEXED:Int = 9;
		var TGA_TYPE_RLE_RGB:Int = 10;
		var TGA_TYPE_RLE_GREY:Int = 11;
		var TGA_ORIGIN_MASK:Int = 0x30;
		var TGA_ORIGIN_SHIFT:Int = 0x04;
		var TGA_ORIGIN_BL:Int = 0x00;
		var TGA_ORIGIN_BR:Int = 0x01;
		var TGA_ORIGIN_UL:Int = 0x02;
		var TGA_ORIGIN_UR:Int = 0x03;

		if (buffer.length < 19) throw new Error("THREE.TGALoader: Not enough data to contain header.");
		var offset:Int = 0;
		var content = new haxe.io.Bytes(buffer);
		var header = {
			id_length: content.get(offset++),
			colormap_type: content.get(offset++),
			image_type: content.get(offset++),
			colormap_index: content.get(offset++) | content.get(offset++) << 8,
			colormap_length: content.get(offset++) | content.get(offset++) << 8,
			colormap_size: content.get(offset++),
			origin: [
				content.get(offset++) | content.get(offset++) << 8,
				content.get(offset++) | content.get(offset++) << 8
			],
			width: content.get(offset++) | content.get(offset++) << 8,
			height: content.get(offset++) | content.get(offset++) << 8,
			pixel_size: content.get(offset++),
			flags: content.get(offset++)
		};
		// check tga if it is valid format
		tgaCheckHeader(header);
		if (header.id_length + offset > buffer.length) {
			throw new Error("THREE.TGALoader: No data.");
		}
		// skip the needn't data
		offset += header.id_length;
		// get targa information about RLE compression and palette
		var use_rle:Bool = false;
		var use_pal:Bool = false;
		var use_grey:Bool = false;
		switch (header.image_type) {
			case TGA_TYPE_RLE_INDEXED:
				use_rle = true;
				use_pal = true;
				break;
			case TGA_TYPE_INDEXED:
				use_pal = true;
				break;
			case TGA_TYPE_RLE_RGB:
				use_rle = true;
				break;
			case TGA_TYPE_RGB:
				break;
			case TGA_TYPE_RLE_GREY:
				use_rle = true;
				use_grey = true;
				break;
			case TGA_TYPE_GREY:
				use_grey = true;
				break;
		}
		//
		var imageData = new haxe.io.Bytes(header.width * header.height * 4);
		var result = tgaParse(use_rle, use_pal, header, offset, content);
		getTgaRGBA(imageData, header.width, header.height, result.pixel_data, result.palettes);
		return {
			data: imageData,
			width: header.width,
			height: header.height,
			flipY: true,
			generateMipmaps: true,
			minFilter: TextureFilter.LinearMipmapLinear,
		};
	}

}