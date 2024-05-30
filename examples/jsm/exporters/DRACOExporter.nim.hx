import Color.{fromBufferAttribute, convertLinearToSRGB};

/**
 * Export draco compressed files from threejs geometry objects.
 *
 * Draco files are compressed and usually are smaller than conventional 3D file formats.
 *
 * The exporter receives a options object containing
 *  - decodeSpeed, indicates how to tune the encoder regarding decode speed (0 gives better speed but worst quality)
 *  - encodeSpeed, indicates how to tune the encoder parameters (0 gives better speed but worst quality)
 *  - encoderMethod
 *  - quantization, indicates the presision of each type of data stored in the draco file in the order (POSITION, NORMAL, COLOR, TEX_COORD, GENERIC)
 *  - exportUvs
 *  - exportNormals
 *  - exportColor
 */

// @:include('three.js/examples/jsm/exporters/DRACOExporter.js')

class DRACOExporter {

	public function parse(object: Dynamic, options: Dynamic): Int8Array {

		options = {
			decodeSpeed: 5,
			encodeSpeed: 5,
			encoderMethod: DRACOExporter.MESH_EDGEBREAKER_ENCODING,
			quantization: [16, 8, 8, 8, 8],
			exportUvs: true,
			exportNormals: true,
			exportColor: false,
		} :< options;

		if (DracoEncoderModule === undefined) {

			throw new Error('THREE.DRACOExporter: required the draco_encoder to work.');

		}

		var geometry = object.geometry;

		var dracoEncoder = DracoEncoderModule();
		var encoder = new dracoEncoder.Encoder();
		var builder;
		var dracoObject;

		if (object.isMesh === true) {

			builder = new dracoEncoder.MeshBuilder();
			dracoObject = new dracoEncoder.Mesh();

			var vertices = geometry.getAttribute('position');
			builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

			var faces = geometry.getIndex();

			if (faces !== null) {

				builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);

			} else {

				var faces = new (vertices.count > 65535 ? Uint32Array : Uint16Array)(vertices.count);

				for (i in 0...faces.length) {

					faces[i] = i;

				}

				builder.AddFacesToMesh(dracoObject, vertices.count, faces);

			}

			if (options.exportNormals === true) {

				var normals = geometry.getAttribute('normal');

				if (normals !== undefined) {

					builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.NORMAL, normals.count, normals.itemSize, normals.array);

				}

			}

			if (options.exportUvs === true) {

				var uvs = geometry.getAttribute('uv');

				if (uvs !== undefined) {

					builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.TEX_COORD, uvs.count, uvs.itemSize, uvs.array);

				}

			}

			if (options.exportColor === true) {

				var colors = geometry.getAttribute('color');

				if (colors !== undefined) {

					var array = createVertexColorSRGBArray(colors);

					builder.AddFloatAttributeToMesh(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);

				}

			}

		} else if (object.isPoints === true) {

			builder = new dracoEncoder.PointCloudBuilder();
			dracoObject = new dracoEncoder.PointCloud();

			var vertices = geometry.getAttribute('position');
			builder.AddFloatAttribute(dracoObject, dracoEncoder.POSITION, vertices.count, vertices.itemSize, vertices.array);

			if (options.exportColor === true) {

				var colors = geometry.getAttribute('color');

				if (colors !== undefined) {

					var array = createVertexColorSRGBArray(colors);

					builder.AddFloatAttribute(dracoObject, dracoEncoder.COLOR, colors.count, colors.itemSize, array);

				}

			}

		} else {

			throw new Error('DRACOExporter: Unsupported object type.');

		}

		//Compress using draco encoder

		var encodedData = new dracoEncoder.DracoInt8Array();

		//Sets the desired encoding and decoding speed for the given options from 0 (slowest speed, but the best compression) to 10 (fastest, but the worst compression).

		var encodeSpeed = (options.encodeSpeed !== undefined) ? options.encodeSpeed : 5;
		var decodeSpeed = (options.decodeSpeed !== undefined) ? options.decodeSpeed : 5;

		encoder.SetSpeedOptions(encodeSpeed, decodeSpeed);

		// Sets the desired encoding method for a given geometry.

		if (options.encoderMethod !== undefined) {

			encoder.SetEncodingMethod(options.encoderMethod);

		}

		// Sets the quantization (number of bits used to represent) compression options for a named attribute.
		// The attribute values will be quantized in a box defined by the maximum extent of the attribute values.
		if (options.quantization !== undefined) {

			for (i in 0...5) {

				if (options.quantization[i] !== undefined) {

					encoder.SetAttributeQuantization(i, options.quantization[i]);

				}

			}

		}

		var length;

		if (object.isMesh === true) {

			length = encoder.EncodeMeshToDracoBuffer(dracoObject, encodedData);

		} else {

			length = encoder.EncodePointCloudToDracoBuffer(dracoObject, true, encodedData);

		}

		dracoEncoder.destroy(dracoObject);

		if (length === 0) {

			throw new Error('THREE.DRACOExporter: Draco encoding failed.');

		}

		//Copy encoded data to buffer.
		var outputData = new Int8Array(new ArrayBuffer(length));

		for (i in 0...length) {

			outputData[i] = encodedData.GetValue(i);

		}

		dracoEncoder.destroy(encodedData);
		dracoEncoder.destroy(encoder);
		dracoEncoder.destroy(builder);

		return outputData;

	}

}

function createVertexColorSRGBArray(attribute: Dynamic): Float32Array {

	// While .drc files do not specify colorspace, the only 'official' tooling
	// is PLY and OBJ converters, which use sRGB. We'll assume sRGB is expected
	// for .drc files, but note that Draco buffers embedded in glTF files will
	// be Linear-sRGB instead.

	var _color = new Color();

	var count = attribute.count;
	var itemSize = attribute.itemSize;
	var array = new Float32Array(count * itemSize);

	for (i in 0...count) {

		_color.fromBufferAttribute(attribute, i).convertLinearToSRGB();

		array[i * itemSize] = _color.r;
		array[i * itemSize + 1] = _color.g;
		array[i * itemSize + 2] = _color.b;

		if (itemSize === 4) {

			array[i * itemSize + 3] = attribute.getW(i);

		}

	}

	return array;

}

// Encoder methods

DRACOExporter.MESH_EDGEBREAKER_ENCODING = 1;
DRACOExporter.MESH_SEQUENTIAL_ENCODING = 0;

// Geometry type

DRACOExporter.POINT_CLOUD = 0;
DRACOExporter.TRIANGULAR_MESH = 1;

// Attribute type

DRACOExporter.INVALID = -1;
DRACOExporter.POSITION = 0;
DRACOExporter.NORMAL = 1;
DRACOExporter.COLOR = 2;
DRACOExporter.TEX_COORD = 3;
DRACOExporter.GENERIC = 4;

export DRACOExporter;