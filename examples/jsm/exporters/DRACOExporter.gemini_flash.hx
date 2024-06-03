import three.Color;
import three.Object3D;
import three.Mesh;
import three.Points;
import three.BufferGeometry;
import three.BufferAttribute;
import three.MathUtils;
import three.Triangle;
import three.Vector3;

@:native("DracoEncoderModule")
private extern class DracoEncoder {
	public function new():Void;
	public function destroy(obj:Dynamic):Void;
	public function destroy(obj:Int8Array):Void;
	public function destroy(obj:Float32Array):Void;
	public function destroy(obj:Uint32Array):Void;
	public function destroy(obj:Uint16Array):Void;

	// Encoder
	public function newEncoder():Encoder;
	public function newMeshBuilder():MeshBuilder;
	public function newPointCloudBuilder():PointCloudBuilder;
	public function newMesh():Mesh;
	public function newPointCloud():PointCloud;
	public function newDracoInt8Array():DracoInt8Array;

	// MeshBuilder
	public function AddFloatAttributeToMesh(mesh:Mesh, attributeType:Int, numComponents:Int, componentSize:Int, attributeData:Float32Array):Void;
	public function AddFacesToMesh(mesh:Mesh, numFaces:Int, faceData:Uint32Array):Void;

	// PointCloudBuilder
	public function AddFloatAttribute(pointCloud:PointCloud, attributeType:Int, numComponents:Int, componentSize:Int, attributeData:Float32Array):Void;

	// Encoder
	public function SetSpeedOptions(encodeSpeed:Int, decodeSpeed:Int):Void;
	public function SetEncodingMethod(encodingMethod:Int):Void;
	public function SetAttributeQuantization(attributeType:Int, quantizationBits:Int):Void;
	public function EncodeMeshToDracoBuffer(mesh:Mesh, encodedData:DracoInt8Array):Int;
	public function EncodePointCloudToDracoBuffer(pointCloud:PointCloud, encodeNormals:Bool, encodedData:DracoInt8Array):Int;
}

private extern class Encoder {
	public function SetSpeedOptions(encodeSpeed:Int, decodeSpeed:Int):Void;
	public function SetEncodingMethod(encodingMethod:Int):Void;
	public function SetAttributeQuantization(attributeType:Int, quantizationBits:Int):Void;
	public function EncodeMeshToDracoBuffer(mesh:Mesh, encodedData:DracoInt8Array):Int;
	public function EncodePointCloudToDracoBuffer(pointCloud:PointCloud, encodeNormals:Bool, encodedData:DracoInt8Array):Int;
}

private extern class Mesh {
	public function new():Void;
}

private extern class PointCloud {
	public function new():Void;
}

private extern class MeshBuilder {
	public function AddFloatAttributeToMesh(mesh:Mesh, attributeType:Int, numComponents:Int, componentSize:Int, attributeData:Float32Array):Void;
	public function AddFacesToMesh(mesh:Mesh, numFaces:Int, faceData:Uint32Array):Void;
}

private extern class PointCloudBuilder {
	public function AddFloatAttribute(pointCloud:PointCloud, attributeType:Int, numComponents:Int, componentSize:Int, attributeData:Float32Array):Void;
}

private extern class DracoInt8Array {
	public function GetValue(index:Int):Int;
}

class DRACOExporter {

	public static function parse(object:Object3D, options:Dynamic = null):Int8Array {

		if (DracoEncoder == null) {
			throw new Error('THREE.DRACOExporter: required the draco_encoder to work.');
		}

		var options = options != null ? options : {
			decodeSpeed: 5,
			encodeSpeed: 5,
			encoderMethod: DRACOExporter.MESH_EDGEBREAKER_ENCODING,
			quantization: [ 16, 8, 8, 8, 8 ],
			exportUvs: true,
			exportNormals: true,
			exportColor: false
		};

		var geometry = object.geometry;

		var dracoEncoder = new DracoEncoder();
		var encoder = dracoEncoder.newEncoder();
		var builder:Dynamic;
		var dracoObject:Dynamic;

		if (Std.is(object, Mesh)) {
			builder = dracoEncoder.newMeshBuilder();
			dracoObject = dracoEncoder.newMesh();

			var vertices = geometry.getAttribute('position');
			builder.AddFloatAttributeToMesh(dracoObject, DRACOExporter.POSITION, vertices.count, vertices.itemSize, vertices.array);

			var faces = geometry.getIndex();

			if (faces != null) {
				builder.AddFacesToMesh(dracoObject, faces.count / 3, faces.array);
			} else {
				var faces = new (vertices.count > 65535 ? Uint32Array : Uint16Array)(vertices.count);
				for (var i = 0; i < faces.length; i++) {
					faces[i] = i;
				}
				builder.AddFacesToMesh(dracoObject, vertices.count, faces);
			}

			if (options.exportNormals) {
				var normals = geometry.getAttribute('normal');
				if (normals != null) {
					builder.AddFloatAttributeToMesh(dracoObject, DRACOExporter.NORMAL, normals.count, normals.itemSize, normals.array);
				}
			}

			if (options.exportUvs) {
				var uvs = geometry.getAttribute('uv');
				if (uvs != null) {
					builder.AddFloatAttributeToMesh(dracoObject, DRACOExporter.TEX_COORD, uvs.count, uvs.itemSize, uvs.array);
				}
			}

			if (options.exportColor) {
				var colors = geometry.getAttribute('color');
				if (colors != null) {
					var array = createVertexColorSRGBArray(colors);
					builder.AddFloatAttributeToMesh(dracoObject, DRACOExporter.COLOR, colors.count, colors.itemSize, array);
				}
			}

		} else if (Std.is(object, Points)) {
			builder = dracoEncoder.newPointCloudBuilder();
			dracoObject = dracoEncoder.newPointCloud();

			var vertices = geometry.getAttribute('position');
			builder.AddFloatAttribute(dracoObject, DRACOExporter.POSITION, vertices.count, vertices.itemSize, vertices.array);

			if (options.exportColor) {
				var colors = geometry.getAttribute('color');
				if (colors != null) {
					var array = createVertexColorSRGBArray(colors);
					builder.AddFloatAttribute(dracoObject, DRACOExporter.COLOR, colors.count, colors.itemSize, array);
				}
			}

		} else {
			throw new Error('DRACOExporter: Unsupported object type.');
		}

		var encodedData = dracoEncoder.newDracoInt8Array();

		var encodeSpeed = options.encodeSpeed != null ? options.encodeSpeed : 5;
		var decodeSpeed = options.decodeSpeed != null ? options.decodeSpeed : 5;
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

		var length:Int;
		if (Std.is(object, Mesh)) {
			length = encoder.EncodeMeshToDracoBuffer(dracoObject, encodedData);
		} else {
			length = encoder.EncodePointCloudToDracoBuffer(dracoObject, true, encodedData);
		}

		dracoEncoder.destroy(dracoObject);

		if (length == 0) {
			throw new Error('THREE.DRACOExporter: Draco encoding failed.');
		}

		var outputData = new Int8Array(new ArrayBuffer(length));
		for (var i = 0; i < length; i++) {
			outputData[i] = encodedData.GetValue(i);
		}

		dracoEncoder.destroy(encodedData);
		dracoEncoder.destroy(encoder);
		dracoEncoder.destroy(builder);

		return outputData;

	}

	static function createVertexColorSRGBArray(attribute:BufferAttribute):Float32Array {

		// While .drc files do not specify colorspace, the only 'official' tooling
		// is PLY and OBJ converters, which use sRGB. We'll assume sRGB is expected
		// for .drc files, but note that Draco buffers embedded in glTF files will
		// be Linear-sRGB instead.

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

	static public var MESH_EDGEBREAKER_ENCODING:Int = 1;
	static public var MESH_SEQUENTIAL_ENCODING:Int = 0;

	static public var POINT_CLOUD:Int = 0;
	static public var TRIANGULAR_MESH:Int = 1;

	static public var INVALID:Int = -1;
	static public var POSITION:Int = 0;
	static public var NORMAL:Int = 1;
	static public var COLOR:Int = 2;
	static public var TEX_COORD:Int = 3;
	static public var GENERIC:Int = 4;

}