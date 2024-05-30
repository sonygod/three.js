package ;

import js.Browser.window;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Uint8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;

class RGBMLoader {
	var manager:Dynamic;
	var type:Dynamic;
	var maxRange:Int;

	public function new(manager:Dynamic) {
		this.manager = manager;
		this.type = js.html.HalfFloatType;
		this.maxRange = 7;
	}

	public function setDataType(value:Dynamic):Dynamic {
		this.type = value;
		return this;
	}

	public function setMaxRange(value:Int):Dynamic {
		this.maxRange = value;
		return this;
	}

	public function loadCubemap(urls:Array<String>, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		var texture = js.html.CubeTexture.create();

		for (i in 0...6) {
			texture.images[i] = null;
		}

		var loaded = 0;
		var scope = this;

		function loadTexture(i:Int) {
			scope.load(urls[i], function (image) {
				texture.images[i] = image;
				loaded++;

				if (loaded == 6) {
					texture.needsUpdate = true;

					if (onLoad != null) {
						onLoad(texture);
					}
				}
			}, null, onError);
		}

		for (i in 0...urls.length) {
			loadTexture(i);
		}

		texture.type = this.type;
		texture.format = js.html.RGBAFormat;
		texture.minFilter = js.html.LinearFilter;
		texture.generateMipmaps = false;

		return texture;
	}

	public function loadCubemapAsync(urls:Array<String>, onProgress:Dynamic):Dynamic {
		return js.Promise.handle(function (resolve, reject) {
			this.loadCubemap(urls, resolve, onProgress, reject);
		});
	}

	public function parse(buffer:ArrayBuffer):Dynamic {
		var img = UPNG.decode(buffer);
		var rgba = UPNG.toRGBA8(img)[0];

		var data = new Uint8Array(rgba);
		var size = img.width * img.height * 4;

		var output:Dynamic;
		if (this.type == js.html.HalfFloatType) {
			output = new Uint16Array(size);
		} else {
			output = new Float32Array(size);
		}

		// decode RGBM
		for (i in 0...data.length) {
			var r = data[i + 0] / 255;
			var g = data[i + 1] / 255;
			var b = data[i + 2] / 255;
			var a = data[i + 3] / 255;

			if (this.type == js.html.HalfFloatType) {
				output[i + 0] = DataUtils.toHalfFloat(min(r * a * this.maxRange, 65504));
				output[i + 1] = DataUtils.toHalfFloat(min(g * a * this.maxRange, 65504));
				output[i + 2] = DataUtils.toHalfFloat(min(b * a * this.maxRange, 65504));
				output[i + 3] = DataUtils.toHalfFloat(1);
			} else {
				output[i + 0] = r * a * this.maxRange;
				output[i + 1] = g * a * this.maxRange;
				output[i + 2] = b * a * this.maxRange;
				output[i + 3] = 1;
			}
		}

		return {
			width: img.width,
			height: img.height,
			data: output,
			format: js.html.RGBAFormat,
			type: this.type,
			flipY: true
		};
	}
}

class UPNG {
	static function toRGBA8(out:Dynamic):Dynamic {
		var w = out.width;
		var h = out.height;
		if (out.tabs.acTL == null) {
			return [UPNG.toRGBA8.decodeImage(out.data, w, h, out).buffer];
		}

		var frms = [];
		if (out.frames[0].data == null) {
			out.frames[0].data = out.data;
		}

		var len = w * h * 4;
		var img = new Uint8Array(len);
		var empty = new Uint8Array(len);
		var prev = new Uint8Array(len);
		for (i in 0...out.frames.length) {
			var frm = out.frames[i];
			var fx = frm.rect.x;
			var fy = frm.rect.y;
			var fw = frm.rect.width;
			var fh = frm.rect.height;
			var fdata = UPNG.toRGBA8.decodeImage(frm.data, fw, fh, out);

			if (i != 0) {
				for (j in 0...len) {
					prev[j] = img[j];
				}
			}

			if (frm.blend == 0) {
				UPNG._copyTile(fdata, fw, fh, img, w, h, fx, fy, 0);
			} else if (frm.blend == 1) {
				UPNG._copyTile(fdata, fw, fh, img, w, h, fx, fy, 1);
			}

			frms.push(img.buffer.slice(0));

			if (frm.dispose == 1) {
				UPNG._copyTile(empty, fw, fh, img, w, h, fx, fy, 0);
			} else if (frm.dispose == 2) {
				for (j in 0...len) {
					img[j] = prev[j];
				}
			}
		}

		return frms;
	}

	static function toRGBA8.decodeImage(data:Dynamic, w:Int, h:Int, out:Dynamic):Dynamic {
		var area = w * h;
		var bpp = UPNG.decode._getBPP(out);
		var bpl = Math.ceil(w * bpp / 8);

		var bf = new Uint8Array(area * 4);
		var bf32 = new Uint32Array(bf.buffer);
		var ctype = out.ctype;
		var depth = out.depth;
		var rs = UPNG._bin.readUshort;

		if (ctype == 6) {
			var qarea = area << 2;
			if (depth == 8) {
				for (i in 0...qarea) {
					bf[i] = data[i];
					bf[i + 1] = data[i + 1];
					bf[i + 2] = data[i + 2];
					bf[i + 3] = data[i + 3];
				}
			}

			if (depth == 16) {
				for (i in 0...qarea) {
					bf[i] = data[i << 1];
				}
			}
		} else if (ctype == 2) {
			var ts = out.tabs['tRNS'];
			if (ts == null) {
				if (depth == 8) {
					for (i in 0...area) {
						var ti = i * 3;
						bf32[i] = (255 << 24) | (data[ti + 2] << 16) | (data[ti + 1] << 8) | data[ti];
					}
				}

				if (depth == 16) {
					for (i in 0...area) {
						var ti = i * 6;
						bf32[i] = (255 << 24) | (data[ti + 4] << 16) | (data[ti + 2] << 8) | data[ti];
					}
				}
			} else {
				var tr = ts[0];
				var tg = ts[1];
				var tb = ts[2];
				if (depth == 8) {
					for (i in 0...area) {
						var qi = i << 2;
						var ti = i * 3;
						bf32[i] = (255 << 24) | (data[ti + 2] << 16) | (data[ti + 1] << 8) | data[ti];
						if (data[ti] == tr && data[ti + 1] == tg && data[ti + 2] == tb) {
							bf[qi + 3] = 0;
						}
					}
				}

				if (depth == 16) {
					for (i in 0...area) {
						var qi = i << 2;
						var ti = i * 6;
						bf32[i] = (255 << 24) | (data[ti + 4] << 16) | (data[ti + 2] << 8) | data[ti];
						if (rs(data, ti) == tr && rs(data, ti + 2) == tg && rs(data, ti + 4) == tb) {
							bf[qi + 3] = 0;
						}
					}
				}
			}
		} else if (ctype == 3) {
			var p = out.tabs['PLTE'];
			var ap = out.tabs['tRNS'];
			var tl = (ap != null) ? ap.length : 0;
			if (depth == 1) {
				for (y in 0...h) {
					var s0 = y * bpl;
					var t0 = y * w;
					for (i in 0...w) {
						var qi = (t0 + i) << 2;
						var j = ((data[s0 + (i >> 3)] >> (7 - ((i & 7) << 0))) & 1);
						var cj = 3 * j;
						bf[qi] = p[cj];
						bf[qi + 1] = p[cj + 1];
						bf[qi + 2] = p[cj + 2];
						bf[qi + 3] = (j < tl) ? ap[j] : 255;
					}
				}
			}

			if (depth == 2) {
				for (y in 0...h) {
					var s0 = y * bpl;
					var t0 = y * w;
					for (i in 0...w) {
						var qi = (t0 + i) << 2;
						var j = ((data[s0 + (i >> 2)] >> (6 - ((i & 3) << 1))) & 3);
						var cj = 3 * j;
						bf[qi] = p[cj];
						bf[qi + 1] = p[cj + 1];
						bf[qi + 2] = p[cj + 2];
						bf[qi + 3] = (j < tl) ? ap[j] : 255;
					}
				}
			}

			if (depth == 4) {
				for (y in 0...h) {
					var s0 = y * bpl;
					var t0 = y * w;
					for (i in 0...w) {
						var qi = (t0 + i) << 2;
						var j = ((data[s0 + (i >> 1)] >> (4 - ((i & 1) << 2))) & 15);
						var cj = 3 * j;
						bf[qi] = p[cj];
						bf[qi + 1] = p[cj + 1];
						bf[qi + 2] = p[cj + 2];
						bf[qi + 3] = (j < tl) ? ap[j] : 255;
					}
				}
			}

			if (depth == 8) {
				for (i in 0...area) {
					var qi = i << 2;
					var j = data[i];
					var cj = 3 * j;
					bf[qi] = p[cj];
					bf[qi + 1] = p[cj + 1];
					bf[qi + 2] = p[cj + 2];
					bf[qi + 3] = (j < tl) ? ap[j] : 255;
				}
			}
		} else if (ctype == 4) {
			if (depth == 8) {
				for (i in 0...area) {
					var qi = i << 2;
					var di = i << 1;
					var gr = data[di];
					bf[qi] = gr;
					bf[qi + 1] = gr;
					bf[qi + 2] = gr;
					bf[qi + 3] = data[di + 1];
				}
			}

			if (depth == 16) {
				for (i in 0...area) {
					var qi = i << 2;
					var di = i << 2;
					var gr = data[di];
					bf[qi] = gr;
					bf[qi + 1] = gr;
					bf[qi + 2] = gr;
					bf[qi + 3] = data[di + 2];
				}
			}
		} else if (ctype == 0) {
			var tr = (out.tabs['tRNS'] != null) ? out.tabs['tRNS'] : -1;
			for (y in 0...h) {
				var off = y * bpl;
				var to = y * w;
				if (depth == 1) {
					for (x in 0...w) {
						var gr = 255 * ((data[off + (x >>> 3)] >>> (7 - (x & 7))) & 1);
						var al = (gr == tr * 255) ? 0 : 255;
						bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
					}
				} else if (depth == 2) {
					for (x in 0...w) {
						var gr = 85 * ((data[off + (x >>> 2)] >>> (6 - ((x & 3) << 1))) & 3);
						var al = (gr == tr * 85) ? 0 : 255;
						bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
					}
				} else if (depth == 4) {
					for (x in 0...w) {
						var gr = 17 * ((data[off + (x >>> 1)] >>> (4 - ((x & 1) << 2))) & 15);
						var al = (gr == tr * 17) ? 0 : 255;
						bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
					}
				} else if (depth == 8) {
					for (x in 0...w) {
						var gr = data[off + x];
						var al = (gr == tr) ? 0 : 255;
						bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
					}
				} else if (depth == 16) {
					for (x in 0...w) {
						var gr = data[off + (x << 1)];
						var al = (rs(data, off + (x << 1)) == tr) ? 0 : 255;
						bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
					}