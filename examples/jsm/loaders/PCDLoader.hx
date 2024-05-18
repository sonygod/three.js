package three.js.examples.jsm.loaders;

import three.js.BufferGeometry;
import three.js.Color;
import three.js.FileLoader;
import three.js.Float32BufferAttribute;
import three.js.Int32BufferAttribute;
import three.js.Loader;
import three.js.Points;
import three.js.PointsMaterial;

class PCDLoader extends Loader {
    public var littleEndian:Bool;

    public function new(manager:Loader) {
        super(manager);
        littleEndian = true;
    }

    public function load(url:String, onLoad:Void->Void, onProgress:Void->Void, onError:Void->Void):Void {
        var scope:PCDLoader = this;
        var loader:FileLoader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(parse(data));
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

    private function parse(data:ArrayBuffer):Points {
        // from https://gitlab.com/taketwo/three-pcd-loader/blob/master/decompress-lzf.js

        function decompressLZF(inData:ArrayBuffer, outLength:Int):ArrayBuffer {
            var inLength:Int = inData.byteLength;
            var outData:ArrayBuffer = new ArrayBuffer(outLength);
            var inPtr:Int = 0;
            var outPtr:Int = 0;
            var ctrl:Int;
            var len:Int;
            var ref:Int;
            do {
                ctrl = inData[inPtr++];
                if (ctrl < (1 << 5)) {
                    ctrl++;
                    if (outPtr + ctrl > outLength) throw new Error('Output buffer is not large enough');
                    if (inPtr + ctrl > inLength) throw new Error('Invalid compressed data');
                    do {
                        outData[outPtr++] = inData[inPtr++];
                    } while (--ctrl > 0);
                } else {
                    len = ctrl >> 5;
                    ref = outPtr - ((ctrl & 0x1f) << 8) - 1;
                    if (inPtr >= inLength) throw new Error('Invalid compressed data');
                    if (len == 7) {
                        len += inData[inPtr++];
                        if (inPtr >= inLength) throw new Error('Invalid compressed data');
                    }
                    ref -= inData[inPtr++];
                    if (outPtr + len + 2 > outLength) throw new Error('Output buffer is not large enough');
                    if (ref < 0) throw new Error('Invalid compressed data');
                    if (ref >= outPtr) throw new Error('Invalid compressed data');
                    do {
                        outData[outPtr++] = outData[ref++];
                    } while (--len + 2 > 0);
                }
            } while (inPtr < inLength);
            return outData;
        }

        function parseHeader(data:String):PCDHeader {
            var PCDheader:PCDHeader = {};
            var result1:Int = data.indexOf('\nDATA');
            var result2:Array<String> = ~/[\r\n]DATA\s(\S*)\s/i.exec(data.slice(result1 - 1));
            PCDheader.data = result2[1];
            PCDheader.headerLen = result2[0].length + result1;
            PCDheader.str = data.slice(0, PCDheader.headerLen);
            // remove comments
            PCDheader.str = PCDheader.str.replace(/#.*/gi, '');
            // parse
            PCDheader.version = ~/VERSION (.*)/i.exec(PCDheader.str);
            PCDheader.fields = ~/FIELDS (.*)/i.exec(PCDheader.str);
            PCDheader.size = ~/SIZE (.*)/i.exec(PCDheader.str);
            PCDheader.type = ~/TYPE (.*)/i.exec(PCDheader.str);
            PCDheader.count = ~/COUNT (.*)/i.exec(PCDheader.str);
            PCDheader.width = ~/WIDTH (.*)/i.exec(PCDheader.str);
            PCDheader.height = ~/HEIGHT (.*)/i.exec(PCDheader.str);
            PCDheader.viewpoint = ~/VIEWPOINT (.*)/i.exec(PCDheader.str);
            PCDheader.points = ~/POINTS (.*)/i.exec(PCDheader.str);
            // evaluate
            if (PCDheader.version != null) PCDheader.version = Std.parseFloat(PCDheader.version[1]);
            PCDheader.fields = (PCDheader.fields != null) ? PCDheader.fields[1].split(' ') : [];
            if (PCDheader.type != null) PCDheader.type = PCDheader.type[1].split(' ');
            if (PCDheader.width != null) PCDheader.width = Std.parseInt(PCDheader.width[1]);
            if (PCDheader.height != null) PCDheader.height = Std.parseInt(PCDheader.height[1]);
            if (PCDheader.viewpoint != null) PCDheader.viewpoint = PCDheader.viewpoint[1];
            if (PCDheader.points != null) PCDheader.points = Std.parseInt(PCDheader.points[1], 10);
            if (PCDheader.points == null) PCDheader.points = PCDheader.width * PCDheader.height;
            if (PCDheader.size != null) PCDheader.size = PCDheader.size[1].split(' ').map(function(x:String) return Std.parseInt(x, 10));
            if (PCDheader.count != null) PCDheader.count = PCDheader.count[1].split(' ').map(function(x:String) return Std.parseInt(x, 10));
            else {
                PCDheader.count = [];
                for (i in 0...PCDheader.fields.length) PCDheader.count.push(1);
            }
            PCDheader.offset = {};
            var sizeSum:Int = 0;
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

        var textData:String = new TextDecoder().decode(data);
        // parse header (always ascii format)
        var PCDheader:PCDHeader = parseHeader(textData);
        // parse data

        var position:Array<Float> = [];
        var normal:Array<Float> = [];
        var color:Array<Float> = [];
        var intensity:Array<Float> = [];
        var label:Array<Int> = [];

        var c:Color = new Color();

        // ascii
        if (PCDheader.data == 'ascii') {
            var offset:Dynamic = PCDheader.offset;
            var pcdData:String = textData.slice(PCDheader.headerLen);
            var lines:Array<String> = pcdData.split('\n');

            for (i in 0...lines.length) {
                if (lines[i] == '') continue;
                var line:Array<String> = lines[i].split(' ');
                if (offset.x != null) {
                    position.push(Std.parseFloat(line[offset.x]));
                    position.push(Std.parseFloat(line[offset.y]));
                    position.push(Std.parseFloat(line[offset.z]));
                }
                if (offset.rgb != null) {
                    var rgb_field_index:Int = PCDheader.fields.indexOf('rgb');
                    var rgb_type:String = PCDheader.type[rgb_field_index];
                    var float:Float = Std.parseFloat(line[offset.rgb]);
                    var rgb:Int = float;
                    if (rgb_type == 'F') {
                        // treat float values as int
                        // https://github.com/daavoo/pyntcloud/pull/204/commits/7b4205e64d5ed09abe708b2e91b615690c24d518
                        var farr:ArrayBuffer = new ArrayBuffer(4);
                        farr.setInt32(0, Std.int(float));
                        rgb = farr.getInt32(0);
                    }
                    var r:Float = ((rgb >> 16) & 0x0000ff) / 255.0;
                    var g:Float = ((rgb >> 8) & 0x0000ff) / 255.0;
                    var b:Float = (rgb & 0x0000ff) / 255.0;
                    c.set(r, g, b).convertSRGBToLinear();
                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
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
                    label.push(Std.parseInt(line[offset.label], 10));
                }
            }
        }

        // binary-compressed
        if (PCDheader.data == 'binary_compressed') {
            var sizes:Uint32Array = new Uint32Array(data, PCDheader.headerLen, 8);
            var compressedSize:Int = sizes[0];
            var decompressedSize:Int = sizes[1];
            var decompressed:ArrayBuffer = decompressLZF(new Uint8Array(data, PCDheader.headerLen + 8, compressedSize), decompressedSize);
            var dataview:DataView = new DataView(decompressed.buffer);

            var offset:Dynamic = PCDheader.offset;

            for (i in 0...PCDheader.points) {
                if (offset.x != null) {
                    var xIndex:Int = PCDheader.fields.indexOf('x');
                    var yIndex:Int = PCDheader.fields.indexOf('y');
                    var zIndex:Int = PCDheader.fields.indexOf('z');
                    position.push(dataview.getFloat32(PCDheader.points * offset.x + PCDheader.size[xIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.y + PCDheader.size[yIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.z + PCDheader.size[zIndex] * i, littleEndian));
                }
                if (offset.rgb != null) {
                    var rgbIndex:Int = PCDheader.fields.indexOf('rgb');
                    var r:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 2) / 255.0;
                    var g:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 1) / 255.0;
                    var b:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 0) / 255.0;
                    c.set(r, g, b).convertSRGBToLinear();
                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
                }
                if (offset.normal_x != null) {
                    var xIndex:Int = PCDheader.fields.indexOf('normal_x');
                    var yIndex:Int = PCDheader.fields.indexOf('normal_y');
                    var zIndex:Int = PCDheader.fields.indexOf('normal_z');
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_x + PCDheader.size[xIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_y + PCDheader.size[yIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_z + PCDheader.size[zIndex] * i, littleEndian));
                }
                if (offset.intensity != null) {
                    var intensityIndex:Int = PCDheader.fields.indexOf('intensity');
                    intensity.push(dataview.getFloat32(PCDheader.points * offset.intensity + PCDheader.size[intensityIndex] * i, littleEndian));
                }
                if (offset.label != null) {
                    var labelIndex:Int = PCDheader.fields.indexOf('label');
                    label.push(dataview.getInt32(PCDheader.points * offset.label + PCDheader.size[labelIndex] * i, littleEndian));
                }
            }
        }

        // binary

        if (PCDheader.data == 'binary') {
            var dataview:DataView = new DataView(data, PCDheader.headerLen);
            var offset:Dynamic = PCDheader.offset;

            for (i in 0...PCDheader.points) {
                var row:Int = i * PCDheader.rowSize;
                if (offset.x != null) {
                    position.push(dataview.getFloat32(row + offset.x, littleEndian));
                    position.push(dataview.getFloat32(row + offset.y, littleEndian));
                    position.push(dataview.getFloat32(row + offset.z, littleEndian));
                }
                if (offset.rgb != null) {
                    var r:Float = dataview.getUint8(row + offset.rgb + 2) / 255.0;
                    var g:Float = dataview.getUint8(row + offset.rgb + 1) / 255.0;
                    var b:Float = dataview.getUint8(row + offset.rgb + 0) / 255.0;
                    c.set(r, g, b).convertSRGBToLinear();
                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
                }
                if (offset.normal_x != null) {
                    normal.push(dataview.getFloat32(row + offset.normal_x, littleEndian));
                    normal.push(dataview.getFloat32(row + offset.normal_y, littleEndian));
                    normal.push(dataview.getFloat32(row + offset.normal_z, littleEndian));
                }
                if (offset.intensity != null) {
                    intensity.push(dataview.getFloat32(row + offset.intensity, littleEndian));
                }
                if (offset.label != null) {
                    label.push(dataview.getInt32(row + offset.label, littleEndian));
                }
            }
        }

        // build geometry

        var geometry:BufferGeometry = new BufferGeometry();
        if (position.length > 0) geometry.setAttribute('position', new Float32BufferAttribute(position, 3));
        if (normal.length > 0) geometry.setAttribute('normal', new Float32BufferAttribute(normal, 3));
        if (color.length > 0) geometry.setAttribute('color', new Float32BufferAttribute(color, 3));
        if (intensity.length > 0) geometry.setAttribute('intensity', new Float32BufferAttribute(intensity, 1));
        if (label.length > 0) geometry.setAttribute('label', new Int32BufferAttribute(label, 1));
        geometry.computeBoundingSphere();

        // build material

        var material:PointsMaterial = new PointsMaterial({ size: 0.005 });
        if (color.length > 0) material.vertexColors = true;

        // build point cloud

        return new Points(geometry, material);
    }
}