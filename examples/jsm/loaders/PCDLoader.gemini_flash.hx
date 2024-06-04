import three.core.BufferGeometry;
import three.math.Color;
import three.loaders.FileLoader;
import three.core.Float32BufferAttribute;
import three.core.Int32BufferAttribute;
import three.loaders.Loader;
import three.objects.Points;
import three.materials.PointsMaterial;

class PCDLoader extends Loader {

	public var littleEndian:Bool = true;

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(data) {
			try {
				onLoad(scope.parse(data));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:haxe.io.Bytes):Points {
		// from https://gitlab.com/taketwo/three-pcd-loader/blob/master/decompress-lzf.js
		function decompressLZF(inData:haxe.io.Bytes, outLength:Int):haxe.io.Bytes {
			var inLength = inData.length;
			var outData = new haxe.io.Bytes(outLength);
			var inPtr = 0;
			var outPtr = 0;
			var ctrl:Int;
			var len:Int;
			var ref:Int;
			while (inPtr < inLength) {
				ctrl = inData.get(inPtr++);
				if (ctrl < (1 << 5)) {
					ctrl++;
					if (outPtr + ctrl > outLength) throw new Error('Output buffer is not large enough');
					if (inPtr + ctrl > inLength) throw new Error('Invalid compressed data');
					while (ctrl > 0) {
						outData.set(outPtr++, inData.get(inPtr++));
						ctrl--;
					}
				} else {
					len = ctrl >> 5;
					ref = outPtr - ((ctrl & 0x1f) << 8) - 1;
					if (inPtr >= inLength) throw new Error('Invalid compressed data');
					if (len == 7) {
						len += inData.get(inPtr++);
						if (inPtr >= inLength) throw new Error('Invalid compressed data');
					}
					ref -= inData.get(inPtr++);
					if (outPtr + len + 2 > outLength) throw new Error('Output buffer is not large enough');
					if (ref < 0) throw new Error('Invalid compressed data');
					if (ref >= outPtr) throw new Error('Invalid compressed data');
					while (len + 2 > 0) {
						outData.set(outPtr++, outData.get(ref++));
						len--;
					}
				}
			}
			return outData;
		}

		function parseHeader(data:String):Dynamic {
			var PCDheader = {};
			var result1 = data.indexOf('DATA ' + '\n');
			var result2 = /DATA\s(\S*)\s/.exec(data.substring(result1 - 1));

			PCDheader.data = result2[1];
			PCDheader.headerLen = result2[0].length + result1;
			PCDheader.str = data.substring(0, PCDheader.headerLen);

			// remove comments
			PCDheader.str = PCDheader.str.replace(/#.*/gi, '');

			// parse
			PCDheader.version = /VERSION (.*)/i.exec(PCDheader.str);
			PCDheader.fields = /FIELDS (.*)/i.exec(PCDheader.str);
			PCDheader.size = /SIZE (.*)/i.exec(PCDheader.str);
			PCDheader.type = /TYPE (.*)/i.exec(PCDheader.str);
			PCDheader.count = /COUNT (.*)/i.exec(PCDheader.str);
			PCDheader.width = /WIDTH (.*)/i.exec(PCDheader.str);
			PCDheader.height = /HEIGHT (.*)/i.exec(PCDheader.str);
			PCDheader.viewpoint = /VIEWPOINT (.*)/i.exec(PCDheader.str);
			PCDheader.points = /POINTS (.*)/i.exec(PCDheader.str);

			// evaluate
			if (PCDheader.version != null) {
				PCDheader.version = Std.parseFloat(PCDheader.version[1]);
			}

			PCDheader.fields = (PCDheader.fields != null) ? PCDheader.fields[1].split(' ') : [];

			if (PCDheader.type != null) {
				PCDheader.type = PCDheader.type[1].split(' ');
			}

			if (PCDheader.width != null) {
				PCDheader.width = Std.parseInt(PCDheader.width[1]);
			}

			if (PCDheader.height != null) {
				PCDheader.height = Std.parseInt(PCDheader.height[1]);
			}

			if (PCDheader.viewpoint != null) {
				PCDheader.viewpoint = PCDheader.viewpoint[1];
			}

			if (PCDheader.points != null) {
				PCDheader.points = Std.parseInt(PCDheader.points[1], 10);
			}

			if (PCDheader.points == null) {
				PCDheader.points = PCDheader.width * PCDheader.height;
			}

			if (PCDheader.size != null) {
				PCDheader.size = PCDheader.size[1].split(' ').map(function(x) {
					return Std.parseInt(x, 10);
				});
			}

			if (PCDheader.count != null) {
				PCDheader.count = PCDheader.count[1].split(' ').map(function(x) {
					return Std.parseInt(x, 10);
				});
			} else {
				PCDheader.count = [];
				for (i in 0...PCDheader.fields.length) {
					PCDheader.count.push(1);
				}
			}

			PCDheader.offset = {};
			var sizeSum = 0;
			for (i in 0...PCDheader.fields.length) {
				if (PCDheader.data == 'ascii') {
					PCDheader.offset[PCDheader.fields[i]] = i;
				} else {
					PCDheader.offset[PCDheader.fields[i]] = sizeSum;
					sizeSum += PCDheader.size[i] * PCDheader.count[i];
				}
			}

			// for binary only
			PCDheader.rowSize = sizeSum;

			return PCDheader;
		}

		var textData = new String(data);

		// parse header (always ascii format)
		var PCDheader = parseHeader(textData);

		// parse data
		var position:Array<Float> = [];
		var normal:Array<Float> = [];
		var color:Array<Float> = [];
		var intensity:Array<Float> = [];
		var label:Array<Int> = [];

		var c = new Color();

		// ascii
		if (PCDheader.data == 'ascii') {
			var offset = PCDheader.offset;
			var pcdData = textData.substring(PCDheader.headerLen);
			var lines = pcdData.split('\n');
			for (i in 0...lines.length) {
				if (lines[i] == '') continue;
				var line = lines[i].split(' ');
				if (offset.x != null) {
					position.push(Std.parseFloat(line[offset.x]));
					position.push(Std.parseFloat(line[offset.y]));
					position.push(Std.parseFloat(line[offset.z]));
				}
				if (offset.rgb != null) {
					var rgb_field_index = PCDheader.fields.indexOf('rgb');
					var rgb_type = PCDheader.type[rgb_field_index];
					var float = Std.parseFloat(line[offset.rgb]);
					var rgb = float;
					if (rgb_type == 'F') {
						// treat float values as int
						// https://github.com/daavoo/pyntcloud/pull/204/commits/7b4205e64d5ed09abe708b2e91b615690c24d518
						var farr = new Float32Array(1);
						farr[0] = float;
						rgb = new Int32Array(farr.buffer)[0];
					}
					var r = ((rgb >> 16) & 0x0000ff) / 255;
					var g = ((rgb >> 8) & 0x0000ff) / 255;
					var b = ((rgb >> 0) & 0x0000ff) / 255;
					c.set(r, g, b).convertSRGBToLinear();
					color.push(c.r, c.g, c.b);
				}
				if (offset.normal_x != null) {
					normal.push(Std.parseFloat(line[offset.normal_x]));
					normal.push(Std.parseFloat(line[offset.normal_y]));
					normal.push(Std.parseFloat(line[offset.normal_z]));
				}
				if (offset.intensity != null) {
					intensity.push(Std.parseFloat(line[offset.intensity]));
				}
				if (offset.label != null) {
					label.push(Std.parseInt(line[offset.label]));
				}
			}
		}

		// binary-compressed
		// normally data in PCD files are organized as array of structures: XYZRGBXYZRGB
		// binary compressed PCD files organize their data as structure of arrays: XXYYZZRGBRGB
		// that requires a totally different parsing approach compared to non-compressed data
		if (PCDheader.data == 'binary_compressed') {
			var sizes = new Uint32Array(data.sub(PCDheader.headerLen, 8).buffer);
			var compressedSize = sizes[0];
			var decompressedSize = sizes[1];
			var decompressed = decompressLZF(data.sub(PCDheader.headerLen + 8, compressedSize), decompressedSize);
			var dataview = new DataView(decompressed.buffer);
			var offset = PCDheader.offset;
			for (i in 0...PCDheader.points) {
				if (offset.x != null) {
					var xIndex = PCDheader.fields.indexOf('x');
					var yIndex = PCDheader.fields.indexOf('y');
					var zIndex = PCDheader.fields.indexOf('z');
					position.push(dataview.getFloat32((PCDheader.points * offset.x) + PCDheader.size[xIndex] * i, this.littleEndian));
					position.push(dataview.getFloat32((PCDheader.points * offset.y) + PCDheader.size[yIndex] * i, this.littleEndian));
					position.push(dataview.getFloat32((PCDheader.points * offset.z) + PCDheader.size[zIndex] * i, this.littleEndian));
				}
				if (offset.rgb != null) {
					var rgbIndex = PCDheader.fields.indexOf('rgb');
					var r = dataview.getUint8((PCDheader.points * offset.rgb) + PCDheader.size[rgbIndex] * i + 2) / 255.0;
					var g = dataview.getUint8((PCDheader.points * offset.rgb) + PCDheader.size[rgbIndex] * i + 1) / 255.0;
					var b = dataview.getUint8((PCDheader.points * offset.rgb) + PCDheader.size[rgbIndex] * i + 0) / 255.0;
					c.set(r, g, b).convertSRGBToLinear();
					color.push(c.r, c.g, c.b);
				}
				if (offset.normal_x != null) {
					var xIndex = PCDheader.fields.indexOf('normal_x');
					var yIndex = PCDheader.fields.indexOf('normal_y');
					var zIndex = PCDheader.fields.indexOf('normal_z');
					normal.push(dataview.getFloat32((PCDheader.points * offset.normal_x) + PCDheader.size[xIndex] * i, this.littleEndian));
					normal.push(dataview.getFloat32((PCDheader.points * offset.normal_y) + PCDheader.size[yIndex] * i, this.littleEndian));
					normal.push(dataview.getFloat32((PCDheader.points * offset.normal_z) + PCDheader.size[zIndex] * i, this.littleEndian));
				}
				if (offset.intensity != null) {
					var intensityIndex = PCDheader.fields.indexOf('intensity');
					intensity.push(dataview.getFloat32((PCDheader.points * offset.intensity) + PCDheader.size[intensityIndex] * i, this.littleEndian));
				}
				if (offset.label != null) {
					var labelIndex = PCDheader.fields.indexOf('label');
					label.push(dataview.getInt32((PCDheader.points * offset.label) + PCDheader.size[labelIndex] * i, this.littleEndian));
				}
			}
		}

		// binary
		if (PCDheader.data == 'binary') {
			var dataview = new DataView(data.sub(PCDheader.headerLen).buffer);
			var offset = PCDheader.offset;
			var row = 0;
			for (i in 0...PCDheader.points) {
				if (offset.x != null) {
					position.push(dataview.getFloat32(row + offset.x, this.littleEndian));
					position.push(dataview.getFloat32(row + offset.y, this.littleEndian));
					position.push(dataview.getFloat32(row + offset.z, this.littleEndian));
				}
				if (offset.rgb != null) {
					var r = dataview.getUint8(row + offset.rgb + 2) / 255.0;
					var g = dataview.getUint8(row + offset.rgb + 1) / 255.0;
					var b = dataview.getUint8(row + offset.rgb + 0) / 255.0;
					c.set(r, g, b).convertSRGBToLinear();
					color.push(c.r, c.g, c.b);
				}
				if (offset.normal_x != null) {
					normal.push(dataview.getFloat32(row + offset.normal_x, this.littleEndian));
					normal.push(dataview.getFloat32(row + offset.normal_y, this.littleEndian));
					normal.push(dataview.getFloat32(row + offset.normal_z, this.littleEndian));
				}
				if (offset.intensity != null) {
					intensity.push(dataview.getFloat32(row + offset.intensity, this.littleEndian));
				}
				if (offset.label != null) {
					label.push(dataview.getInt32(row + offset.label, this.littleEndian));
				}
				row += PCDheader.rowSize;
			}
		}

		// build geometry
		var geometry = new BufferGeometry();
		if (position.length > 0) geometry.setAttribute('position', new Float32BufferAttribute(position, 3));
		if (normal.length > 0) geometry.setAttribute('normal', new Float32BufferAttribute(normal, 3));
		if (color.length > 0) geometry.setAttribute('color', new Float32BufferAttribute(color, 3));
		if (intensity.length > 0) geometry.setAttribute('intensity', new Float32BufferAttribute(intensity, 1));
		if (label.length > 0) geometry.setAttribute('label', new Int32BufferAttribute(label, 1));
		geometry.computeBoundingSphere();

		// build material
		var material = new PointsMaterial({size: 0.005});
		if (color.length > 0) {
			material.vertexColors = true;
		}

		// build point cloud
		return new Points(geometry, material);
	}

}