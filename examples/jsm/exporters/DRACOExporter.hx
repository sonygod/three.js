package three.js.examples.jsm.exporters;

import haxe.io.Int8Array;
import haxe.io.Bytes;

class DRACOExporter {

    public static inline var MESH_EDGEBREAKER_ENCODING:Int = 1;
    public static inline var MESH_SEQUENTIAL_ENCODING:Int = 0;

    public static inline var POINT_CLOUD:Int = 0;
    public static inline var TRIANGULAR_MESH:Int = 1;

    public static inline var INVALID:Int = -1;
    public static inline var POSITION:Int = 0;
    public static inline var NORMAL:Int = 1;
    public static inline var COLOR:Int = 2;
    public static inline var TEX_COORD:Int = 3;
    public static inline var GENERIC:Int = 4;

    public function new() { }

    public function parse(object:Dynamic, ?options:Dynamic) {
        options = {
            decodeSpeed: 5,
            encodeSpeed: 5,
            encoderMethod: MESH_EDGEBREAKER_ENCODING,
            quantization: [16, 8, 8, 8, 8],
            exportUvs: true,
            exportNormals: true,
            exportColor: false,
        };

        if (options != null) {
            for (field in Reflect.fields(options)) {
                Reflect.setField(options, field, Reflect.field(options, field));
            }
        }

        if (DracoEncoderModule == null) {
            throw new Error('THREE.DRACOExporter: required the draco_encoder to work.');
        }

        var geometry = object.geometry;

        var dracoEncoder = new DracoEncoderModule();
        var encoder = new dracoEncoder.Encoder();
        var builder:Dynamic;
        var dracoObject:Dynamic;

        if (object.isMesh) {
            builder = new dracoEncoder.MeshBuilder();
            dracoObject = new dracoEncoder.Mesh();

            var vertices = geometry.getAttribute('position');
            builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            var faces = geometry.getIndex();

            if (faces != null) {
                builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
            } else {
                var faceCount = vertices.count;
                faces = new Int32Array(faceCount);

                for (i in 0...faceCount) {
                    faces[i] = i;
                }

                builder.AddFacesToMesh(dracoObject, faceCount, faces);
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
                    var colorArray = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, colorArray);
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
                    var colorArray = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttribute(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, colorArray);
                }
            }
        } else {
            throw new Error('DRACOExporter: Unsupported object type.');
        }

        var encodedData = new dracoEncoder.DracoInt8Array();

        var encodeSpeed = (options.encodeSpeed != null) ? options.encodeSpeed : 5;
        var decodeSpeed = (options.decodeSpeed != null) ? options.decodeSpeed : 5;

        encoder.SetSpeedOptions(encodeSpeed, decodeSpeed);

        if (options.encoderMethod != null) {
            encoder.SetEncodingMethod(options.encoderMethod);
        }

        if (options.quantization != null) {
            for (i in 0...5) {
                if (options.quantization[i] != null) {
                    encoder.SetAttributeQuantization(i, options.quantization[i]);
                }
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
            throw new Error('THREE.DRACOExporter: Draco encoding failed.');
        }

        var outputData = new Int8Array(new Bytes(length));

        for (i in 0...length) {
            outputData[i] = encodedData.GetValue(i);
        }

        dracoEncoder.destroy(encodedData);
        dracoEncoder.destroy(encoder);
        dracoEncoder.destroy(builder);

        return outputData;
    }

    static function createVertexColorSRGBArray(attribute:Dynamic) {
        var color = new Color();

        var count = attribute.count;
        var itemSize = attribute.itemSize;
        var array = new Float32Array(count * itemSize);

        for (i in 0...count) {
            color.fromBufferAttribute(attribute, i).convertLinearToSRGB();

            array[i * itemSize] = color.r;
            array[i * itemSize + 1] = color.g;
            array[i * itemSize + 2] = color.b;

            if (itemSize == 4) {
                array[i * itemSize + 3] = attribute.getW(i);
            }
        }

        return array;
    }
}