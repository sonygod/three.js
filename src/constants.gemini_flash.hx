package three;

@:native('REVISION')
public var REVISION : String = "165dev";

typedef Mouse = {
    LEFT: Int,
    MIDDLE: Int,
    RIGHT: Int,
    ROTATE: Int,
    DOLLY: Int,
    PAN: Int
};

@:native('MOUSE')
public var MOUSE : Mouse = {
    LEFT: 0,
    MIDDLE: 1,
    RIGHT: 2,
    ROTATE: 0,
    DOLLY: 1,
    PAN: 2
};

typedef Touch = {
    ROTATE: Int,
    PAN: Int,
    DOLLY_PAN: Int,
    DOLLY_ROTATE: Int
};

@:native('TOUCH')
public var TOUCH : Touch = {
    ROTATE: 0,
    PAN: 1,
    DOLLY_PAN: 2,
    DOLLY_ROTATE: 3
};

public var CullFaceNone : Int = 0;
public var CullFaceBack : Int = 1;
public var CullFaceFront : Int = 2;
public var CullFaceFrontBack : Int = 3;

public var BasicShadowMap : Int = 0;
public var PCFShadowMap : Int = 1;
public var PCFSoftShadowMap : Int = 2;
public var VSMShadowMap : Int = 3;

public var FrontSide : Int = 0;
public var BackSide : Int = 1;
public var DoubleSide : Int = 2;

public var NoBlending : Int = 0;
public var NormalBlending : Int = 1;
public var AdditiveBlending : Int = 2;
public var SubtractiveBlending : Int = 3;
public var MultiplyBlending : Int = 4;
public var CustomBlending : Int = 5;

public var AddEquation : Int = 100;
public var SubtractEquation : Int = 101;
public var ReverseSubtractEquation : Int = 102;
public var MinEquation : Int = 103;
public var MaxEquation : Int = 104;

public var ZeroFactor : Int = 200;
public var OneFactor : Int = 201;
public var SrcColorFactor : Int = 202;
public var OneMinusSrcColorFactor : Int = 203;
public var SrcAlphaFactor : Int = 204;
public var OneMinusSrcAlphaFactor : Int = 205;
public var DstAlphaFactor : Int = 206;
public var OneMinusDstAlphaFactor : Int = 207;
public var DstColorFactor : Int = 208;
public var OneMinusDstColorFactor : Int = 209;
public var SrcAlphaSaturateFactor : Int = 210;
public var ConstantColorFactor : Int = 211;
public var OneMinusConstantColorFactor : Int = 212;
public var ConstantAlphaFactor : Int = 213;
public var OneMinusConstantAlphaFactor : Int = 214;

public var NeverDepth : Int = 0;
public var AlwaysDepth : Int = 1;
public var LessDepth : Int = 2;
public var LessEqualDepth : Int = 3;
public var EqualDepth : Int = 4;
public var GreaterEqualDepth : Int = 5;
public var GreaterDepth : Int = 6;
public var NotEqualDepth : Int = 7;

public var MultiplyOperation : Int = 0;
public var MixOperation : Int = 1;
public var AddOperation : Int = 2;

public var NoToneMapping : Int = 0;
public var LinearToneMapping : Int = 1;
public var ReinhardToneMapping : Int = 2;
public var CineonToneMapping : Int = 3;
public var ACESFilmicToneMapping : Int = 4;
public var CustomToneMapping : Int = 5;
public var AgXToneMapping : Int = 6;
public var NeutralToneMapping : Int = 7;

public var AttachedBindMode : String = "attached";
public var DetachedBindMode : String = "detached";

public var UVMapping : Int = 300;
public var CubeReflectionMapping : Int = 301;
public var CubeRefractionMapping : Int = 302;
public var EquirectangularReflectionMapping : Int = 303;
public var EquirectangularRefractionMapping : Int = 304;
public var CubeUVReflectionMapping : Int = 306;

public var RepeatWrapping : Int = 1000;
public var ClampToEdgeWrapping : Int = 1001;
public var MirroredRepeatWrapping : Int = 1002;

public var NearestFilter : Int = 1003;
public var NearestMipmapNearestFilter : Int = 1004;
public var NearestMipmapLinearFilter : Int = 1005;

public var LinearFilter : Int = 1006;
public var LinearMipmapNearestFilter : Int = 1007;
public var LinearMipmapLinearFilter : Int = 1008;

public var UnsignedByteType : Int = 1009;
public var ByteType : Int = 1010;
public var ShortType : Int = 1011;
public var UnsignedShortType : Int = 1012;
public var IntType : Int = 1013;
public var UnsignedIntType : Int = 1014;
public var FloatType : Int = 1015;
public var HalfFloatType : Int = 1016;
public var UnsignedShort4444Type : Int = 1017;
public var UnsignedShort5551Type : Int = 1018;
public var UnsignedInt248Type : Int = 1020;
public var UnsignedInt5999Type : Int = 35902;

public var AlphaFormat : Int = 1021;
public var RGBFormat : Int = 1022;
public var RGBAFormat : Int = 1023;
public var LuminanceFormat : Int = 1024;
public var LuminanceAlphaFormat : Int = 1025;
public var DepthFormat : Int = 1026;
public var DepthStencilFormat : Int = 1027;
public var RedFormat : Int = 1028;
public var RedIntegerFormat : Int = 1029;
public var RGFormat : Int = 1030;
public var RGIntegerFormat : Int = 1031;
public var RGBAIntegerFormat : Int = 1033;

public var RGB_S3TC_DXT1_Format : Int = 33776;
public var RGBA_S3TC_DXT1_Format : Int = 33777;
public var RGBA_S3TC_DXT3_Format : Int = 33778;
public var RGBA_S3TC_DXT5_Format : Int = 33779;

public var RGB_PVRTC_4BPPV1_Format : Int = 35840;
public var RGB_PVRTC_2BPPV1_Format : Int = 35841;
public var RGBA_PVRTC_4BPPV1_Format : Int = 35842;
public var RGBA_PVRTC_2BPPV1_Format : Int = 35843;

public var RGB_ETC1_Format : Int = 36196;
public var RGB_ETC2_Format : Int = 37492;
public var RGBA_ETC2_EAC_Format : Int = 37496;

public var RGBA_ASTC_4x4_Format : Int = 37808;
public var RGBA_ASTC_5x4_Format : Int = 37809;
public var RGBA_ASTC_5x5_Format : Int = 37810;
public var RGBA_ASTC_6x5_Format : Int = 37811;
public var RGBA_ASTC_6x6_Format : Int = 37812;
public var RGBA_ASTC_8x5_Format : Int = 37813;
public var RGBA_ASTC_8x6_Format : Int = 37814;
public var RGBA_ASTC_8x8_Format : Int = 37815;
public var RGBA_ASTC_10x5_Format : Int = 37816;
public var RGBA_ASTC_10x6_Format : Int = 37817;
public var RGBA_ASTC_10x8_Format : Int = 37818;
public var RGBA_ASTC_10x10_Format : Int = 37819;
public var RGBA_ASTC_12x10_Format : Int = 37820;
public var RGBA_ASTC_12x12_Format : Int = 37821;

public var RGBA_BPTC_Format : Int = 36492;
public var RGB_BPTC_SIGNED_Format : Int = 36494;
public var RGB_BPTC_UNSIGNED_Format : Int = 36495;

public var RED_RGTC1_Format : Int = 36283;
public var SIGNED_RED_RGTC1_Format : Int = 36284;
public var RED_GREEN_RGTC2_Format : Int = 36285;
public var SIGNED_RED_GREEN_RGTC2_Format : Int = 36286;

public var LoopOnce : Int = 2200;
public var LoopRepeat : Int = 2201;
public var LoopPingPong : Int = 2202;

public var InterpolateDiscrete : Int = 2300;
public var InterpolateLinear : Int = 2301;
public var InterpolateSmooth : Int = 2302;

public var ZeroCurvatureEnding : Int = 2400;
public var ZeroSlopeEnding : Int = 2401;
public var WrapAroundEnding : Int = 2402;

public var NormalAnimationBlendMode : Int = 2500;
public var AdditiveAnimationBlendMode : Int = 2501;

public var TrianglesDrawMode : Int = 0;
public var TriangleStripDrawMode : Int = 1;
public var TriangleFanDrawMode : Int = 2;

public var BasicDepthPacking : Int = 3200;
public var RGBADepthPacking : Int = 3201;

public var TangentSpaceNormalMap : Int = 0;
public var ObjectSpaceNormalMap : Int = 1;

public var NoColorSpace : String = "";
public var SRGBColorSpace : String = "srgb";
public var LinearSRGBColorSpace : String = "srgb-linear";
public var DisplayP3ColorSpace : String = "display-p3";
public var LinearDisplayP3ColorSpace : String = "display-p3-linear";

public var LinearTransfer : String = "linear";
public var SRGBTransfer : String = "srgb";

public var Rec709Primaries : String = "rec709";
public var P3Primaries : String = "p3";

public var ZeroStencilOp : Int = 0;
public var KeepStencilOp : Int = 7680;
public var ReplaceStencilOp : Int = 7681;
public var IncrementStencilOp : Int = 7682;
public var DecrementStencilOp : Int = 7683;
public var IncrementWrapStencilOp : Int = 34055;
public var DecrementWrapStencilOp : Int = 34056;
public var InvertStencilOp : Int = 5386;

public var NeverStencilFunc : Int = 512;
public var LessStencilFunc : Int = 513;
public var EqualStencilFunc : Int = 514;
public var LessEqualStencilFunc : Int = 515;
public var GreaterStencilFunc : Int = 516;
public var NotEqualStencilFunc : Int = 517;
public var GreaterEqualStencilFunc : Int = 518;
public var AlwaysStencilFunc : Int = 519;

public var NeverCompare : Int = 512;
public var LessCompare : Int = 513;
public var EqualCompare : Int = 514;
public var LessEqualCompare : Int = 515;
public var GreaterCompare : Int = 516;
public var NotEqualCompare : Int = 517;
public var GreaterEqualCompare : Int = 518;
public var AlwaysCompare : Int = 519;

public var StaticDrawUsage : Int = 35044;
public var DynamicDrawUsage : Int = 35048;
public var StreamDrawUsage : Int = 35040;
public var StaticReadUsage : Int = 35045;
public var DynamicReadUsage : Int = 35049;
public var StreamReadUsage : Int = 35041;
public var StaticCopyUsage : Int = 35046;
public var DynamicCopyUsage : Int = 35050;
public var StreamCopyUsage : Int = 35042;

public var GLSL1 : String = "100";
public var GLSL3 : String = "300 es";

public var WebGLCoordinateSystem : Int = 2000;
public var WebGPUCoordinateSystem : Int = 2001;