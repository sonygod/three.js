import three.loaders.DataTextureLoader;
import three.textures.Texture;
import three.textures.CubeTexture;
import three.constants.TextureConstants;
import three.constants.Mapping;
import three.math.Math;
import three.utils.DataUtils;
import haxe.io.Bytes;

class RGBMLoader extends DataTextureLoader {

    public var type:Int;
    public var maxRange:Int;

    public function new(manager:Loader = null) {
        super(manager);
        this.type = TextureConstants.HalfFloatType;
        this.maxRange = 7;
    }

    public function setDataType(value:Int):RGBMLoader {
        this.type = value;
        return this;
    }

    public function setMaxRange(value:Int):RGBMLoader {
        this.maxRange = value;
        return this;
    }

    public function loadCubemap(urls:Array<String>, onLoad:Function = null, onProgress:Function = null, onError:Function = null):CubeTexture {
        var texture = new CubeTexture();
        for (var i in 0...6) {
            texture.images[i] = null;
        }
        var loaded = 0;
        var scope = this;
        function loadTexture(i:Int) {
            scope.load(urls[i], function(image:HTMLImageElement) {
                texture.images[i] = image;
                loaded++;
                if (loaded === 6) {
                    texture.needsUpdate = true;
                    if (onLoad != null) onLoad(texture);
                }
            }, onProgress, onError);
        }
        for (var i in 0...urls.length) {
            loadTexture(i);
        }
        texture.type = this.type;
        texture.format = TextureConstants.RGBAFormat;
        texture.minFilter = TextureConstants.LinearFilter;
        texture.generateMipmaps = false;
        return texture;
    }

    public function loadCubemapAsync(urls:Array<String>, onProgress:Function = null):Promise<CubeTexture> {
        return new Promise((resolve, reject) => {
            this.loadCubemap(urls, resolve, onProgress, reject);
        });
    }

    public function parse(buffer:Bytes):Dynamic {
        var img = UPNG.decode(buffer);
        var rgba = UPNG.toRGBA8(img)[0];
        var data = new Uint8Array(rgba);
        var size = img.width * img.height * 4;
        var output = (this.type === TextureConstants.HalfFloatType) ? new Uint16Array(size) : new Float32Array(size);
        for (var i in 0...data.length) {
            if (i % 4 != 3) {
                var value = data[i] / 255;
                var alpha = data[i + 3] / 255;
                if (this.type === TextureConstants.HalfFloatType) {
                    output[i] = DataUtils.toHalfFloat(Math.min(value * alpha * this.maxRange, 65504));
                } else {
                    output[i] = value * alpha * this.maxRange;
                }
            } else {
                if (this.type === TextureConstants.HalfFloatType) {
                    output[i] = DataUtils.toHalfFloat(1);
                } else {
                    output[i] = 1;
                }
            }
        }
        return {
            width: img.width,
            height: img.height,
            data: output,
            format: TextureConstants.RGBAFormat,
            type: this.type,
            flipY: true
        };
    }
}

class UPNG {
    public static function toRGBA8(out:Dynamic):Array<Bytes> {
        var w = out.width;
        var h = out.height;
        if (out.tabs.acTL == null) return [UPNG.toRGBA8.decodeImage(out.data, w, h, out)];
        var frms = new Array<Bytes>();
        if (out.frames[0].data == null) out.frames[0].data = out.data;
        var len = w * h * 4;
        var bf = new Uint8Array(len);
        var bf32 = new Uint32Array(bf.buffer);
        var ctype = out.ctype;
        var depth = out.depth;
        var rs = UPNG._bin.readUshort;
        if (ctype == 6) {
            var qarea = len;
            if (depth == 8) {
                for (var i in 0...qarea) {
                    bf[i] = out.data[i];
                }
            } else if (depth == 16) {
                for (var i in 0...qarea) {
                    bf[i] = out.data[i << 1];
                }
            }
        } else if (ctype == 2) {
            var ts = out.tabs['tRNS'];
            if (ts == null) {
                if (depth == 8) {
                    for (var i in 0...len) {
                        var ti = i * 3;
                        bf32[i] = (255 << 24) | (out.data[ti + 2] << 16) | (out.data[ti + 1] << 8) | out.data[ti];
                    }
                } else if (depth == 16) {
                    for (var i in 0...len) {
                        var ti = i * 6;
                        bf32[i] = (255 << 24) | (out.data[ti + 4] << 16) | (out.data[ti + 2] << 8) | out.data[ti];
                    }
                }
            } else {
                var tr = ts[0];
                var tg = ts[1];
                var tb = ts[2];
                if (depth == 8) {
                    for (var i in 0...len) {
                        var qi = i << 2;
                        var ti = i * 3;
                        bf32[i] = (255 << 24) | (out.data[ti + 2] << 16) | (out.data[ti + 1] << 8) | out.data[ti];
                        if (out.data[ti] == tr && out.data[ti + 1] == tg && out.data[ti + 2] == tb) bf[qi + 3] = 0;
                    }
                } else if (depth == 16) {
                    for (var i in 0...len) {
                        var qi = i << 2;
                        var ti = i * 6;
                        bf32[i] = (255 << 24) | (out.data[ti + 4] << 16) | (out.data[ti + 2] << 8) | out.data[ti];
                        if (rs(out.data, ti) == tr && rs(out.data, ti + 2) == tg && rs(out.data, ti + 4) == tb) bf[qi + 3] = 0;
                    }
                }
            }
        } else if (ctype == 3) {
            var p = out.tabs['PLTE'];
            var ap = out.tabs['tRNS'];
            var tl = ap != null ? ap.length : 0;
            if (depth == 1) {
                for (var y in 0...h) {
                    var s0 = y * bpl;
                    var t0 = y * w;
                    for (var x in 0...w) {
                        var qi = (t0 + x) << 2;
                        var j = (out.data[s0 + (x >> 3)] >> (7 - ((x & 7) << 0))) & 1;
                        var cj = 3 * j;
                        bf[qi] = p[cj];
                        bf[qi + 1] = p[cj + 1];
                        bf[qi + 2] = p[cj + 2];
                        bf[qi + 3] = (j < tl) ? ap[j] : 255;
                    }
                }
            } else if (depth == 2) {
                for (var y in 0...h) {
                    var s0 = y * bpl;
                    var t0 = y * w;
                    for (var x in 0...w) {
                        var qi = (t0 + x) << 2;
                        var j = (out.data[s0 + (x >> 2)] >> (6 - ((x & 3) << 1))) & 3;
                        var cj = 3 * j;
                        bf[qi] = p[cj];
                        bf[qi + 1] = p[cj + 1];
                        bf[qi + 2] = p[cj + 2];
                        bf[qi + 3] = (j < tl) ? ap[j] : 255;
                    }
                }
            } else if (depth == 4) {
                for (var y in 0...h) {
                    var s0 = y * bpl;
                    var t0 = y * w;
                    for (var x in 0...w) {
                        var qi = (t0 + x) << 2;
                        var j = (out.data[s0 + (x >> 1)] >> (4 - ((x & 1) << 2))) & 15;
                        var cj = 3 * j;
                        bf[qi] = p[cj];
                        bf[qi + 1] = p[cj + 1];
                        bf[qi + 2] = p[cj + 2];
                        bf[qi + 3] = (j < tl) ? ap[j] : 255;
                    }
                }
            } else if (depth == 8) {
                for (var i in 0...len) {
                    var qi = i << 2;
                    var j = out.data[i];
                    var cj = 3 * j;
                    bf[qi] = p[cj];
                    bf[qi + 1] = p[cj + 1];
                    bf[qi + 2] = p[cj + 2];
                    bf[qi + 3] = (j < tl) ? ap[j] : 255;
                }
            }
        } else if (ctype == 4) {
            if (depth == 8) {
                for (var i in 0...len) {
                    var qi = i << 2;
                    var di = i << 1;
                    var gr = out.data[di];
                    bf[qi] = gr;
                    bf[qi + 1] = gr;
                    bf[qi + 2] = gr;
                    bf[qi + 3] = out.data[di + 1];
                }
            } else if (depth == 16) {
                for (var i in 0...len) {
                    var qi = i << 2;
                    var di = i << 2;
                    var gr = out.data[di];
                    bf[qi] = gr;
                    bf[qi + 1] = gr;
                    bf[qi + 2] = gr;
                    bf[qi + 3] = out.data[di + 2];
                }
            }
        } else if (ctype == 0) {
            var tr = out.tabs['tRNS'] != null ? out.tabs['tRNS'] : -1;
            for (var y in 0...h) {
                var off = y * bpl;
                var to = y * w;
                if (depth == 1) {
                    for (var x in 0...w) {
                        var gr = 255 * (((out.data[off + (x >>> 3)] >>> (7 - (x & 7))) & 1));
                        var al = (gr == tr * 255) ? 0 : 255;
                        bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
                    }
                } else if (depth == 2) {
                    for (var x in 0...w) {
                        var gr = 85 * (((out.data[off + (x >>> 2)] >>> (6 - ((x & 3) << 1))) & 3));
                        var al = (gr == tr * 85) ? 0 : 255;
                        bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
                    }
                } else if (depth == 4) {
                    for (var x in 0...w) {
                        var gr = 17 * (((out.data[off + (x >>> 1)] >>> (4 - ((x & 1) << 2))) & 15));
                        var al = (gr == tr * 17) ? 0 : 255;
                        bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
                    }
                } else if (depth == 8) {
                    for (var x in 0...w) {
                        var gr = out.data[off + x];
                        var al = (gr == tr) ? 0 : 255;
                        bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
                    }
                } else if (depth == 16) {
                    for (var x in 0...w) {
                        var gr = out.data[off + (x << 1)];
                        var al = (rs(out.data, off + (x << 1)) == tr) ? 0 : 255;
                        bf32[to + x] = (al << 24) | (gr << 16) | (gr << 8) | gr;
                    }
                }
            }
        }
        return [Bytes.ofData(bf)];
    }

    public static function decode(buff:Bytes):Dynamic {
        var data = new Uint8Array(buff.getBytes());
        var offset = 8;
        var bin = UPNG._bin;
        var rUs = bin.readUshort;
        var rUi = bin.readUint;
        var out = { tabs: {}, frames: [] };
        var dd = new Uint8Array(data.length);
        var doff = 0;
        var fd = new Uint8Array(data.length);
        var foff = 0;
        var text:String;
        var keyw:String;
        var bfr:Bytes;

        var mgck = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
        for (var i in 0...8) {
            if (data[i] != mgck[i]) throw new Error('The input is not a PNG file!');
        }

        while (offset < data.length) {
            var len = bin.readUint(data, offset);
            offset += 4;
            var type = bin.readASCII(data, offset, 4);
            offset += 4;

            if (type == 'IHDR') {
                UPNG.decode._IHDR(data, offset, out);
            } else if (type == 'CgBI') {
                out.tabs[type] = data.slice(offset, offset + 4);
            } else if (type == 'IDAT') {
                for (var i in 0...len) {
                    dd[doff + i] = data[offset + i];
                }
                doff += len;
            } else if (type == 'acTL') {
                out.tabs[type] = { num_frames: rUi(data, offset), num_plays: rUi(data, offset + 4) };
            } else if (type == 'fcTL') {
                if (foff != 0) {
                    var fr = out.frames[out.frames.length - 1];
                    fr.data = UPNG.decode._decompress(out, fd.slice(0, foff), fr.rect.width, fr.rect.height);
                    foff = 0;
                }
                var rct = { x: rUi(data, offset + 12), y: rUi(data, offset + 16), width: rUi(data, offset + 4), height: rUi(data, offset + 8) };
                var del = rUs(data, offset + 22);
                del = rUs(data, offset + 20) / (del == 0 ? 100 : del);
                var frm = { rect: rct, delay: Math.round(del * 1000), dispose: data[offset + 24], blend: data[offset + 25] };
                out.frames.push(frm);
            } else if (type == 'fdAT') {
                for (var i in 0...len - 4) {
                    fd[foff + i] = data[offset + i + 4];
                }
                foff += len - 4;
            } else if (type == 'pHYs') {
                out.tabs[type] = [bin.readUint(data, offset), bin.readUint(data, offset + 4), data[offset + 8]];
            } else if (type == 'cHRM') {
                out.tabs[type] = [];
                for (var i in 0...8) {
                    out.tabs[type].push(bin.readUint(data, offset + i * 4));
                }
            } else if (type == 'tEXt' || type == 'zTXt') {
                if (out.tabs[type] == null) out.tabs[type] = {};
                var nz = bin.nextZero(data, offset);
                keyw = bin.readASCII(data, offset, nz - offset);
                var tl = offset + len - nz - 1;
                if (type == 'tEXt') {
                    text = bin.readASCII(data, nz + 1, tl);
                } else {
                    bfr = UPNG.decode._inflate(data.slice(nz + 2, nz + 2 + tl));
                    text = bin.readUTF8(bfr, 0, bfr.length);
                }
                out.tabs[type][keyw] = text;
            } else if (type == 'iTXt') {
                if (out.tabs[type] == null) out.tabs[type] = {};
                var nz = 0;
                var off = offset;
                nz = bin.nextZero(data, off);
                keyw = bin.readASCII(data, off, nz - off);
                off = nz + 1;
                var cflag = data[off];
                off += 2;
                nz = bin.nextZero(data, off);
                bin.readASCII(data, off, nz - off);
                off = nz + 1;
                nz = bin.nextZero(data, off);
                bin.readUTF8(data, off, nz - off);
                off = nz + 1;
                var tl = len - (off - offset);
                if (cflag == 0) {
                    text = bin.readUTF8(data, off, tl);
                } else {
                    bfr = UPNG.decode._inflate(data.slice(off, off + tl));
                    text = bin.readUTF8(bfr, 0, bfr.length);
                }
                out.tabs[type][keyw] = text;
            } else if (type == 'PLTE') {
                out.tabs[type] = bin.readBytes(data, offset, len);
            } else if (type == 'hIST') {
                var pl = out.tabs['PLTE'].length / 3;
                out.tabs[type] = [];
                for (var i in 0...pl) {
                    out.tabs[type].push(rUs(data, offset + i * 2));
                }
            } else if (type == 'tRNS') {
                if (out.ctype == 3) {
                    out.tabs[type] = bin.readBytes(data, offset, len);
                } else if (out.ctype == 0) {
                    out.tabs[type] = rUs(data, offset);
                } else if (out.ctype == 2) {
                    out.tabs[type] = [rUs(data, offset), rUs(data, offset + 2), rUs(data, offset + 4)];
                }
            } else if (type == 'gAMA') {
                out.tabs[type] = bin.readUint(data, offset) / 100000;
            } else if (type == 'sRGB') {
                out.tabs[type] = data[offset];
            } else if (type == 'bKGD') {
                if (out.ctype == 0 || out.ctype == 4) {
                    out.tabs[type] = [rUs(data, offset)];
                } else if (out.ctype == 2 || out.ctype == 6) {
                    out.tabs[type] = [rUs(data, offset), rUs(data, offset + 2), rUs(data, offset + 4)];
                } else if (out.ctype == 3) {
                    out.tabs[type] = data[offset];
                }
            } else if (type == 'IEND') {
                break;
            }
            offset += len;
            bin.readUint(data, offset);
            offset += 4;
        }
        if (foff != 0) {
            var fr = out.frames[out.frames.length - 1];
            fr.data = UPNG.decode._decompress(out, fd.slice(0, foff), fr.rect.width, fr.rect.height);
        }
        out.data = UPNG.decode._decompress(out, dd, out.width, out.height);
        delete out.compress;
        delete out.interlace;
        delete out.filter;
        return out;
    }

    // Rest of the UPNG class methods...
}

class UPNG._bin {
    // Rest of the _bin class methods...
}