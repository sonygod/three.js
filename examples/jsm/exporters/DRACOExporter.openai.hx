import haxe.io.Bytes;
import haxe.io.UInt8Array;

// Assume DracoEncoderModule is already imported and available

class DRACOExporter {
    public static inline var MESH_EDGEBREAKER_ENCODING = 1;
    public static inline var MESH_SEQUENTIAL_ENCODING = 0;

    public static inline var POINT_CLOUD = 0;
    public static inline var TRIANGULAR_MESH = 1;

    public static inline var INVALID = -1;
    public static inline var POSITION = 0;
    public static inline var NORMAL = 1;
    public static inline var COLOR = 2;
    public static inline var TEX_COORD = 3;
    public static inline var GENERIC = 4;

    public function parse(object: Dynamic, options: {decodeSpeed: Int, encodeSpeed: Int, encoderMethod: Int, quantization: Array<Int>, exportUvs: Bool, exportNormals: Bool, exportColor: Bool} = {}): Bytes {
        options = {decodeSpeed: 5, encodeSpeed: 5, encoderMethod: MESH_EDGEBREAKER_ENCODING, quantization: [16, 8, 8, 8, 8], exportUvs: true, exportNormals: true, exportColor: false};

        if (DracoEncoderModule == null) {
            throw new Error('THREE.DRACOExporter: required the draco_encoder to work.');
        }

        var geometry = object.geometry;

        var dracoEncoder = new DracoEncoderModule();
        var encoder = new dracoEncoder.Encoder();
        var builder;
        var dracoObject;

        if (object.isMesh) {
            builder = new dracoEncoder MeshBuilder();
            dracoObject = new dracoEncoder.Mesh();

            var vertices = geometry.getAttribute('position');
            builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            var faces = geometry.getIndex();

            if (faces != null) {
                builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
            } else {
                var faces = new (vertices.count > 65535 ? UInt32Array : UInt16Array)(vertices.count);

                for (i in 0...faces.length) {
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
            throw new Error('DRACOExporter: Unsupported object type.');
        }

        // Compress using draco encoder
        var encodedData = new dracoEncoder.DracoInt8Array();

        // Sets the desired encoding and decoding speed for the given options from 0 (slowest speed, but the best compression) to 10 (fastest, but the worst compression).
        var encodeSpeed = options.encodeSpeed != null ? options.encodeSpeed : 5;
        var decodeSpeed = options.decodeSpeed != null ? options.decodeSpeed : 5;

        encoder.SetSpeedOptions(encodeSpeed, decodeSpeed);

        // Sets the desired encoding method for a given geometry.
        if (options.encoderMethod != null) {
            encoder.SetEncodingMethod(options.encoderMethod);
        }

        // Sets the quantization (number of bits used to represent) compression options for a named attribute.
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

        // Copy encoded data to buffer.
        var outputData = Bytes.alloc(length);
        for (i in 0...length) {
            outputData.writeByte(i, encodedData.GetValue(i));
        }

        dracoEncoder.destroy(encodedData);
        dracoEncoder.destroy(encoder);
        dracoEncoder.destroy(builder);

        return outputData;
    }

    static function createVertexColorSRGBArray(attribute: Dynamic): Array<Float> {
        var color = new Color();

        var count = attribute.count;
        var itemSize = attribute.itemSize;
        var array = new Array<Float>();

        for (i in 0...count) {
            color.fromBufferAttribute(attribute, i).convertLinearToSRGB();

            array.push(color.r);
            array.push(color.g);
            array.push(color.b);

            if (itemSize == 4) {
                array.push(attribute.getW(i));
            }
        }

        return array;
    }
}