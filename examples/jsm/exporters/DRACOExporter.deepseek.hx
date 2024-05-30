import three.Color;

class DRACOExporter {

    static var MESH_EDGEBREAKER_ENCODING:Int = 1;
    static var MESH_SEQUENTIAL_ENCODING:Int = 0;
    static var POINT_CLOUD:Int = 0;
    static var TRIANGULAR_MESH:Int = 1;
    static var INVALID:Int = -1;
    static var POSITION:Int = 0;
    static var NORMAL:Int = 1;
    static var COLOR:Int = 2;
    static var TEX_COORD:Int = 3;
    static var GENERIC:Int = 4;

    public function new() {}

    public function parse(object:Dynamic, options:Dynamic = null):Int8Array {

        if (options == null) {
            options = {
                decodeSpeed: 5,
                encodeSpeed: 5,
                encoderMethod: DRACOExporter.MESH_EDGEBREAKER_ENCODING,
                quantization: [16, 8, 8, 8, 8],
                exportUvs: true,
                exportNormals: true,
                exportColor: false
            };
        }

        if (DracoEncoderModule == null) {
            throw 'THREE.DRACOExporter: required the draco_encoder to work.';
        }

        var geometry = object.geometry;

        var dracoEncoder = DracoEncoderModule();
        var encoder = new dracoEncoder.Encoder();
        var builder;
        var dracoObject;

        if (object.isMesh) {

            builder = new dracoEncoder.MeshBuilder();
            dracoObject = new dracoEncoder.Mesh();

            var vertices = geometry.getAttribute('position');
            builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            var faces = geometry.getIndex();

            if (faces != null) {
                builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
            } else {
                var faces = new (vertices.count > 65535 ? Uint32Array : Uint16Array)(vertices.count);
                for (i in faces) {
                    faces[i] = i;
                }
                builder.AddFacesToMesh(dracoObject, vertices.count, faces);
            }

            if (options.exportNormals) {
                var normals = geometry.getAttribute('normal');
                if (normals != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.NORMAL, normals.count, normals.itemSize, normals.array);
                }
            }

            if (options.exportUvs) {
                var uvs = geometry.getAttribute('uv');
                if (uvs != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.TEX_COORD, uvs.count, uvs.itemSize, uvs.array);
                }
            }

            if (options.exportColor) {
                var colors = geometry.getAttribute('color');
                if (colors != null) {
                    var array = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }

        } else if (object.isPoints) {

            builder = new dracoEncoder.PointCloudBuilder();
            dracoObject = new dracoEncoder.PointCloud();

            var vertices = geometry.getAttribute('position');
            builder.AddFloatAttribute(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            if (options.exportColor) {
                var colors = geometry.getAttribute('color');
                if (colors != null) {
                    var array = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttribute(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }

        } else {
            throw 'DRACOExporter: Unsupported object type.';
        }

        var encodedData = new dracoEncoder.DracoInt8Array();

        encoder.SetSpeedOptions(options.encodeSpeed, options.decodeSpeed);

        if (options.encoderMethod != null) {
            encoder.SetEncodingMethod(options.encoderMethod);
        }

        if (options.quantization != null) {
            for (i in options.quantization) {
                encoder.SetAttributeQuantization(i, options.quantization[i]);
            }
        }

        var length;

        if (object.isMesh) {
            length = encoder.EncodeMeshToDracoBuffer(dracoObject, encodedData);
        } else {
            length = encoder.EncodePointCloudToDracoBuffer(dracoObject, true, encodedData);
        }

        dracoEncoder.destroy(dracoObject);

        if (length == 0) {
            throw 'THREE.DRACOExporter: Draco encoding failed.';
        }

        var outputData = new Int8Array(new ArrayBuffer(length));

        for (i in outputData) {
            outputData[i] = encodedData.GetValue(i);
        }

        dracoEncoder.destroy(encodedData);
        dracoEncoder.destroy(encoder);
        dracoEncoder.destroy(builder);

        return outputData;
    }

    static function createVertexColorSRGBArray(attribute:Dynamic):Float32Array {

        var _color = new Color();

        var count = attribute.count;
        var itemSize = attribute.itemSize;
        var array = new Float32Array(count * itemSize);

        for (i in count) {
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
}