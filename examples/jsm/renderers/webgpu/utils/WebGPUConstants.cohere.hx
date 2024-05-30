package js;

enum GPUPrimitiveTopology {
	PointList,
	LineList,
	LineStrip,
	TriangleList,
	TriangleStrip,
}

enum GPUCompareFunction {
	Never,
	Less,
	Equal,
	LessEqual,
	Greater,
	NotEqual,
	GreaterEqual,
	Always,
}

enum GPUStoreOp {
	Store,
	Discard,
}

enum GPULoadOp {
	Load,
	Clear,
}

enum GPUFrontFace {
	CCW,
	CW,
}

enum GPUCullMode {
	None,
	Front,
	Back,
}

enum GPUIndexFormat {
	Uint16,
	Uint32,
}

enum GPUVertexFormat {
	Uint8x2,
	Uint8x4,
	Sint8x2,
	Sint8x4,
	Unorm8x2,
	Unorm8x4,
	Snorm8x2,
	Snorm8x4,
	Uint16x2,
	Uint16x4,
	Sint16x2,
	Sint16x4,
	Unorm16x2,
	Unorm16x4,
	Snorm16x2,
	Snorm16x4,
	Float16x2,
	Float16x4,
	Float32,
	Float32x2,
	Float32x3,
	Float32x4,
	Uint32,
	Uint32x2,
	Uint32x3,
	Uint32x4,
	Sint32,
	Sint32x2,
	Sint32x3,
	Sint32x4,
}

enum GPUTextureFormat {
	// 8-bit formats
	R8Unorm,
	R8Snorm,
	R8Uint,
	R8Sint,
	// 16-bit formats
	R16Uint,
	R16Sint,
	R16Float,
	RG8Unorm,
	RG8Snorm,
	RG8Uint,
	RG8Sint,
	// 32-bit formats
	R32Uint,
	R32Sint,
	R32Float,
	RG16Uint,
	RG16Sint,
	RG16Float,
	RGBA8Unorm,
	RGBA8UnormSRGB,
	RGBA8Snorm,
	RGBA8Uint,
	RGBA8Sint,
	BGRA8Unorm,
	BGRA8UnormSRGB,
	// Packed 32-bit formats
	RGB9E5UFloat,
	RGB10A2Unorm,
	RG11B10uFloat,
	// 64-bit formats
	RG32Uint,
	RG32Sint,
	RG32Float,
	RGBA16Uint,
	RGBA16Sint,
	RGBA16Float,
	// 128-bit formats
	RGBA32Uint,
	RGBA32Sint,
	RGBA32Float,
	// Depth and stencil formats
	Stencil8,
	Depth16Unorm,
	Depth24Plus,
	Depth24PlusStencil8,
	Depth32Float,
	// 'depth32float-stencil8' extension
	Depth32FloatStencil8,
	// BC compressed formats usable if 'texture-compression-bc' is both
	// supported by the device/user agent and enabled in requestDevice.
	BC1RGBAUnorm,
	BC1RGBAUnormSRGB,
	BC2RGBAUnorm,
	BC2RGBAUnormSRGB,
	BC3RGBAUnorm,
	BC3RGBAUnormSRGB,
	BC4RUnorm,
	BC4RSnorm,
	BC5RGUnorm,
	BC5RGSnorm,
	BC6HRGBUFloat,
	BC6HRGBFloat,
	BC7RGBAUnorm,
	BC7RGBAUnormSRGB,
	// ETC2 compressed formats usable if 'texture-compression-etc2' is both
	// supported by the device/user agent and enabled in requestDevice.
	ETC2RGB8Unorm,
	ETC2RGB8UnormSRGB,
	ETC2RGB8A1Unorm,
	ETC2RGB8A1UnormSRGB,
	ETC2RGBA8Unorm,
	ETC2RGBA8UnormSRGB,
	EACR11Unorm,
	EACR11Snorm,
	EACRG11Unorm,
	EACRG11Snorm,
	// ASTC compressed formats usable if 'texture-compression-astc' is both
	// supported by the device/user agent and enabled in requestDevice.
	ASTC4x4Unorm,
	ASTC4x4UnormSRGB,
	ASTC5x4Unorm,
	ASTC5x4UnormSRGB,
	ASTC5x5Unorm,
	ASTC5x5UnormSRGB,
	ASTC6x5Unorm,
	ASTC6x5UnormSRGB,
	ASTC6x6Unorm,
	ASTC6x6UnormSRGB,
	ASTC8x5Unorm,
	ASTC8x5UnormSRGB,
	ASTC8x6Unorm,
	ASTC8x6UnormSRGB,
	ASTC8x8Unorm,
	ASTC8x8UnormSRGB,
	ASTC10x5Unorm,
	ASTC10x5UnormSRGB,
	ASTC10x6Unorm,
	ASTC10x6UnormSRGB,
	ASTC10x8Unorm,
	ASTC10x8UnormSRGB,
	ASTC10x10Unorm,
	ASTC10x10UnormSRGB,
	ASTC12x10Unorm,
	ASTC12x10UnormSRGB,
	ASTC12x12Unorm,
	ASTC12x12UnormSRGB,
}

enum GPUAddressMode {
	ClampToEdge,
	Repeat,
	MirrorRepeat,
}

enum GPUFilterMode {
	Linear,
	Nearest,
}

enum GPUBlendFactor {
	Zero,
	One,
	Src,
	OneMinusSrc,
	SrcAlpha,
	OneMinusSrcAlpha,
	Dst,
	OneMinusDstColor,
	DstAlpha,
	OneMinusDstAlpha,
	SrcAlphaSaturated,
	Constant,
	OneMinusConstant,
}

enum GPUBlendOperation {
	Add,
	Subtract,
	ReverseSubtract,
	Min,
	Max,
}

enum GPUColorWriteFlags {
	None,
	Red,
	Green,
	Blue,
	Alpha,
	All,
}

enum GPUStencilOperation {
	Keep,
	Zero,
	Replace,
	Invert,
	IncrementClamp,
	DecrementClamp,
	IncrementWrap,
	DecrementWrap,
}

enum GPUBufferBindingType {
	Uniform,
	Storage,
	ReadOnlyStorage,
}

enum GPUSamplerBindingType {
	Filtering,
	NonFiltering,
	Comparison,
}

enum GPUTextureSampleType {
	Float,
	UnfilterableFloat,
	Depth,
	SInt,
	UInt,
}

enum GPUTextureDimension {
	OneD,
	TwoD,
	ThreeD,
}

enum GPUTextureViewDimension {
	OneD,
	TwoD,
	TwoDArray,
	Cube,
	CubeArray,
	ThreeD,
}

enum GPUTextureAspect {
	All,
	StencilOnly,
	DepthOnly,
}

enum GPUInputStepMode {
	Vertex,
	Instance,
}

enum GPUFeatureName {
	DepthClipControl,
	Depth32FloatStencil8,
	TextureCompressionBC,
	TextureCompressionETC2,
	TextureCompressionASTC,
	TimestampQuery,
	IndirectFirstInstance,
	ShaderF16,
	RG11B10UFloat,
	BGRA8UNormStorage,
	Float32Filterable,
}