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

    public function new(manager:any = null) {
        super(manager);
    }

    public function load(url:String, onLoad:(points:Points) -> Void, onProgress:(event:ProgressEvent) -> Void, onError:(event:ErrorEvent) -> Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, (data) -> {
            try {
                onLoad(this.parse(data));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:ArrayBuffer):Points {
        function decompressLZF(inData:Uint8Array, outLength:Int):Uint8Array {
            var inLength = inData.length;
            var outData = new Uint8Array(outLength);
            var inPtr = 0;
            var outPtr = 0;
            var ctrl:Int = 0;
            var len:Int = 0;
            var ref:Int = 0;
            while (true) {
                ctrl = inData[inPtr++];
                if (ctrl < (1 << 5)) {
                    ctrl++;
                    if (outPtr + ctrl > outLength) throw 'Output buffer is not large enough';
                    if (inPtr + ctrl > inLength) throw 'Invalid compressed data';
                    while (--ctrl > 0) {
                        outData[outPtr++] = inData[inPtr++];
                    }
                } else {
                    len = ctrl >> 5;
                    ref = outPtr - ((ctrl & 0x1f) << 8) - 1;
                    if (inPtr >= inLength) throw 'Invalid compressed data';
                    if (len == 7) {
                        len += inData[inPtr++];
                        if (inPtr >= inLength) throw 'Invalid compressed data';
                    }
                    ref -= inData[inPtr++];
                    if (outPtr + len + 2 > outLength) throw 'Output buffer is not large enough';
                    if (ref < 0) throw 'Invalid compressed data';
                    if (ref >= outPtr) throw 'Invalid compressed data';
                    while (--len + 2 > 0) {
                        outData[outPtr++] = outData[ref++];
                    }
                }
                if (inPtr >= inLength) break;
            }
            return outData;
        }

        function parseHeader(data:String):Dynamic {
            var PCDheader = { };
            var result1 = data.search(new EReg("[\r\n]DATA\\s(\\S*)\\s", "i"));
            var result2 = new EReg("[\r\n]DATA\\s(\\S*)\\s", "i").exec(data.slice(result1 - 1));

            PCDheader.data = result2[1];
            PCDheader.headerLen = result2[0].length + result1;
            PCDheader.str = data.slice(0, PCDheader.headerLen);

            PCDheader.str = PCDheader.str.replace(new EReg("#.*", "gi"), '');

            var versionMatch = new EReg("VERSION (.*)", "i").exec(PCDheader.str);
            var fieldsMatch = new EReg("FIELDS (.*)", "i").exec(PCDheader.str);
            var sizeMatch = new EReg("SIZE (.*)", "i").exec(PCDheader.str);
            var typeMatch = new EReg("TYPE (.*)", "i").exec(PCDheader.str);
            var countMatch = new EReg("COUNT (.*)", "i").exec(PCDheader.str);
            var widthMatch = new EReg("WIDTH (.*)", "i").exec(PCDheader.str);
            var heightMatch = new EReg("HEIGHT (.*)", "i").exec(PCDheader.str);
            var viewpointMatch = new EReg("VIEWPOINT (.*)", "i").exec(PCDheader.str);
            var pointsMatch = new EReg("POINTS (.*)", "i").exec(PCDheader.str);

            if (versionMatch != null)
                PCDheader.version = Std.parseFloat(versionMatch[1]);

            PCDheader.fields = (fieldsMatch != null) ? fieldsMatch[1].split(' ') : [];

            if (typeMatch != null)
                PCDheader.type = typeMatch[1].split(' ');

            if (widthMatch != null)
                PCDheader.width = Std.parseInt(widthMatch[1]);

            if (heightMatch != null)
                PCDheader.height = Std.parseInt(heightMatch[1]);

            if (viewpointMatch != null)
                PCDheader.viewpoint = viewpointMatch[1];

            if (pointsMatch != null)
                PCDheader.points = Std.parseInt(pointsMatch[1], 10);

            if (PCDheader.points == null)
                PCDheader.points = PCDheader.width * PCDheader.height;

            if (sizeMatch != null) {
                PCDheader.size = sizeMatch[1].split(' ').map(function(x) {
                    return Std.parseInt(x, 10);
                });
            }

            if (countMatch != null) {
                PCDheader.count = countMatch[1].split(' ').map(function(x) {
                    return Std.parseInt(x, 10);
                });
            } else {
                PCDheader.count = [];
                for (var i in 0...PCDheader.fields.length) {
                    PCDheader.count.push(1);
                }
            }

            PCDheader.offset = { };

            var sizeSum = 0;

            for (var i in 0...PCDheader.fields.length) {
                if (PCDheader.data == 'ascii') {
                    PCDheader.offset[PCDheader.fields[i]] = i;
                } else {
                    PCDheader.offset[PCDheader.fields[i]] = sizeSum;
                    sizeSum += PCDheader.size[i] * PCDheader.count[i];
                }
            }

            PCDheader.rowSize = sizeSum;

            return PCDheader;
        }

        var textData = new TextDecoder().decode(data);

        var PCDheader = parseHeader(textData);

        var position:Array<Float> = [];
        var normal:Array<Float> = [];
        var color:Array<Float> = [];
        var intensity:Array<Float> = [];
        var label:Array<Int> = [];

        var c = new Color();

        if (PCDheader.data == 'ascii') {
            var offset = PCDheader.offset;
            var pcdData = textData.slice(PCDheader.headerLen);
            var lines = pcdData.split('\n');

            for (var i in 0...lines.length) {
                if (lines[i] == '') continue;

                var line = lines[i].split(' ');

                if (offset.hasKey('x')) {
                    position.push(Std.parseFloat(line[offset['x']]));
                    position.push(Std.parseFloat(line[offset['y']]));
                    position.push(Std.parseFloat(line[offset['z']]));
                }

                if (offset.hasKey('rgb')) {
                    var rgb_field_index = PCDheader.fields.indexOf('rgb');
                    var rgb_type = PCDheader.type[rgb_field_index];

                    var float = Std.parseFloat(line[offset['rgb']]);
                    var rgb = float;

                    if (rgb_type == 'F') {
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

                if (offset.hasKey('normal_x')) {
                    normal.push(Std.parseFloat(line[offset['normal_x']]));
                    normal.push(Std.parseFloat(line[offset['normal_y']]));
                    normal.push(Std.parseFloat(line[offset['normal_z']]));
                }

                if (offset.hasKey('intensity')) {
                    intensity.push(Std.parseFloat(line[offset['intensity']]));
                }

                if (offset.hasKey('label')) {
                    label.push(Std.parseInt(line[offset['label']]));
                }
            }
        }

        if (PCDheader.data == 'binary_compressed') {
            var sizes = new Uint32Array(data.slice(PCDheader.headerLen, PCDheader.headerLen + 8));
            var compressedSize = sizes[0];
            var decompressedSize = sizes[1];
            var decompressed = decompressLZF(new Uint8Array(data, PCDheader.headerLen + 8, compressedSize), decompressedSize);
            var dataview = new DataView(decompressed.buffer);

            var offset = PCDheader.offset;

            for (var i in 0...PCDheader.points) {
                if (offset.hasKey('x')) {
                    var xIndex = PCDheader.fields.indexOf('x');
                    var yIndex = PCDheader.fields.indexOf('y');
                    var zIndex = PCDheader.fields.indexOf('z');
                    position.push(dataview.getFloat32((PCDheader.points * offset['x']) + PCDheader.size[xIndex] * i, this.littleEndian));
                    position.push(dataview.getFloat32((PCDheader.points * offset['y']) + PCDheader.size[yIndex] * i, this.littleEndian));
                    position.push(dataview.getFloat32((PCDheader.points * offset['z']) + PCDheader.size[zIndex] * i, this.littleEndian));
                }

                if (offset.hasKey('rgb')) {
                    var rgbIndex = PCDheader.fields.indexOf('rgb');

                    var r = dataview.getUint8((PCDheader.points * offset['rgb']) + PCDheader.size[rgbIndex] * i + 2) / 255.0;
                    var g = dataview.getUint8((PCDheader.points * offset['rgb']) + PCDheader.size[rgbIndex] * i + 1) / 255.0;
                    var b = dataview.getUint8((PCDheader.points * offset['rgb']) + PCDheader.size[rgbIndex] * i + 0) / 255.0;

                    c.set(r, g, b).convertSRGBToLinear();

                    color.push(c.r, c.g, c.b);
                }

                if (offset.hasKey('normal_x')) {
                    var xIndex = PCDheader.fields.indexOf('normal_x');
                    var yIndex = PCDheader.fields.indexOf('normal_y');
                    var zIndex = PCDheader.fields.indexOf('normal_z');
                    normal.push(dataview.getFloat32((PCDheader.points * offset['normal_x']) + PCDheader.size[xIndex] * i, this.littleEndian));
                    normal.push(dataview.getFloat32((PCDheader.points * offset['normal_y']) + PCDheader.size[yIndex] * i, this.littleEndian));
                    normal.push(dataview.getFloat32((PCDheader.points * offset['normal_z']) + PCDheader.size[zIndex] * i, this.littleEndian));
                }

                if (offset.hasKey('intensity')) {
                    var intensityIndex = PCDheader.fields.indexOf('intensity');
                    intensity.push(dataview.getFloat32((PCDheader.points * offset['intensity']) + PCDheader.size[intensityIndex] * i, this.littleEndian));
                }

                if (offset.hasKey('label')) {
                    var labelIndex = PCDheader.fields.indexOf('label');
                    label.push(dataview.getInt32((PCDheader.points * offset['label']) + PCDheader.size[labelIndex] * i, this.littleEndian));
                }
            }
        }

        if (PCDheader.data == 'binary') {
            var dataview = new DataView(data, PCDheader.headerLen);
            var offset = PCDheader.offset;

            for (var i in 0...PCDheader.points) {
                var row = i * PCDheader.rowSize;
                if (offset.hasKey('x')) {
                    position.push(dataview.getFloat32(row + offset['x'], this.littleEndian));
                    position.push(dataview.getFloat32(row + offset['y'], this.littleEndian));
                    position.push(dataview.getFloat32(row + offset['z'], this.littleEndian));
                }

                if (offset.hasKey('rgb')) {
                    var r = dataview.getUint8(row + offset['rgb'] + 2) / 255.0;
                    var g = dataview.getUint8(row + offset['rgb'] + 1) / 255.0;
                    var b = dataview.getUint8(row + offset['rgb'] + 0) / 255.0;

                    c.set(r, g, b).convertSRGBToLinear();

                    color.push(c.r, c.g, c.b);
                }

                if (offset.hasKey('normal_x')) {
                    normal.push(dataview.getFloat32(row + offset['normal_x'], this.littleEndian));
                    normal.push(dataview.getFloat32(row + offset['normal_y'], this.littleEndian));
                    normal.push(dataview.getFloat32(row + offset['normal_z'], this.littleEndian));
                }

                if (offset.hasKey('intensity')) {
                    intensity.push(dataview.getFloat32(row + offset['intensity'], this.littleEndian));
                }

                if (offset.hasKey('label')) {
                    label.push(dataview.getInt32(row + offset['label'], this.littleEndian));
                }
            }
        }

        var geometry = new BufferGeometry();

        if (position.length > 0) geometry.setAttribute('position', new Float32BufferAttribute(position, 3));
        if (normal.length > 0) geometry.setAttribute('normal', new Float32BufferAttribute(normal, 3));
        if (color.length > 0) geometry.setAttribute('color', new Float32BufferAttribute(color, 3));
        if (intensity.length > 0) geometry.setAttribute('intensity', new Float32BufferAttribute(intensity, 1));
        if (label.length > 0) geometry.setAttribute('label', new Int32BufferAttribute(label, 1));

        geometry.computeBoundingSphere();

        var material = new PointsMaterial({ size: 0.005 });

        if (color.length > 0) {
            material.vertexColors = true;
        }

        return new Points(geometry, material);
    }
}