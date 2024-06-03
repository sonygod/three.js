import draco_decoder.DracoDecoder;
import draco_decoder.DecoderBuffer;
import draco_decoder.Decoder;
import draco_decoder.PointCloud;
import draco_decoder.Mesh;
import draco_decoder.Status;
import draco_decoder.Metadata;
import draco_decoder.MetadataQuerier;
import draco_decoder.PointAttribute;
import draco_decoder.AttributeTransformData;
import draco_decoder.AttributeQuantizationTransform;
import draco_decoder.AttributeOctahedronTransform;
import draco_decoder.DracoFloat32Array;
import draco_decoder.DracoInt8Array;
import draco_decoder.DracoUInt8Array;
import draco_decoder.DracoInt16Array;
import draco_decoder.DracoUInt16Array;
import draco_decoder.DracoInt32Array;
import draco_decoder.DracoUInt32Array;
import draco_decoder.AttributeTransformType;
import draco_decoder.GeometryAttribute_Type;
import draco_decoder.EncodedGeometryType;
import draco_decoder.DataType;
import draco_decoder.StatusCode;

class DracoDecoderModule {
    public static var ready:Promise<DracoDecoderModule> = new Promise((resolve, reject) => {
        DracoDecoder.load(function(decoder) {
            resolve(new DracoDecoderModule(decoder));
        });
    });

    private decoder:DracoDecoder;

    public function new(decoder:DracoDecoder) {
        this.decoder = decoder;
    }

    public var ATTRIBUTE_INVALID_TRANSFORM:AttributeTransformType = AttributeTransformType.ATTRIBUTE_INVALID_TRANSFORM;
    public var ATTRIBUTE_NO_TRANSFORM:AttributeTransformType = AttributeTransformType.ATTRIBUTE_NO_TRANSFORM;
    public var ATTRIBUTE_QUANTIZATION_TRANSFORM:AttributeTransformType = AttributeTransformType.ATTRIBUTE_QUANTIZATION_TRANSFORM;
    public var ATTRIBUTE_OCTAHEDRON_TRANSFORM:AttributeTransformType = AttributeTransformType.ATTRIBUTE_OCTAHEDRON_TRANSFORM;

    public var INVALID:GeometryAttribute_Type = GeometryAttribute_Type.INVALID;
    public var POSITION:GeometryAttribute_Type = GeometryAttribute_Type.POSITION;
    public var NORMAL:GeometryAttribute_Type = GeometryAttribute_Type.NORMAL;
    public var COLOR:GeometryAttribute_Type = GeometryAttribute_Type.COLOR;
    public var TEX_COORD:GeometryAttribute_Type = GeometryAttribute_Type.TEX_COORD;
    public var GENERIC:GeometryAttribute_Type = GeometryAttribute_Type.GENERIC;

    public var INVALID_GEOMETRY_TYPE:EncodedGeometryType = EncodedGeometryType.INVALID_GEOMETRY_TYPE;
    public var POINT_CLOUD:EncodedGeometryType = EncodedGeometryType.POINT_CLOUD;
    public var TRIANGULAR_MESH:EncodedGeometryType = EncodedGeometryType.TRIANGULAR_MESH;

    public var DT_INVALID:DataType = DataType.DT_INVALID;
    public var DT_INT8:DataType = DataType.DT_INT8;
    public var DT_UINT8:DataType = DataType.DT_UINT8;
    public var DT_INT16:DataType = DataType.DT_INT16;
    public var DT_UINT16:DataType = DataType.DT_UINT16;
    public var DT_INT32:DataType = DataType.DT_INT32;
    public var DT_UINT32:DataType = DataType.DT_UINT32;
    public var DT_INT64:DataType = DataType.DT_INT64;
    public var DT_UINT64:DataType = DataType.DT_UINT64;
    public var DT_FLOAT32:DataType = DataType.DT_FLOAT32;
    public var DT_FLOAT64:DataType = DataType.DT_FLOAT64;
    public var DT_BOOL:DataType = DataType.DT_BOOL;
    public var DT_TYPES_COUNT:DataType = DataType.DT_TYPES_COUNT;

    public var OK:StatusCode = StatusCode.OK;
    public var DRACO_ERROR:StatusCode = StatusCode.DRACO_ERROR;
    public var IO_ERROR:StatusCode = StatusCode.IO_ERROR;
    public var INVALID_PARAMETER:StatusCode = StatusCode.INVALID_PARAMETER;
    public var UNSUPPORTED_VERSION:StatusCode = StatusCode.UNSUPPORTED_VERSION;
    public var UNKNOWN_VERSION:StatusCode = StatusCode.UNKNOWN_VERSION;

    public function DecoderBuffer(data:haxe.io.Bytes):DecoderBuffer {
        return new DecoderBuffer(data);
    }

    public function Decoder():Decoder {
        return new Decoder();
    }

    public function DecodeArrayToPointCloud(data:haxe.io.Bytes, data_size:Int, out_point_cloud:PointCloud):Status {
        return this.decoder.decodeArrayToPointCloud(data, data_size, out_point_cloud);
    }

    public function DecodeArrayToMesh(data:haxe.io.Bytes, data_size:Int, out_mesh:Mesh):Status {
        return this.decoder.decodeArrayToMesh(data, data_size, out_mesh);
    }

    public function GetAttributeId(pc:PointCloud, type:GeometryAttribute_Type):Int {
        return this.decoder.getAttributeId(pc, type);
    }

    public function GetAttributeIdByName(pc:PointCloud, name:String):Int {
        return this.decoder.getAttributeIdByName(pc, name);
    }

    public function GetAttributeIdByMetadataEntry(pc:PointCloud, name:String, value:String):Int {
        return this.decoder.getAttributeIdByMetadataEntry(pc, name, value);
    }

    public function GetAttribute(pc:PointCloud, att_id:Int):PointAttribute {
        return this.decoder.getAttribute(pc, att_id);
    }

    public function GetAttributeByUniqueId(pc:PointCloud, unique_id:Int):PointAttribute {
        return this.decoder.getAttributeByUniqueId(pc, unique_id);
    }

    public function GetMetadata(pc:PointCloud):Metadata {
        return this.decoder.getMetadata(pc);
    }

    public function GetAttributeMetadata(pc:PointCloud, att_id:Int):Metadata {
        return this.decoder.getAttributeMetadata(pc, att_id);
    }

    public function GetFaceFromMesh(m:Mesh, face_id:Int, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getFaceFromMesh(m, face_id, out_values);
    }

    public function GetTriangleStripsFromMesh(m:Mesh, strip_values:haxe.io.Bytes):Int {
        return this.decoder.getTriangleStripsFromMesh(m, strip_values);
    }

    public function GetTrianglesUInt16Array(m:Mesh, out_size:haxe.io.Bytes, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getTrianglesUInt16Array(m, out_size, out_values);
    }

    public function GetTrianglesUInt32Array(m:Mesh, out_size:haxe.io.Bytes, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getTrianglesUInt32Array(m, out_size, out_values);
    }

    public function GetAttributeFloat(pa:PointAttribute, att_index:Int, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeFloat(pa, att_index, out_values);
    }

    public function GetAttributeFloatForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeFloatForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeIntForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeIntForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeInt8ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeInt8ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeUInt8ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeUInt8ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeInt16ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeInt16ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeUInt16ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeUInt16ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeInt32ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeInt32ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeUInt32ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeUInt32ForAllPoints(pc, pa, out_values);
    }

    public function GetAttributeDataArrayForAllPoints(pc:PointCloud, pa:PointAttribute, data_type:DataType, out_size:haxe.io.Bytes, out_values:haxe.io.Bytes):Bool {
        return this.decoder.getAttributeDataArrayForAllPoints(pc, pa, data_type, out_size, out_values);
    }

    public function SkipAttributeTransform(att_type:AttributeTransformType):Void {
        this.decoder.skipAttributeTransform(att_type);
    }

    public function GetEncodedGeometryType(array:haxe.io.Bytes):EncodedGeometryType {
        return this.decoder.getEncodedGeometryType(array);
    }

    public function DecodeBufferToPointCloud(in_buffer:DecoderBuffer, out_point_cloud:PointCloud):Status {
        return this.decoder.decodeBufferToPointCloud(in_buffer, out_point_cloud);
    }

    public function DecodeBufferToMesh(in_buffer:DecoderBuffer, out_mesh:Mesh):Status {
        return this.decoder.decodeBufferToMesh(in_buffer, out_mesh);
    }

    public function MetadataQuerier():MetadataQuerier {
        return new MetadataQuerier();
    }

    public function DracoFloat32Array(data:haxe.io.Bytes):DracoFloat32Array {
        return new DracoFloat32Array(data);
    }

    public function DracoInt8Array(data:haxe.io.Bytes):DracoInt8Array {
        return new DracoInt8Array(data);
    }

    public function DracoUInt8Array(data:haxe.io.Bytes):DracoUInt8Array {
        return new DracoUInt8Array(data);
    }

    public function DracoInt16Array(data:haxe.io.Bytes):DracoInt16Array {
        return new DracoInt16Array(data);
    }

    public function DracoUInt16Array(data:haxe.io.Bytes):DracoUInt16Array {
        return new DracoUInt16Array(data);
    }

    public function DracoInt32Array(data:haxe.io.Bytes):DracoInt32Array {
        return new DracoInt32Array(data);
    }

    public function DracoUInt32Array(data:haxe.io.Bytes):DracoUInt32Array {
        return new DracoUInt32Array(data);
    }

    public function AttributeQuantizationTransform():AttributeQuantizationTransform {
        return new AttributeQuantizationTransform();
    }

    public function AttributeOctahedronTransform():AttributeOctahedronTransform {
        return new AttributeOctahedronTransform();
    }

    public function PointCloud():PointCloud {
        return new PointCloud();
    }

    public function Mesh():Mesh {
        return new Mesh();
    }

    public function Metadata():Metadata {
        return new Metadata();
    }

    public function Status():Status {
        return new Status();
    }
}