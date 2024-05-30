package three.js.loaders;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Compress;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Int32BufferAttribute;
import three.Loader;
import three.Points;
import three.PointsMaterial;

class PCDLoader extends Loader {

    public var littleEndian:Bool = true;

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Points->Void, onProgress:Int->Void, onError:Error->Void):Void {
        var scope:PCDLoader = this;
        var loader:FileLoader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data:Bytes) {
            try {
                onLoad(parse(data));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(data:Bytes):Points {
        // from https://gitlab.com/taketwo/three-pcd-loader/blob/master/decompress-lzf.js

        function decompressLZF(inData:Bytes, outLength:Int):Bytes {
            var outData:Bytes = Bytes.alloc(outLength);
            var inPtr:Int = 0;
            var outPtr:Int = 0;
            var ctrl:Int;
            var len:Int;
            var ref:Int;

            while (inPtr < inData.length) {
                ctrl = inData.get(inPtr++);
                if (ctrl < (1 << 5)) {
                    ctrl++;
                    if (outPtr + ctrl > outLength) throw new Error('Output buffer is not large enough');
                    if (inPtr + ctrl > inData.length) throw new Error('Invalid compressed data');
                    while (--ctrl > 0) {
                        outData.set(outPtr++, inData.get(inPtr++));
                    }
                } else {
                    len = ctrl >> 5;
                    ref = outPtr - ((ctrl & 0x1f) << 8) - 1;
                    if (inPtr >= inData.length) throw new Error('Invalid compressed data');
                    if (len == 7) {
                        len += inData.get(inPtr++);
                        if (inPtr >= inData.length) throw new Error('Invalid compressed data');
                    }
                    ref -= inData.get(inPtr++);
                    if (outPtr + len + 2 > outLength) throw new Error('Output buffer is not large enough');
                    if (ref < 0) throw new Error('Invalid compressed data');
                    if (ref >= outPtr) throw new Error('Invalid compressed data');
                    while (--len + 2 > 0) {
                        outData.set(outPtr++, outData.get(ref++));
                    }
                }
            }

            return outData;
        }

        function parseHeader(data:String):Dynamic {
            var PCDheader:Dynamic = {};
            var result1:Int = data.indexOf('\nDATA ');
            var result2:Array<String> = ~/[\r\n]DATA\s(\S*)\s/i.exec(data.slice(result1 - 1));
            PCDheader.data = result2[1];
            PCDheader.headerLen = result2[0].length + result1;
            PCDheader.str = data.slice(0, PCDheader.headerLen);

            // remove comments
            PCDheader.str = ~/#.*/gi.replace(PCDheader.str, '');

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
            } else {
                PCDheader.points = PCDheader.width * PCDheader.height;
            }
            if (PCDheader.size != null) {
                PCDheader.size = PCDheader.size[1].split(' ').map(function(x:String) {
                    return Std.parseInt(x, 10);
                });
            }
            if (PCDheader.count != null) {
                PCDheader.count = PCDheader.count[1].split(' ').map(function(x:String) {
                    return Std.parseInt(x, 10);
                });
            } else {
                PCDheader.count = [];
                for (i in 0...PCDheader.fields.length) {
                    PCDheader.count.push(1);
                }
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
        var PCDheader:Dynamic = parseHeader(textData);

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

                if (offset.x != undefined) {
                    position.push(Std.parseFloat(line[offset.x]));
                    position.push(Std.parseFloat(line[offset.y]));
                    position.push(Std.parseFloat(line[offset.z]));
                }

                if (offset.rgb != undefined) {
                    var rgb_field_index:Int = PCDheader.fields.indexOf('rgb');
                    var rgb_type:String = PCDheader.type[rgb_field_index];
                    var float:Float = Std.parseFloat(line[offset.rgb]);
                    var rgb:Int;

                    if (rgb_type == 'F') {
                        // treat float values as int
                        // https://github.com/daavoo/pyntcloud/pull/204/commits/7b4205e64d5ed09abe708b2e91b615690c24d518
                        var farr:Bytes = Bytes.alloc(4);
                        farr.setInt32(0, Std.int(float));
                        rgb = farr.getInt32(0);
                    } else {
                        rgb = Std.int(float);
                    }

                    var r:Float = (rgb >> 16) & 0x0000ff;
                    var g:Float = (rgb >> 8) & 0x0000ff;
                    var b:Float = rgb & 0x0000ff;

                    c.setRGB(r / 255.0, g / 255.0, b / 255.0).convertSRGBToLinear();

                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
                }

                if (offset.normal_x != undefined) {
                    normal.push(Std.parseFloat(line[offset.normal_x]));
                    normal.push(Std.parseFloat(line[offset.normal_y]));
                    normal.push(Std.parseFloat(line[offset.normal_z]));
                }

                if (offset.intensity != undefined) {
                    intensity.push(Std.parseFloat(line[offset.intensity]));
                }

                if (offset.label != undefined) {
                    label.push(Std.parseInt(line[offset.label]));
                }
            }
        }

        // binary-compressed
        // normally data in PCD files are organized as array of structures: XYZRGBXYZRGB
        // binary compressed PCD files organize their data as structure of arrays: XXYYZZRGBRGB
        // that requires a totally different parsing approach compared to non-compressed data

        if (PCDheader.data == 'binary_compressed') {
            var sizes:Bytes = data.slice(PCDheader.headerLen, PCDheader.headerLen + 8);
            var compressedSize:Int = sizes.getInt32(0);
            var decompressedSize:Int = sizes.getInt32(4);
            var decompressedData:Bytes = decompressLZF(data, decompressedSize);
            var dataview:BytesOutput = new BytesOutput();

            var offset:Dynamic = PCDheader.offset;

            for (i in 0...PCDheader.points) {
                if (offset.x != undefined) {
                    var xIndex:Int = PCDheader.fields.indexOf('x');
                    var yIndex:Int = PCDheader.fields.indexOf('y');
                    var zIndex:Int = PCDheader.fields.indexOf('z');
                    position.push(dataview.getFloat32(PCDheader.points * offset.x + PCDheader.size[xIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.y + PCDheader.size[yIndex] * i, littleEndian));
                    position.push(dataview.getFloat32(PCDheader.points * offset.z + PCDheader.size[zIndex] * i, littleEndian));
                }

                if (offset.rgb != undefined) {
                    var rgbIndex:Int = PCDheader.fields.indexOf('rgb');
                    var r:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 2) / 255.0;
                    var g:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 1) / 255.0;
                    var b:Float = dataview.getUint8(PCDheader.points * offset.rgb + PCDheader.size[rgbIndex] * i + 0) / 255.0;

                    c.setRGB(r, g, b).convertSRGBToLinear();

                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
                }

                if (offset.normal_x != undefined) {
                    var xIndex:Int = PCDheader.fields.indexOf('normal_x');
                    var yIndex:Int = PCDheader.fields.indexOf('normal_y');
                    var zIndex:Int = PCDheader.fields.indexOf('normal_z');
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_x + PCDheader.size[xIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_y + PCDheader.size[yIndex] * i, littleEndian));
                    normal.push(dataview.getFloat32(PCDheader.points * offset.normal_z + PCDheader.size[zIndex] * i, littleEndian));
                }

                if (offset.intensity != undefined) {
                    var intensityIndex:Int = PCDheader.fields.indexOf('intensity');
                    intensity.push(dataview.getFloat32(PCDheader.points * offset.intensity + PCDheader.size[intensityIndex] * i, littleEndian));
                }

                if (offset.label != undefined) {
                    var labelIndex:Int = PCDheader.fields.indexOf('label');
                    label.push(dataview.getInt32(PCDheader.points * offset.label + PCDheader.size[labelIndex] * i, littleEndian));
                }
            }
        }

        // binary

        if (PCDheader.data == 'binary') {
            var dataview:BytesOutput = new BytesOutput();
            var offset:Dynamic = PCDheader.offset;

            for (i in 0...PCDheader.points) {
                if (offset.x != undefined) {
                    position.push(dataview.getFloat32(i * PCDheader.rowSize + offset.x, littleEndian));
                    position.push(dataview.getFloat32(i * PCDheader.rowSize + offset.y, littleEndian));
                    position.push(dataview.getFloat32(i * PCDheader.rowSize + offset.z, littleEndian));
                }

                if (offset.rgb != undefined) {
                    var r:Float = dataview.getUint8(i * PCDheader.rowSize + offset.rgb + 2) / 255.0;
                    var g:Float = dataview.getUint8(i * PCDheader.rowSize + offset.rgb + 1) / 255.0;
                    var b:Float = dataview.getUint8(i * PCDheader.rowSize + offset.rgb + 0) / 255.0;

                    c.setRGB(r, g, b).convertSRGBToLinear();

                    color.push(c.r);
                    color.push(c.g);
                    color.push(c.b);
                }

                if (offset.normal_x != undefined) {
                    normal.push(dataview.getFloat32(i * PCDheader.rowSize + offset.normal_x, littleEndian));
                    normal.push(dataview.getFloat32(i * PCDheader.rowSize + offset.normal_y, littleEndian));
                    normal.push(dataview.getFloat32(i * PCDheader.rowSize + offset.normal_z, littleEndian));
                }

                if (offset.intensity != undefined) {
                    intensity.push(dataview.getFloat32(i * PCDheader.rowSize + offset.intensity, littleEndian));
                }

                if (offset.label != undefined) {
                    label.push(dataview.getInt32(i * PCDheader.rowSize + offset.label, littleEndian));
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

        if (color.length > 0) {
            material.vertexColors = true;
        }

        // build point cloud

        return new Points(geometry, material);
    }
}