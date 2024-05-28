import js.three.Color;

/**
 * Export draco compressed files from threejs geometry objects.
 *
 * Draco files are compressed and usually are smaller than conventional 3D file formats.
 *
 * The exporter receives a options object containing
 *  - decodeSpeed, indicates how to tune the encoder regarding decode speed (0 gives better speed but worst quality)
 *  - encodeSpeed, indicates how to tune the encoder parameters (0 gives better speed but worst quality)
 *  - encoderMethod
 *  - quantization, indicates the precision of each type of data stored in the draco file in the order (POSITION, NORMAL, COLOR, TEX_COORD, GENERIC)
 *  - exportUvs
 *  - exportNormals
 *  - exportColor
 */

class DRACOExporter {
    public static inline var DRACOEncoder:Dynamic;

    public function parse(object:Dynamic, ?options:Map<String, Dynamic>):Int8Array {
        options = options ?? {
            'decodeSpeed' => 5,
            'encodeSpeed' => 5,
            'encoderMethod' => DRACOExporter.MESH_EDGEBREAKER_ENCODING,
            'quantization' => [16, 8, 8, 8, 8],
            'exportUvs' => true,
            'exportNormals' => true,
            'exportColor' => false
        };

        if (DRACOEncoder == null) {
            throw 'THREE.DRACOExporter: required the draco_encoder to work.';
        }

        var geometry:Dynamic = object.geometry;
        var dracoEncoder:Dynamic = DRACOEncoder();
        var encoder:Dynamic = dracoEncoder.Encoder();
        var builder:Dynamic;
        var dracoObject:Dynamic;

        if (object.isMesh) {
            builder = dracoEncoder.MeshBuilder();
            dracoObject = dracoEncoder.Mesh();

            var vertices:Dynamic = geometry.getAttribute('position');
            builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            var faces:Dynamic = geometry.getIndex();

            if (faces != null) {
                builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
            } else {
                var facesArray:Array<Int> = [];
                for (i in 0...vertices.count) {
                    facesArray.push(i);
                }
                faces = facesArray;
                builder.AddFacesToMesh(dracoObject, vertices.count, faces);
            }

            if (options.exportNormals) {
                var normals:Dynamic = geometry.getAttribute('normal');
                if (normals != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.NORMAL, normals.count, normals.itemSize, normals.array);
                }
            }

            if (options.exportUvs) {
                var uvs:Dynamic = geometry.getAttribute('uv');
                if (uvs != null) {
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.TEX_COORD, uvs.count, uvs.itemSize, uvs.array);
                }
            }

            if (options.exportColor) {
                var colors:Dynamic = geometry.getAttribute('color');
                if (colors != null) {
                    var array:Float32Array = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }

        } else if (object.isPoints) {
            builder = dracoEncoder.PointCloudBuilder();
            dracoObject = dracoEncoder.PointCloud();

            var vertices:Dynamic = geometry.getAttribute('position');
            builder.AddFloatAttribute(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

            if (options.exportColor) {
                var colors:Dynamic = geometry.getAttribute('color');
                if (colors != null) {
                    var array:Float32Array = createVertexColorSRGBArray(colors);
                    builder.AddFloatAttribute(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);
                }
            }

        } else {
            throw 'DRACOExporter: Unsupported object type.';
        }

        // Compress using draco encoder

        var encodedData:Dynamic = dracoEncoder.DracoInt8Array();

        // Sets the desired encoding and decoding speed for the given options from 0 (slowest speed, but the best compression) to 10 (fastest, but the worst compression).

        var encodeSpeed:Int = options.encodeSpeed ?? 5;
        var decodeSpeed:Int = options.decodeSpeed ?? 5;

        encoder.SetSpeedOptions(encodeSpeed, decodeSpeed);

        // Sets the desired encoding method for a given geometry.

        if (options.encoderMethod != null) {
            encoder.SetEncodingMethod(options.encoderMethod);
        }

        // Sets the quantization (number of bits used to represent) compression options for a named attribute.
        // The attribute values will be quantized in a box defined by the maximum extent of the attribute values.
        if (options.quantization != null) {
            for (i in 0...5) {
                if (options.quantization[i] != null) {
                    encoder.SetAttributeQuantization(i, options.quantization[i]);
                }
            }
        }

        var length:Int;

        if (object.isMesh) {
            length = encoder.EncodeMeshToDracoBuffer(dracoObject, encodedData);
        } else {
            length = encoder.EncodePointCloudToDracoBuffer(dracoObject, true, encodedData);
        }

        dracoEncoder.destroy(dracoObject);

        if (length == 0) {
            throw 'THREE.DRACOExporter: Draco encoding failed.';
        }

        // Copy encoded data to buffer.
        var outputData:Int8Array = new Int8Array(length);

        for (i in 0...length) {
            outputData[i] = encodedData.GetValue(i);
        }

        dracoEncoder.destroy(encodedData);
        dracoEncoder.destroy(encoder);
        dracoEncoder.destroy(builder);

        return outputData;
    }

    static function createVertexColorSRGBArray(attribute:Dynamic):Float32Array {
        // While .drc files do not specify colorspace, the only 'official' tooling
        // is PLY and OBJ converters, which use sRGB. We'll assume sRGB is expected
        // for .drc files, but note that Draco buffers embedded in glTF files will
        // be Linear-sRGB instead.

        var _color:Color = new Color();

        var count:Int = attribute.count;
        var itemSize:Int = attribute.itemSize;
        var array:Float32Array = new Float32Array(count * itemSize);

        for (i in 0...count) {
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
}