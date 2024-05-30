import three.examples.jsm.exporters.KTX2Exporter.{
	FloatType,
	HalfFloatType,
	UnsignedByteType,
	RGBAFormat,
	RGFormat,
	RGIntegerFormat,
	RedFormat,
	RedIntegerFormat,
	NoColorSpace,
	LinearSRGBColorSpace,
	SRGBColorSpace,
	DataTexture,
	REVISION,
}

import three.examples.jsm.libs.ktx-parse.module.{
	write,
	KTX2Container,
	KHR_DF_CHANNEL_RGBSDA_ALPHA,
	KHR_DF_CHANNEL_RGBSDA_BLUE,
	KHR_DF_CHANNEL_RGBSDA_GREEN,
	KHR_DF_CHANNEL_RGBSDA_RED,
	KHR_DF_MODEL_RGBSDA,
	KHR_DF_PRIMARIES_BT709,
	KHR_DF_PRIMARIES_UNSPECIFIED,
	KHR_DF_SAMPLE_DATATYPE_FLOAT,
	KHR_DF_SAMPLE_DATATYPE_LINEAR,
	KHR_DF_SAMPLE_DATATYPE_SIGNED,
	KHR_DF_TRANSFER_LINEAR,
	KHR_DF_TRANSFER_SRGB,
	VK_FORMAT_R16_SFLOAT,
	VK_FORMAT_R16G16_SFLOAT,
	VK_FORMAT_R16G16B16A16_SFLOAT,
	VK_FORMAT_R32_SFLOAT,
	VK_FORMAT_R32G32_SFLOAT,
	VK_FORMAT_R32G32B32A32_SFLOAT,
	VK_FORMAT_R8_SRGB,
	VK_FORMAT_R8_UNORM,
	VK_FORMAT_R8G8_SRGB,
	VK_FORMAT_R8G8_UNORM,
	VK_FORMAT_R8G8B8A8_SRGB,
	VK_FORMAT_R8G8B8A8_UNORM,
}

class VK_FORMAT_MAP {

	public static var RGBAFormat:Dynamic = {
		FloatType: {
			NoColorSpace: VK_FORMAT_R32G32B32A32_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R32G32B32A32_SFLOAT,
		},
		HalfFloatType: {
			NoColorSpace: VK_FORMAT_R16G16B16A16_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R16G16B16A16_SFLOAT,
		},
		UnsignedByteType: {
			NoColorSpace: VK_FORMAT_R8G8B8A8_UNORM,
			LinearSRGBColorSpace: VK_FORMAT_R8G8B8A8_UNORM,
			SRGBColorSpace: VK_FORMAT_R8G8B8A8_SRGB,
		},
	};

	public static var RGFormat:Dynamic = {
		FloatType: {
			NoColorSpace: VK_FORMAT_R32G32_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R32G32_SFLOAT,
		},
		HalfFloatType: {
			NoColorSpace: VK_FORMAT_R16G16_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R16G16_SFLOAT,
		},
		UnsignedByteType: {
			NoColorSpace: VK_FORMAT_R8G8_UNORM,
			LinearSRGBColorSpace: VK_FORMAT_R8G8_UNORM,
			SRGBColorSpace: VK_FORMAT_R8G8_SRGB,
		},
	};

	public static var RedFormat:Dynamic = {
		FloatType: {
			NoColorSpace: VK_FORMAT_R32_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R32_SFLOAT,
		},
		HalfFloatType: {
			NoColorSpace: VK_FORMAT_R16_SFLOAT,
			LinearSRGBColorSpace: VK_FORMAT_R16_SFLOAT,
		},
		UnsignedByteType: {
			NoColorSpace: VK_FORMAT_R8_UNORM,
			LinearSRGBColorSpace: VK_FORMAT_R8_UNORM,
			SRGBColorSpace: VK_FORMAT_R8_SRGB,
		},
	};

}

class KHR_DF_CHANNEL_MAP {

	public static var map:Dynamic = {
		0: KHR_DF_CHANNEL_RGBSDA_RED,
		1: KHR_DF_CHANNEL_RGBSDA_GREEN,
		2: KHR_DF_CHANNEL_RGBSDA_BLUE,
		3: KHR_DF_CHANNEL_RGBSDA_ALPHA,
	};

}

class ERROR_INPUT {

	public static var message:String = 'THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.';

}

class ERROR_FORMAT {

	public static var message:String = 'THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.';

}

class ERROR_TYPE {

	public static var message:String = 'THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.';

}

class ERROR_COLOR_SPACE {

	public static var message:String = 'THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.';

}

class KTX2Exporter {

	public function new() {}

	public function parse(arg1:Dynamic, arg2:Dynamic):Dynamic {

		var texture:Dynamic;

		if (Std.is(arg1, DataTexture) || Std.is(arg1, Data3DTexture)) {

			texture = arg1;

		} else if (Std.is(arg1, WebGLRenderer) && Std.is(arg2, WebGLRenderTarget)) {

			texture = toDataTexture(arg1, arg2);

		} else {

			throw new Error(ERROR_INPUT.message);

		}

		if (VK_FORMAT_MAP[texture.format] === null) {

			throw new Error(ERROR_FORMAT.message);

		}

		if (VK_FORMAT_MAP[texture.format][texture.type] === null) {

			throw new Error(ERROR_TYPE.message);

		}

		if (VK_FORMAT_MAP[texture.format][texture.type][texture.colorSpace] === null) {

			throw new Error(ERROR_COLOR_SPACE.message);

		}

		// ... rest of the code

	}

}

// ... rest of the code