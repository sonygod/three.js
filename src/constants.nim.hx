package three.js.src;

class Constants {
    public static var REVISION:String = '165dev';

    public static var MOUSE = { LEFT: 0, MIDDLE: 1, RIGHT: 2, ROTATE: 0, DOLLY: 1, PAN: 2 };
    public static var TOUCH = { ROTATE: 0, PAN: 1, DOLLY_PAN: 2, DOLLY_ROTATE: 3 };
    public static var CullFaceNone = 0;
    public static var CullFaceBack = 1;
    public static var CullFaceFront = 2;
    public static var CullFaceFrontBack = 3;
    public static var BasicShadowMap = 0;
    public static var PCFShadowMap = 1;
    public static var PCFSoftShadowMap = 2;
    public static var VSMShadowMap = 3;
    public static var FrontSide = 0;
    public static var BackSide = 1;
    public static var DoubleSide = 2;
    public static var NoBlending = 0;
    public static var NormalBlending = 1;
    public static var AdditiveBlending = 2;
    public static var SubtractiveBlending = 3;
    public static var MultiplyBlending = 4;
    public static var CustomBlending = 5;
    public static var AddEquation = 100;
    public static var SubtractEquation = 101;
    public static var ReverseSubtractEquation = 102;
    public static var MinEquation = 103;
    public static var MaxEquation = 104;
    public static var ZeroFactor = 200;
    public static var OneFactor = 201;
    public static var SrcColorFactor = 202;
    public static var OneMinusSrcColorFactor = 203;
    public static var SrcAlphaFactor = 204;
    public static var OneMinusSrcAlphaFactor = 205;
    public static var DstAlphaFactor = 206;
    public static var OneMinusDstAlphaFactor = 207;
    public static var DstColorFactor = 208;
    public static var OneMinusDstColorFactor = 209;
    public static var SrcAlphaSaturateFactor = 210;
    public static var ConstantColorFactor = 211;
    public static var OneMinusConstantColorFactor = 212;
    public static var ConstantAlphaFactor = 213;
    public static var OneMinusConstantAlphaFactor = 214;
    public static var NeverDepth = 0;
    public static var AlwaysDepth = 1;
    public static var LessDepth = 2;
    public static var LessEqualDepth = 3;
    public static var EqualDepth = 4;
    public static var GreaterEqualDepth = 5;
    public static var GreaterDepth = 6;
    public static var NotEqualDepth = 7;
    public static var MultiplyOperation = 0;
    public static var MixOperation = 1;
    public static var AddOperation = 2;
    public static var NoToneMapping = 0;
    public static var LinearToneMapping = 1;
    public static var ReinhardToneMapping = 2;
    public static var CineonToneMapping = 3;
    public static var ACESFilmicToneMapping = 4;
    public static var CustomToneMapping = 5;
    public static var AgXToneMapping = 6;
    public static var NeutralToneMapping = 7;
    public static var AttachedBindMode = 'attached';
    public static var DetachedBindMode = 'detached';

    public static var UVMapping = 300;
    public static var CubeReflectionMapping = 301;
    public static var CubeRefractionMapping = 302;
    public static var EquirectangularReflectionMapping = 303;
    public static var EquirectangularRefractionMapping = 304;
    public static var CubeUVReflectionMapping = 306;
    public static var RepeatWrapping = 1000;
    public static var ClampToEdgeWrapping = 1001;
    public static var MirroredRepeatWrapping = 1002;
    public static var NearestFilter = 1003;
    public static var NearestMipmapNearestFilter = 1004;
    public static var NearestMipMapNearestFilter = 1004;
    public static var NearestMipmapLinearFilter = 1005;
    public static var NearestMipMapLinearFilter = 1005;
    public static var LinearFilter = 1006;
    public static var LinearMipmapNearestFilter = 1007;
    public static var LinearMipMapNearestFilter = 1007;
    public static var LinearMipmapLinearFilter = 1008;
    public static var LinearMipMapLinearFilter = 1008;
    public static var UnsignedByteType = 1009;
    public static var ByteType = 1010;
    public static var ShortType = 1011;
    public static var UnsignedShortType = 1012;
    public static var IntType = 1013;
    public static var UnsignedIntType = 1014;
    public static var FloatType = 1015;
    public static var HalfFloatType = 1016;
    public static var UnsignedShort4444Type = 1017;
    public static var UnsignedShort5551Type = 1018;
    public static var UnsignedInt248Type = 1020;
    public static var UnsignedInt5999Type = 35902;
    public static var AlphaFormat = 1021;
    public static var RGBFormat = 1022;
    public static var RGBAFormat = 1023;
    public static var LuminanceFormat = 1024;
    public static var LuminanceAlphaFormat = 1025;
    public static var DepthFormat = 1026;
    public static var DepthStencilFormat = 1027;
    public static var RedFormat = 1028;
    public static var RedIntegerFormat = 1029;
    public static var RGFormat = 1030;
    public static var RGIntegerFormat = 1031;
    public static var RGBAIntegerFormat = 1033;

    public static var RGB_S3TC_DXT1_Format = 33776;
    public static var RGBA_S3TC_DXT1_Format = 33777;
    public static var RGBA_S3TC_DXT3_Format = 33778;
    public static var RGBA_S3TC_DXT5_Format = 33779;
    public static var RGB_PVRTC_4BPPV1_Format = 35840;
    public static var RGB_PVRTC_2BPPV1_Format = 35841;
    public static var RGBA_PVRTC_4BPPV1_Format = 35842;
    public static var RGBA_PVRTC_2BPPV1_Format = 35843;
    public static var RGB_ETC1_Format = 36196;
    public static var RGB_ETC2_Format = 37492;
    public static var RGBA_ETC2_EAC_Format = 37496;
    public static var RGBA_ASTC_4x4_Format = 37808;
    public static var RGBA_ASTC_5x4_Format = 37809;
    public static var RGBA_ASTC_5x5_Format = 37810;
    public static var RGBA_ASTC_6x5_Format = 37811;
    public static var RGBA_ASTC_6x6_Format = 37812;
    public static var RGBA_ASTC_8x5_Format = 37813;
    public static var RGBA_ASTC_8x6_Format = 37814;
    public static var RGBA_ASTC_8x8_Format = 37815;
    public static var RGBA_ASTC_10x5_Format = 37816;
    public static var RGBA_ASTC_10x6_Format = 37817;
    public static var RGBA_ASTC_10x8_Format = 37818;
    public static var RGBA_ASTC_10x10_Format = 37819;
    public static var RGBA_ASTC_12x10_Format = 37820;
    public static var RGBA_ASTC_12x12_Format = 37821;
    public static var RGBA_BPTC_Format = 36492;
    public static var RGB_BPTC_SIGNED_Format = 36494;
    public static var RGB_BPTC_UNSIGNED_Format = 36495;
    public static var RED_RGTC1_Format = 36283;
    public static var SIGNED_RED_RGTC1_Format = 36284;
    public static var RED_GREEN_RGTC2_Format = 36285;
    public static var SIGNED_RED_GREEN_RGTC2_Format = 36286;
    public static var LoopOnce = 2200;
    public static var LoopRepeat = 2201;
    public static var LoopPingPong = 2202;
    public static var InterpolateDiscrete = 2300;
    public static var InterpolateLinear = 2301;
    public static var InterpolateSmooth = 2302;
    public static var ZeroCurvatureEnding = 2400;
    public static var ZeroSlopeEnding = 2401;
    public static var WrapAroundEnding = 2402;
    public static var NormalAnimationBlendMode = 2500;
    public static var AdditiveAnimationBlendMode = 2501;
    public static var TrianglesDrawMode = 0;
    public static var TriangleStripDrawMode = 1;
    public static var TriangleFanDrawMode = 2;
    public static var BasicDepthPacking = 3200;
    public static var RGBADepthPacking = 3201;
    public static var TangentSpaceNormalMap = 0;
    public static var ObjectSpaceNormalMap = 1;

    // Color space string identifiers, matching CSS Color Module Level 4 and WebGPU names where available.
    public static var NoColorSpace:String = '';
    public static var SRGBColorSpace:String = 'srgb';
    public static var LinearSRGBColorSpace:String = 'srgb-linear';
    public static var DisplayP3ColorSpace:String = 'display-p3';
    public static var LinearDisplayP3ColorSpace:String = 'display-p3-linear';

    public static var LinearTransfer:String = 'linear';
    public static var SRGBTransfer:String = 'srgb';

    public static var Rec709Primaries:String = 'rec709';
    public static var P3Primaries:String = 'p3';

    public static var ZeroStencilOp = 0;
    public static var KeepStencilOp = 7680;
    public static var ReplaceStencilOp = 7681;
    public static var IncrementStencilOp = 7682;
    public static var DecrementStencilOp = 7683;
    public static var IncrementWrapStencilOp = 34055;
    public static var DecrementWrapStencilOp = 34056;
    public static var InvertStencilOp = 5386;

    public static var NeverStencilFunc = 512;
    public static var LessStencilFunc = 513;
    public static var EqualStencilFunc = 514;
    public static var LessEqualStencilFunc = 515;
    public static var GreaterStencilFunc = 516;
    public static var NotEqualStencilFunc = 517;
    public static var GreaterEqualStencilFunc = 518;
    public static var AlwaysStencilFunc = 519;

    public static var NeverCompare = 512;
    public static var LessCompare = 513;
    public static var EqualCompare = 514;
    public static var LessEqualCompare = 515;
    public static var GreaterCompare = 516;
    public static var NotEqualCompare = 517;
    public static var GreaterEqualCompare = 518;
    public static var AlwaysCompare = 519;

    public static var StaticDrawUsage = 35044;
    public static var DynamicDrawUsage = 35048;
    public static var StreamDrawUsage = 35040;
    public static var StaticReadUsage = 35045;
    public static var DynamicReadUsage = 35049;
    public static var StreamReadUsage = 35041;
    public static var StaticCopyUsage = 35046;
    public static var DynamicCopyUsage = 35050;
    public static var StreamCopyUsage = 35042;

    public static var GLSL1:String = '100';
    public static var GLSL3:String = '300 es';

    public static var WebGLCoordinateSystem = 2000;
    public static var WebGPUCoordinateSystem = 2001;
}