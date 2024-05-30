package;

import haxe.io.Bytes;
import js.Browser;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int32Array;
import js.html.Uint8Array;
import js.html.Uint32Array;

class PCDLoader {
    public var littleEndian:Bool;
    private var manager:Dynamic;

    public function new(manager:Dynamic) {
        littleEndian = true;
        this.manager = manager;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var scope = this;
        var loader = new FileLoader(manager);
        loader.path = path;
        loader.responseType = 'arraybuffer';
        loader.withCredentials = withCredentials;
        loader.load(url, function(data) {
            try {
                onLoad(scope.parse(data));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    Browser.console.error(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:Bytes):Points {
        function decompressLZF(inData:Bytes, outLength:Int):Bytes {
            var inLength = inData.length;
            var outData = new Bytes(outLength);
            var inPtr = 0;
            var outPtr = 0;
            var ctrl:Int;
            var len:Int;
            var ref:Int;
            while (inPtr < inLength) {
                ctrl = inData.getInt8(inPtr++);
                if (ctrl < (1 << 5)) {
                    ctrl++;
                    if (outPtr + ctrl > outLength) {
                        throw new Error('Output buffer is not large enough');
                    }
                    if (inPtr + ctrl > inLength) {
                        throw new Error('Invalid compressed data');
                    }
                    while (ctrl-- > 0) {
                        outData.set(inData, inPtr++, outPtr++);
                    }
                } else {
                    len = ctrl >> 5;
                    ref = outPtr - ((ctrl & 0x1f) << 8) - 1;
                    if (inPtr >= inLength) {
                        throw new Error('Invalid compressed data');
                    }
                    if (len == 7) {
                        len += inData.getInt8(inPtr++);
                        if (inPtr >= inLength) {
                            throw new Error('Invalid compressed data');
                        }
                    }
                    ref -= inData.getInt8(inPtr++);
                    if (outPtr + len + 2 > outLength) {
                        throw new Error('Output buffer is not large enough');
                    }
                    if (ref < 0) {
                        throw new Error('Invalid compressed data');
                    }
                    if (ref >= outPtr) {
                        throw new Error('Invalid compressed data');
                    }
                    while (len-- > 0) {
                        outData.set(outData, ref++, outPtr++);
                    }
                }
            }
            return outData;
        }

        function parseHeader(data:String):PCDHeader {
            var PCDheader = new PCDHeader();
            var result1 = data.indexOf('\nDATA\s');
            var result2 = data.substr(result1).split(' ');
            PCDheader.data = result2[1];
            PCDheader.headerLen = result2.length + result1;
            PCDheader.str = data.substr(0, PCDheader.headerLen);
            PCDheader.str = PCDheader.str.split('#').map($it -> $it.split('\n')[0]).join('\n');
            PCDheader.version = PCDheader.str.match(/VERSION (.*)/i);
            PCDheader.fields = PCDheader.str.match(/FIELDS (.*)/i);
            PCDheader.size = PCDheader.str.match(/SIZE (.*)/i);
            PCDheader.type = PCDheader.str.match(/TYPE (.*)/i);
            PCDheader.count = PCDheader.str.match(/COUNT (.*)/i);
            PCDheader.width = PCDheader.str.match(/WIDTH (.*)/i);
            PCDheader.height = PCDheader.str.match(/HEIGHT (.*)/i);
            PCDheader.viewpoint = PCDheader.str.match(/VIEWPOINT (.*)/i);
            PCDheader.points = PCDheader.str.match(/POINTS (.*)/i);
            if (PCDheader.version != null) {
                PCDheader.version = Std.parseFloat(PCDheader.version[1]);
            }
            if (PCDheader.fields != null) {
                PCDheader.fields = PCDheader.fields[1].split(' ');
            }
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
                PCDheader.points = Std.parseInt(PCDheader.points[1]);
            }
            if (PCDheader.points == null) {
                PCDheader.points = PCDheader.width * PCDheader.height;
            }
            if (PCDheader.size != null) {
                PCDheader.size = PCDheader.size[1].split(' ').map($it -> Std.parseInt($it));
            }
            if (PCDheader.count != null) {
                PCDheader.count = PCDheader.count[1].split(' ').map($it -> Std.parseInt($it));
            } else {
                PCDheader.count = [];
                var i = 0;
                var l = PCDheader.fields.length;
                while (i < l) {
                    PCDheader.count.push(1);
                    i++;
                }
            }
            PCDheader.offset = new Map<String, Int>();
            var sizeSum = 0;
            i = 0;
            l = PCDheader.fields.length;
            while (i < l) {
                var field = PCDheader.fields[i];
                if (PCDheader.data == 'ascii') {
                    PCDheader.offset.set(field, i);
                } else {
                    PCDheader.offset.set(field, sizeSum);
                    sizeSum += PCDheader.size[i] * PCDheader.count[i];
                }
                i++;
            }
            PCDheader.rowSize = sizeSum;
            return PCDheader;
        }

        var textData = data.getString(data.length, 'utf8');
        var PCDheader = parseHeader(textData);
        var position = [];
        var normal = [];
        var color = [];
        var intensity = [];
        var label = [];
        var c = new Color();
        if (PCDheader.data == 'ascii') {
            var offset = PCDheader.offset;
            var pcdData = textData.substr(PCDheader.headerLen);
            var lines = pcdData.split('\n');
            var i = 0;
            var l = lines.length;
            while (i < l) {
                var line = lines[i].split(' ');
                if (offset.exists('x')) {
                    position.push(Std.parseFloat(line[offset.get('x')]));
                    position.push(Std.parseFloat(line[offset.get('y')]));
                    position.push(Std.parseFloat(line[offset.get('z')]));
                }
                if (offset.exists('rgb')) {
                    var rgb_field_index = PCDheader.fields.indexOf('rgb');
                    var rgb_type = PCDheader.type[rgb_field_index];
                    var float = Std.parseFloat(line[offset.get('rgb')]);
                    var rgb:Int;
                    if (rgb_type == 'F') {
                        var farr = new Float32Array([float]);
                        rgb = new Int32Array(farr.buffer)[0];
                    } else {
                        rgb = float;
                    }
                    var r = ((rgb >> 16) & 0x000ff) / 255;
                    var g = ((rgb >> 8) & 0x0000ff) / 255;
                    var b = (rgb & 0x0000ff) / 255;
                    c.set(r, g, b);
                    c.convertSRGBToLinear();
                    color.push(c.r, c.g, c.b);
                }
                if (offset.exists('normal_x')) {
                    normal.push(Std.parseFloat(line[offset.get('normal_x')]));
                    normal.push(Std.parseFloat(line[offset.get('normal_y')]));
                    normal.push(Std.parseFloat(line[offset.get('normal_z')]));
                }
                if (offset.exists('intensity')) {
                    intensity.push(Std.parseFloat(line[offset.get('intensity')]));
                }
                if (offset.exists('label')) {
                    label.push(Std.parseInt(line[offset.get('label')]));
                }
                i++;
            }
        }
        if (PCDheader.data == 'binary_compressed') {
            var sizes = new Uint32Array(data.getBytes().slice(PCDheader.headerLen, PCDheader.headerLen + 8));
            var compressedSize = sizes[0];
            var decompressedSize = sizes[1];
            var decompressed = decompressLZF(data.getBytes().slice(PCDheader.headerLen + 8, PCDheader.headerLen + 8 + compressedSize), decompressedSize);
            var dataview = new DataView(decompressed);
            var offset = PCDheader.offset;
            var i = 0;
            while (i < PCDheader.points) {
                if (offset.exists('x')) {
                    var xIndex = PCDheader.fields.indexOf('x');
                    var yIndex = PCDheader.fields.indexOf('y');
                    var zIndex = PCDheader.fields.indexOf('z');
                    position.push(dataview.getFloat32(PCDheader.points * offset.get('x') + PCDheader.size[xIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.get('y') + PCDheader.size[yIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.get('z') + PCDheader.size[zIndex] * i, littleEndian));
                }
                if (offset.exists('rgb')) {
                    var rgbIndex = PCDheader.fields.indexOf('rgb');
                    var r = dataview.getUint8(PCDheader.points * offset.get('rgb') + PCDheader.size[rgbIndex] * i + 2) / 255.0;
                    var g = dataview.getUint8(PCDheader.points * offset.get('rgb') + PCDheader.size[rgbIndex] * i + 1) / 255.0;
                    var b = dataview.getUint8(PCDheader.points * offset.get('rgb') + PCDheader.size[rgbIndex] * i + 0) / 255.0;
                    c.set(r, g, b);
                    c.convertSRGBToLinear();
                    color.push(c.r, c.g, c.b);
                }
                if (offset.exists('normal_x')) {
                    var xIndex = PCDheader.fields.indexOf('normal_x');
                    var yIndex = PCDheader.fields.indexOf('normal_y');
                    var zIndex = PCDheader.fields.indexOf('normal_z');
                    normal.push(dataview.getFloat32(PCDheader.points * offset.get('normal_x') + PCDheader.size[xIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.get('normal_y') + PCDheader.size[yIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.get('normal_z') + PCDheader.size[zIndex] * i, littleEndian));
                }
                if (offset.exists('intensity')) {
                    var intensityIndex = PCDheader.fields.indexOf('intensity');
                    intensity.push(dataview.getFloat32(PCDheader.points * offset.get('intensity') + PCDheader.size[intensityIndex] * i, littleEndian));
                }
                if (offset.exists('label')) {
                    var labelIndex = PCDheader.fields.indexOf('label');
                    label.push(dataview.getInt32(PCDheader.points * offset.get('label') + PCDheader.size[labelIndex] * i, littleEndian));
                }
                i++;
            }
        }
        if (PCDheader.data == 'binary') {
            var dataview = new DataView(data.getBytes().slice(PCDheader.headerLen));
            var offset = PCDheader.offset;
            var i = 0;
            var row = 0;
            while (i < PCDheader.points) {
                if (offset.exists('x')) {
                    position.push(dataview.getFloat32(row + offset.get('x'), littleEndian));
                    position.push(dataview.getFloat32(row + offset.get('y'), littleEndian));
                    position.push(dataview.getFloat32(row + offset.get('z'), littleEndian));
                }
                if (offset.exists('rgb')) {
                    var r = dataview.getUint8(row + offset.get('rgb') + 2) / 255.0;
                    var g = dataview.getUint8(row + offset.get('rgb') + 1) / 255.0;
                    var b = dataview.getUint8(row + offset.get('rgb')) / 255.0;
                    c.set(r, g, b);
                    c.convertSRGBToLinear();
                    color.push(c.r, c.g, c.b);
                }
                if (offset.exists('normal_x')) {
                    normal.push(dataview.getFloat32(row + offset.get('normal_x'), littleEndian));
                    normal.push(dataview.getFloat32(row + offset.get('normal_y'), littleEndian));
                    normal.push(dataview.getFloat32(row + offset.get('normal_z'), littleEndian));
                }
                if (offset.exists('intensity')) {
                    intensity.push(dataview.getFloat32(row + offset.get('intensity'), littleEndian));
                }
                if (offset.exists('label')) {
                    label.push(dataview.getInt32(row + offset.get('label'), littleEndian));
                }
                row += PCDheader.rowSize;
                i++;
            }
        }
        var geometry = new BufferGeometry();
        if (position.length > 0) {
            geometry.setAttribute('position', new Float32BufferAttribute(position, 3));
        }
        if (normal.length > 0) {
            geometry.setAttribute('normal', new Float32BufferAttribute(normal, 3));
        }
        if (color.length > 0) {
            geometry.setAttribute('color', new Float32BufferAttribute(color, 3));
        }
        if (intensity.length > 0) {
            geometry.setAttribute('intensity', new Float32BufferAttribute(intensity, 1));
        }
        if (label.length > 0) {
            geometry.setAttribute('label', new Int32BufferAttribute(label, 1));
        }
        geometry.computeBoundingSphere();
        var material = new PointsMaterial({ size: 0.005 });
        if (color.length > 0) {
            material.vertexColors = true;
        }
        return new Points(geometry, material);
    }
}

class PCDHeader {
    public var data:String;
    public var headerLen:Int;
    public var str:String;
    public var version:Float;
    public var fields:Array<String>;
    public var size:Array<Int>;
    public var type:Array<String>;
    public var count:Array<Int>;
    public var width:Int;
    public var height:Int;
    public var viewpoint:String;
    public var points:Int;
    public var offset:Map<String, Int>;
    public var rowSize:Int;
}

class FileLoader {
    public var manager:Dynamic;
    public var path:String;
    public var responseType:String;
    public var withCredentials:Bool;

    public function new(manager:Dynamic) {
        this.manager = manager;
    }

    public function setPath(path:String):Void {
        this.path = path;
    }

    public function setResponseType(responseType:String):Void {
        this.responseType = responseType;
    }

    public function setRequestHeader(requestHeader:Dynamic):Void {
        // To be implemented
    }

    public function setWithCredentials(withCredentials:Bool):Void {
        this.withCredentials = withCredentials;
    }

    public function load(url:
    function(onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        // To be implemented
    }
}

class BufferGeometry {
    public function setAttribute(name:String, attribute:Dynamic):Void {
        // To be implemented
    }

    public function computeBoundingSphere():Void {
        // To be implemented
    }
}

class Points {
    public function new(geometry:Dynamic, material:Dynamic) {
        // To be implemented
    }
}

class PointsMaterial {
    public var size:Float;
    public var vertexColors:Bool;

    public function new(parameters:Dynamic) {
        size = parameters.size;
        vertexColors = parameters.vertexColors;
    }
}

class Float32BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int) {
        // To be implemented
    }
}

class Int32BufferAttribute {
    public function new(array:Array<Int>, itemSize:Int) {
        // To be implemented
    }
}

class Color {
    public var r:Float;
    public var g:Float;
    public var b:Float;

    public function set(r:Float, g:Float, b:Float):Void {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    public function convertSRGBToLinear():Void {
        // To be implemented
    }
}