import draco_decoder_gltf.draco_decoder_gltf;

class DracoDecoderModule {

	static var ready:Promise<draco_decoder_gltf.draco_decoder_gltf>;

	static function main() {
		DracoDecoderModule.ready = draco_decoder_gltf.draco_decoder_gltf();
	}
}

class VoidPtr extends draco_decoder_gltf.WrapperObject {

	public function new() {
		throw "cannot construct a VoidPtr, no constructor in IDL";
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_VoidPtr___destroy___0(this.ptr);
	}
}

class DecoderBuffer extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DecoderBuffer_DecoderBuffer_0();
		draco_decoder_gltf.getCache(DecoderBuffer)[this.ptr] = this;
	}

	public function Init(data:haxe.io.Bytes, data_size:haxe.Int = null) : Void {
		draco_decoder_gltf.ensureCache.prepare();
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DecoderBuffer_Init_2(this.ptr, data.length > 0 ? data.toBytes() : null, data_size);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DecoderBuffer___destroy___0(this.ptr);
	}
}

class AttributeTransformData extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeTransformData_AttributeTransformData_0();
		draco_decoder_gltf.getCache(AttributeTransformData)[this.ptr] = this;
	}

	public function transform_type() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeTransformData_transform_type_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeTransformData___destroy___0(this.ptr);
	}
}

class GeometryAttribute extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_GeometryAttribute_GeometryAttribute_0();
		draco_decoder_gltf.getCache(GeometryAttribute)[this.ptr] = this;
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_GeometryAttribute___destroy___0(this.ptr);
	}
}

class PointAttribute extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_PointAttribute_0();
		draco_decoder_gltf.getCache(PointAttribute)[this.ptr] = this;
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_size_0(this.ptr);
	}

	public function GetAttributeTransformData() : AttributeTransformData {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_GetAttributeTransformData_0(this.ptr), AttributeTransformData);
	}

	public function attribute_type() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_attribute_type_0(this.ptr);
	}

	public function data_type() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_data_type_0(this.ptr);
	}

	public function num_components() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_num_components_0(this.ptr);
	}

	public function normalized() : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_normalized_0(this.ptr) != 0;
	}

	public function byte_stride() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_byte_stride_0(this.ptr);
	}

	public function byte_offset() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_byte_offset_0(this.ptr);
	}

	public function unique_id() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute_unique_id_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointAttribute___destroy___0(this.ptr);
	}
}

class AttributeQuantizationTransform extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform_AttributeQuantizationTransform_0();
		draco_decoder_gltf.getCache(AttributeQuantizationTransform)[this.ptr] = this;
	}

	public function InitFromAttribute(att:GeometryAttribute) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform_InitFromAttribute_1(this.ptr, att.ptr) != 0;
	}

	public function quantization_bits() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform_quantization_bits_0(this.ptr);
	}

	public function min_value(axis:haxe.Int = null) : Float {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform_min_value_1(this.ptr, axis);
	}

	public function range() : Float {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform_range_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeQuantizationTransform___destroy___0(this.ptr);
	}
}

class AttributeOctahedronTransform extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeOctahedronTransform_AttributeOctahedronTransform_0();
		draco_decoder_gltf.getCache(AttributeOctahedronTransform)[this.ptr] = this;
	}

	public function InitFromAttribute(att:GeometryAttribute) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeOctahedronTransform_InitFromAttribute_1(this.ptr, att.ptr) != 0;
	}

	public function quantization_bits() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeOctahedronTransform_quantization_bits_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_AttributeOctahedronTransform___destroy___0(this.ptr);
	}
}

class PointCloud extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointCloud_PointCloud_0();
		draco_decoder_gltf.getCache(PointCloud)[this.ptr] = this;
	}

	public function num_attributes() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointCloud_num_attributes_0(this.ptr);
	}

	public function num_points() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointCloud_num_points_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_PointCloud___destroy___0(this.ptr);
	}
}

class Mesh extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Mesh_Mesh_0();
		draco_decoder_gltf.getCache(Mesh)[this.ptr] = this;
	}

	public function num_faces() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Mesh_num_faces_0(this.ptr);
	}

	public function num_attributes() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Mesh_num_attributes_0(this.ptr);
	}

	public function num_points() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Mesh_num_points_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Mesh___destroy___0(this.ptr);
	}
}

class Metadata extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Metadata_Metadata_0();
		draco_decoder_gltf.getCache(Metadata)[this.ptr] = this;
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Metadata___destroy___0(this.ptr);
	}
}

class Status extends draco_decoder_gltf.WrapperObject {

	public function new() {
		throw "cannot construct a Status, no constructor in IDL";
	}

	public function code() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Status_code_0(this.ptr);
	}

	public function ok() : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Status_ok_0(this.ptr) != 0;
	}

	public function error_msg() : String {
		return draco_decoder_gltf.UTF8ToString(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Status_error_msg_0(this.ptr));
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Status___destroy___0(this.ptr);
	}
}

class DracoFloat32Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoFloat32Array_DracoFloat32Array_0();
		draco_decoder_gltf.getCache(DracoFloat32Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : Float {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoFloat32Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoFloat32Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoFloat32Array___destroy___0(this.ptr);
	}
}

class DracoInt8Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt8Array_DracoInt8Array_0();
		draco_decoder_gltf.getCache(DracoInt8Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt8Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt8Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt8Array___destroy___0(this.ptr);
	}
}

class DracoUInt8Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt8Array_DracoUInt8Array_0();
		draco_decoder_gltf.getCache(DracoUInt8Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt8Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt8Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt8Array___destroy___0(this.ptr);
	}
}

class DracoInt16Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt16Array_DracoInt16Array_0();
		draco_decoder_gltf.getCache(DracoInt16Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt16Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt16Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt16Array___destroy___0(this.ptr);
	}
}

class DracoUInt16Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt16Array_DracoUInt16Array_0();
		draco_decoder_gltf.getCache(DracoUInt16Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt16Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt16Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt16Array___destroy___0(this.ptr);
	}
}

class DracoInt32Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt32Array_DracoInt32Array_0();
		draco_decoder_gltf.getCache(DracoInt32Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt32Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt32Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoInt32Array___destroy___0(this.ptr);
	}
}

class DracoUInt32Array extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt32Array_DracoUInt32Array_0();
		draco_decoder_gltf.getCache(DracoUInt32Array)[this.ptr] = this;
	}

	public function GetValue(index:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt32Array_GetValue_1(this.ptr, index);
	}

	public function size() : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt32Array_size_0(this.ptr);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_DracoUInt32Array___destroy___0(this.ptr);
	}
}

class MetadataQuerier extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_MetadataQuerier_0();
		draco_decoder_gltf.getCache(MetadataQuerier)[this.ptr] = this;
	}

	public function HasEntry(metadata:Metadata, entry_name:String) : Bool {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_HasEntry_2(this.ptr, metadata.ptr, draco_decoder_gltf.ensureString(entry_name)) != 0;
	}

	public function GetIntEntry(metadata:Metadata, entry_name:String) : haxe.Int {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_GetIntEntry_2(this.ptr, metadata.ptr, draco_decoder_gltf.ensureString(entry_name));
	}

	public function GetIntEntryArray(metadata:Metadata, entry_name:String, out_values:DracoInt32Array) : Void {
		draco_decoder_gltf.ensureCache.prepare();
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_GetIntEntryArray_3(this.ptr, metadata.ptr, draco_decoder_gltf.ensureString(entry_name), out_values.ptr);
	}

	public function GetDoubleEntry(metadata:Metadata, entry_name:String) : Float {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_GetDoubleEntry_2(this.ptr, metadata.ptr, draco_decoder_gltf.ensureString(entry_name));
	}

	public function GetStringEntry(metadata:Metadata, entry_name:String) : String {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.UTF8ToString(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_GetStringEntry_2(this.ptr, metadata.ptr, draco_decoder_gltf.ensureString(entry_name)));
	}

	public function NumEntries(metadata:Metadata) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_NumEntries_1(this.ptr, metadata.ptr);
	}

	public function GetEntryName(metadata:Metadata, entry_id:haxe.Int = null) : String {
		return draco_decoder_gltf.UTF8ToString(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier_GetEntryName_2(this.ptr, metadata.ptr, entry_id));
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_MetadataQuerier___destroy___0(this.ptr);
	}
}

class Decoder extends draco_decoder_gltf.WrapperObject {

	public function new() {
		this.ptr = draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_Decoder_0();
		draco_decoder_gltf.getCache(Decoder)[this.ptr] = this;
	}

	public function DecodeArrayToPointCloud(data:haxe.io.Bytes, data_size:haxe.Int = null, out_point_cloud:PointCloud = null) : Status {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_DecodeArrayToPointCloud_3(this.ptr, data.length > 0 ? data.toBytes() : null, data_size, out_point_cloud.ptr), Status);
	}

	public function DecodeArrayToMesh(data:haxe.io.Bytes, data_size:haxe.Int = null, out_mesh:Mesh = null) : Status {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_DecodeArrayToMesh_3(this.ptr, data.length > 0 ? data.toBytes() : null, data_size, out_mesh.ptr), Status);
	}

	public function GetAttributeId(pc:PointCloud, type:haxe.Int = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeId_2(this.ptr, pc.ptr, type);
	}

	public function GetAttributeIdByName(pc:PointCloud, name:String) : haxe.Int {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeIdByName_2(this.ptr, pc.ptr, draco_decoder_gltf.ensureString(name));
	}

	public function GetAttributeIdByMetadataEntry(pc:PointCloud, name:String, value:String) : haxe.Int {
		draco_decoder_gltf.ensureCache.prepare();
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeIdByMetadataEntry_3(this.ptr, pc.ptr, draco_decoder_gltf.ensureString(name), draco_decoder_gltf.ensureString(value));
	}

	public function GetAttribute(pc:PointCloud, att_id:haxe.Int = null) : PointAttribute {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttribute_2(this.ptr, pc.ptr, att_id), PointAttribute);
	}

	public function GetAttributeByUniqueId(pc:PointCloud, unique_id:haxe.Int = null) : PointAttribute {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeByUniqueId_2(this.ptr, pc.ptr, unique_id), PointAttribute);
	}

	public function GetMetadata(pc:PointCloud) : Metadata {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetMetadata_1(this.ptr, pc.ptr), Metadata);
	}

	public function GetAttributeMetadata(pc:PointCloud, att_id:haxe.Int = null) : Metadata {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeMetadata_2(this.ptr, pc.ptr, att_id), Metadata);
	}

	public function GetFaceFromMesh(m:Mesh, face_id:haxe.Int = null, out_values:DracoUInt32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetFaceFromMesh_3(this.ptr, m.ptr, face_id, out_values.ptr) != 0;
	}

	public function GetTriangleStripsFromMesh(m:Mesh, strip_values:DracoUInt32Array = null) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetTriangleStripsFromMesh_2(this.ptr, m.ptr, strip_values.ptr);
	}

	public function GetTrianglesUInt16Array(m:Mesh, out_size:haxe.Int = null, out_values:DracoUInt16Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetTrianglesUInt16Array_3(this.ptr, m.ptr, out_size, out_values.ptr) != 0;
	}

	public function GetTrianglesUInt32Array(m:Mesh, out_size:haxe.Int = null, out_values:DracoUInt32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetTrianglesUInt32Array_3(this.ptr, m.ptr, out_size, out_values.ptr) != 0;
	}

	public function GetAttributeFloat(pa:PointAttribute, att_index:haxe.Int = null, out_values:DracoFloat32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeFloat_3(this.ptr, pa.ptr, att_index, out_values.ptr) != 0;
	}

	public function GetAttributeFloatForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoFloat32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeFloatForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeIntForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoInt32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeIntForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeInt8ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoInt8Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeInt8ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeUInt8ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoUInt8Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeUInt8ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeInt16ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoInt16Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeInt16ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeUInt16ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoUInt16Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeUInt16ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeInt32ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoInt32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeInt32ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeUInt32ForAllPoints(pc:PointCloud, pa:PointAttribute, out_values:DracoUInt32Array = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeUInt32ForAllPoints_3(this.ptr, pc.ptr, pa.ptr, out_values.ptr) != 0;
	}

	public function GetAttributeDataArrayForAllPoints(pc:PointCloud, pa:PointAttribute, data_type:haxe.Int = null, out_size:haxe.Int = null, out_values:VoidPtr = null) : Bool {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetAttributeDataArrayForAllPoints_5(this.ptr, pc.ptr, pa.ptr, data_type, out_size, out_values.ptr) != 0;
	}

	public function SkipAttributeTransform(att_type:haxe.Int = null) : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_SkipAttributeTransform_1(this.ptr, att_type);
	}

	public function GetEncodedGeometryType_Deprecated(in_buffer:DecoderBuffer) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetEncodedGeometryType_Deprecated_1(this.ptr, in_buffer.ptr);
	}

	public function DecodeBufferToPointCloud(in_buffer:DecoderBuffer, out_point_cloud:PointCloud = null) : Status {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_DecodeBufferToPointCloud_2(this.ptr, in_buffer.ptr, out_point_cloud.ptr
	public function SkipAttributeTransform(att_type:haxe.Int = null) : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_SkipAttributeTransform_1(this.ptr, att_type);
	}

	public function GetEncodedGeometryType_Deprecated(in_buffer:DecoderBuffer) : haxe.Int {
		return draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_GetEncodedGeometryType_Deprecated_1(this.ptr, in_buffer.ptr);
	}

	public function DecodeBufferToPointCloud(in_buffer:DecoderBuffer, out_point_cloud:PointCloud = null) : Status {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_DecodeBufferToPointCloud_2(this.ptr, in_buffer.ptr, out_point_cloud.ptr), Status);
	}

	public function DecodeBufferToMesh(in_buffer:DecoderBuffer, out_mesh:Mesh = null) : Status {
		return draco_decoder_gltf.wrapPointer(draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder_DecodeBufferToMesh_2(this.ptr, in_buffer.ptr, out_mesh.ptr), Status);
	}

	public function __destroy__() : Void {
		draco_decoder_gltf.draco_decoder_gltf._emscripten_bind_Decoder___destroy___0(this.ptr);
	}
}

// ... rest of the code