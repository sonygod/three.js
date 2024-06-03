import three.Color;

class DRACOExporterOptions {
    public var decodeSpeed: Int = 5;
    public var encodeSpeed: Int = 5;
    public var encoderMethod: Int = DRACOExporter.MESH_EDGEBREAKER_ENCODING;
    public var quantization: Array<Int> = [ 16, 8, 8, 8, 8 ];
    public var exportUvs: Bool = true;
    public var exportNormals: Bool = true;
    public var exportColor: Bool = false;
}

class DRACOExporter {
    public static var MESH_EDGEBREAKER_ENCODING: Int = 1;
    public static var MESH_SEQUENTIAL_ENCODING: Int = 0;
    public static var POINT_CLOUD: Int = 0;
    public static var TRIANGULAR_MESH: Int = 1;
    public static var INVALID: Int = -1;
    public static var POSITION: Int = 0;
    public static var NORMAL: Int = 1;
    public static var COLOR: Int = 2;
    public static var TEX_COORD: Int = 3;
    public static var GENERIC: Int = 4;

    public function new() {}

    public function parse(object: Dynamic, options: DRACOExporterOptions = null): Int8Array {
        if (options == null) {
            options = new DRACOExporterOptions();
        }

        if (!Reflect.hasField(js.global, "DracoEncoderModule")) {
            throw new Error("THREE.DRACOExporter: required the draco_encoder to work.");
        }

        var geometry = object.geometry;
        var dracoEncoder = js.global.DracoEncoderModule();
        var encoder = new dracoEncoder.Encoder();
        var builder: Dynamic;
        var dracoObject: Dynamic;

        if (object.isMesh == true) {
            builder = new dracoEncoder.MeshBuilder();
            dracoObject = new dracoEncoder.Mesh();

            var vertices = geometry.getAttribute("position");
            builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            var faces = geometry.getIndex();

            if (faces != null) {
                builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
            } else {
                var faces = new (vertices.count > 65535 ? haxe.Int32Array : haxe.Int16Array)(vertices.count);

                for (var i = 0; i < faces.length; i++) {
                    faces[i] = i;
                }

                builder.AddFacesToMesh(dracoObject, vertices.count, faces);
            }

            if (options.exportNormals == true) {
                var normals = geometry.getAttribute("normal");

                if (normals != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.NORMAL, normals.count, normals.itemSize, normals.array);
                }
            }

            if (options.exportUvs == true) {
                var uvs = geometry.getAttribute("uv");

                if (uvs != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.TEX_COORD, uvs.count, uvs.itemSize, uvs.array);
                }
            }

            if (options.exportColor == true) {
                var colors = geometry.getAttribute("color");

                if (colors != null) {
                    var array = createVertexColorSRGBArray(colors);

                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }
        } else if (object.isPoints == true) {
            builder = new dracoEncoder.PointCloudBuilder();
            dracoObject = new dracoEncoder.PointCloud();

            var vertices = geometry.getAttribute("position");
            builder.AddFloatAttribute(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            if (options.exportColor == true) {
                var colors = geometry.getAttribute("color");

                if (colors != null) {
                    var array = createVertexColorSRGBArray(colors);

                    builder.AddFloatAttribute(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }
        } else {
            throw new Error("DRACOExporter: Unsupported object type.");
        }

        var encodedData = new dracoEncoder.DracoInt8Array();

        var encodeSpeed = (options.encodeSpeed != null) ? options.encodeSpeed : 5;
        var decodeSpeed = (options.decodeSpeed != null) ? options.decodeSpeed : 5;

        encoder.SetSpeedOptions(encodeSpeed, decodeSpeed);

        if (options.encoderMethod != null) {
            encoder.SetEncodingMethod(options.encoderMethod);
        }

        if (options.quantization != null) {
            for (var i = 0; i < 5; i++) {
                if (options.quantization[i] != null) {
                    encoder.SetAttributeQuantization(i, options.quantization[i]);
                }
            }
        }

        var length: Int;

        if (object.isMesh == true) {
            length = encoder.EncodeMeshToDracoBuffer(dracoObject, encodedData);
        } else {
            length = encoder.EncodePointCloudToDracoBuffer(dracoObject, true, encodedData);
        }

        dracoEncoder.destroy(dracoObject);

        if (length == 0) {
            throw new Error("THREE.DRACOExporter: Draco encoding failed.");
        }

        var outputData = new Int8Array(length);

        for (var i = 0; i < length; i++) {
            outputData[i] = encodedData.GetValue(i);
        }

        dracoEncoder.destroy(encodedData);
        dracoEncoder.destroy(encoder);
        dracoEncoder.destroy(builder);

        return outputData;
    }
}

function createVertexColorSRGBArray(attribute: Dynamic): Float32Array {
    var _color = new Color();

    var count = attribute.count;
    var itemSize = attribute.itemSize;
    var array = new Float32Array(count * itemSize);

    for (var i = 0, il = count; i < il; i++) {
        _color.fromBufferAttribute(attribute, i).convertLinearToSRGB();

        array[i * itemSize] = _color.r;
        array[i * itemSize + 1] = _color.g;
        array[i * itemSize + 2] = _color.b;

        if (itemSize == 4) {
            array[i * itemSize + 3] = attribute.getW(i);
        }
    }

    return array;
}