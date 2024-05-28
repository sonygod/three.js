package three;

class Constants {
    public static inline var REVISION = '165dev';

    public static inline var MOUSE = {
        LEFT: 0,
        MIDDLE: 1,
        RIGHT: 2,
        ROTATE: 0,
        DOLLY: 1,
        PAN: 2
    };

    public static inline var TOUCH = {
        ROTATE: 0,
        PAN: 1,
        DOLLY_PAN: 2,
        DOLLY_ROTATE: 3
    };

    public static inline var CullFaceNone = 0;
    public static inline var CullFaceBack = 1;
    public static inline var CullFaceFront = 2;
    public static inline var CullFaceFrontBack = 3;

    public static inline var BasicShadowMap = 0;
    public static inline var PCFShadowMap = 1;
    public static inline var PCFSoftShadowMap = 2;
    public static inline var VSMShadowMap = 3;

    public static inline var FrontSide = 0;
    public static inline var BackSide = 1;
    public static inline var DoubleSide = 2;

    public static inline var NoBlending = 0;
    public static inline var NormalBlending = 1;
    public static inline var AdditiveBlending = 2;
    public static inline var SubtractiveBlending = 3;
    public static inline var MultiplyBlending = 4;
    public static inline var CustomBlending = 5;

    public static inline var AddEquation = 100;
    public static inline var SubtractEquation = 101;
    public static inline var ReverseSubtractEquation = 102;
    public static inline var MinEquation = 103;
    public static inline var MaxEquation = 104;

    public static inline var ZeroFactor = 200;
    public static inline var OneFactor = 201;
    public static inline var SrcColorFactor = 202;
    public static inline var OneMinusSrcColorFactor = 203;
    public static inline var SrcAlphaFactor = 204;
    public static inline var OneMinusSrcAlphaFactor = 205;
    public static inline var DstAlphaFactor = 206;
    public static inline var OneMinusDstAlphaFactor = 207;
    public static inline var DstColorFactor = 208;
    public static inline var OneMinusDstColorFactor = 209;
    public static inline var SrcAlphaSaturateFactor = 210;
    public static inline var ConstantColorFactor = 211;
    public static inline var OneMinusConstantColorFactor = 212;
    public static inline var ConstantAlphaFactor = 213;
    public static inline var OneMinusConstantAlphaFactor = 214;

    public static inline var NeverDepth = 0;
    public static inline var AlwaysDepth = 1;
    public static inline var LessDepth = 2;
    public static inline var LessEqualDepth = 3;
    public static inline var EqualDepth = 4;
    public static inline var GreaterEqualDepth = 5;
    public static inline var GreaterDepth = 6;
    public static inline var NotEqualDepth = 7;

    public static inline var MultiplyOperation = 0;
    public static inline var MixOperation = 1;
    public static inline var AddOperation = 2;

    public static inline var NoToneMapping = 0;
    public static inline var LinearToneMapping = 1;
    public static inline var ReinhardToneMapping = 2;
    public static inline var CineonToneMapping = 3;
    public static inline var ACESFilmicToneMapping = 4;
    public static inline var CustomToneMapping = 5;
    public static inline var AgXToneMapping = 6;
    public static inline var NeutralToneMapping = 7;

    public static inline var AttachedBindMode = 'attached';
    public static inline var DetachedBindMode = 'detached';

    public static inline var UVMapping = 300;
    public static inline var CubeReflectionMapping = 301;
    public static inline var CubeRefractionMapping = 302;
    public static inline var EquirectangularReflectionMapping = 303;
    public static inline var EquirectangularRefractionMapping = 304;
    public static inline var CubeUVReflectionMapping = 306;

    public static inline var RepeatWrapping = 1000;
    public static inline var ClampToEdgeWrapping = 1001;
    public static inline var MirroredRepeatWrapping = 1002;

    public static inline var NearestFilter = 1003;
    public static inline var NearestMipmapNearestFilter = 1004;
    public static inline var NearestMipmapLinearFilter = 1005;
    public static inline var LinearFilter = 1006;
    public static inline var LinearMipmapNearestFilter = 1007;
    public static inline var LinearMipmapLinearFilter = 1008;

    public static inline var UnsignedByteType = 1009;
    public static inline var ByteType = 1010;
    public static inline var ShortType = 1011;
    public static inline var UnsignedShortType = 1012;
    public static inline var IntType = 1013;
    public static inline var UnsignedIntType = 1014;
    public static inline var FloatType = 1015;
    public static inline var HalfFloatType = 1016;
    public static inline var UnsignedShort4444Type = 1017;
    public static inline var UnsignedShort5551Type = 1018;
    public static inline var UnsignedInt248Type = 1020;
    public static inline var UnsignedInt5999Type = 35902;

    public static inline var AlphaFormat = 1021;
    public static inline var RGBFormat = 1022;
    public static inline var RGBAFormat = 1023;
    public static inline var LuminanceFormat = 1024;
    public static inline var LuminanceAlphaFormat = 1025;
    public static inline var DepthFormat = 1026;
    public static inline var DepthStencilFormat = 1027;
    public static inline var RedFormat = 1028;
    public static inline var RedIntegerFormat = 1029;
    public static inline var RGFormat = 1030;
    public static inline var RGIntegerFormat = 1031;
    public static inline var RGBAIntegerFormat = 1033;

    public static inline var RGB_S3TC_DXT1_Format = 33776;
    public static inline var RGBA_S3TC_DXT1_Format = 33777;
    public static inline var RGBA_S3TC_DXT3_Format = 33778;
    public static inline var RGBA_S3TC_DXT5_Format = 33779;
    public static inline var RGB_PVRTC_4BPPV1_Format = 35840;
    public static inline var RGB_PVRTC_2BPPV1_Format = 35841;
    public static inline var RGBA_PVRTC_4BPPV1_Format = 35842;
    public static inline var RGBA_PVRTC_2BPPV1_Format = 35843;
    public static inline var RGB_ETC1_Format = 36196;
    public static inline var RGB_ETC2_Format = 37492;
    public static inline var RGBA_ETC2_EAC_Format = 37496;
    public static inline var RGBA_ASTC_4x4_Format = 37808;
    public static inline var RGBA_ASTC_5x4_Format = 37809;
    public static inline var RGBA_ASTC_5x5_Format = 37810;
    public static inline var RGBA_ASTC_6x5_Format = 37811;
    public static inline var RGBA_ASTC_6x6_Format = 37812;
    public static inline var RGBA_ASTC_8x5_Format = 37813;
    public static inline var RGBA_ASTC_8x6_Format = 37814;
    public static inline var RGBA_ASTC_8x8_Format = 37815;
    public static inline var RGBA_ASTC_10x5_Format = 37816;
    public static inline var RGBA_ASTC_10x6_Format = 37817;
    public static inline var RGBA_ASTC_10x8_Format = 37818;
    public static inline var RGBA_ASTC_10x10_Format = 37819;
    public static inline var RGBA_ASTC_12x10_Format = 37820;
    public static inline var RGBA_ASTC_12x12_Format = 37821;
    public static inline var RGBA_BPTC_Format = 36492;
    public static inline var RGB_BPTC_SIGNED_Format = 36494;
    public static inline var RGB_BPTC_UNSIGNED_Format = 36495;
    public static inline var RED_RGTC1_Format = 36283;
    public static inline var SIGNED_RED_RGTC1_Format = 36284;
    public static inline var RED_GREEN_RGTC2_Format = 36285;
    public static inline var SIGNED_RED_GREEN_RGTC2_Format = 36286;

    public static inline var LoopOnce = 2200;
    public static inline var LoopRepeat = 2201;
    public static inline var LoopPingPong = 2202;

    public static inline var InterpolateDiscrete = 2300;
    public static inline var InterpolateLinear = 2301;
    public static inline var InterpolateSmooth = 2302;

    public static inline var ZeroCurvatureEnding = 2400;
    public static inline var ZeroSlopeEnding = 2401;
    public static inline var WrapAroundEnding = 2402;

    public static inline var NormalAnimationBlendMode = 2500;
    public static inline var AdditiveAnimationBlendMode = 2501;

    public static inline var TrianglesDrawMode = 0;
    public static inline var TriangleStripDrawMode = 1;
    public static inline var TriangleFanDrawMode = 2;

    public static inline var BasicDepthPacking = 3200;
    public static inline var RGBADepthPacking = 3201;

    public static inline var TangentSpaceNormalMap = 0;
    public static inline var ObjectSpaceNormalMap = 1;

    public static inline var NoColorSpace = '';
    public static inline var SRGBColorSpace = 'srgb';
    public static inline var LinearSRGBColorSpace = 'srgb-linear';
    public static inline var DisplayP3ColorSpace = 'display-p3';
    public static inline var LinearDisplayP3ColorSpace = 'display-p3-linear';

    public static inline var LinearTransfer = 'linear';
    public static inline var SRGBTransfer = 'srgb';

    public static inline var Rec709Primaries = 'rec709';
    public static inline var P3Primaries = 'p3';

    public static inline var ZeroStencilOp = 0;
    public static inline var KeepStencilOp = 7680;
    public static inline var ReplaceStencilOp = 7681;
    public static inline var IncrementStencilOp = 7682;
    public static inline var DecrementStencilOp = 7683;
    public static inline var IncrementWrapStencilOp = 34055;
    public static inline var DecrementWrapStencilOp = 34056;
    public static inline var InvertStencilOp = 5386;

    public static inline var NeverStencilFunc = 512;
    public static inline var LessStencilFunc = 513;
    public static inline var EqualStencilFunc = 514;
    public static inline var LessEqualStencilFunc = 515;
    public static inline var GreaterStencilFunc = 516;
    public static inline var NotEqualStencilFunc = 517;
    public static inline var GreaterEqualStencilFunc = 518;
    public static inline var AlwaysStencilFunc = 519;

    public static inline var NeverCompare = 512;
    public static inline var LessCompare = 513;
    public static inline var EqualCompare = 514;
    public static inline var LessEqualCompare = 515;
    public static inline var GreaterCompare = 516;
    public static inline var NotEqualCompare = 517;
    public static inline var GreaterEqualCompare = 518;
    public static inline var AlwaysCompare = 519;

    public static inline var StaticDrawUsage = 35044;
    public static inline var DynamicDrawUsage = 35048;
    public static inline var StreamDrawUsage = 35040;
    public static inline var StaticReadUsage = 35045;
    public static inline var DynamicReadUsage = 35049;
    public static inline var StreamReadUsage = 35041;
    public static inline var StaticCopyUsage = 35046;
    public static inline var DynamicCopyUsage = 35050;
    public static inline var StreamCopyUsage = 35042;

    public static inline var GLSL1 = '100';
    public static inline var GLSL3 = '300 es';

    public static inline var WebGLCoordinateSystem = 2000;
    public static inline var WebGPUCoordinateSystem = 2001;
}