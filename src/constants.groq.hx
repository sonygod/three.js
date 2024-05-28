@:final class Constants {
    public static inline var REVISION:String = '165dev';

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

    public static inline var CullFaceNone:Int = 0;
    public static inline var CullFaceBack:Int = 1;
    public static inline var CullFaceFront:Int = 2;
    public static inline var CullFaceFrontBack:Int = 3;

    public static inline var BasicShadowMap:Int = 0;
    public static inline var PCFShadowMap:Int = 1;
    public static inline var PCFSoftShadowMap:Int = 2;
    public static inline var VSMShadowMap:Int = 3;

    public static inline var FrontSide:Int = 0;
    public static inline var BackSide:Int = 1;
    public static inline var DoubleSide:Int = 2;

    public static inline var NoBlending:Int = 0;
    public static inline var NormalBlending:Int = 1;
    public static inline var AdditiveBlending:Int = 2;
    public static inline var SubtractiveBlending:Int = 3;
    public static inline var MultiplyBlending:Int = 4;
    public static inline var CustomBlending:Int = 5;

    public static inline var AddEquation:Int = 100;
    public static inline var SubtractEquation:Int = 101;
    public static inline var ReverseSubtractEquation:Int = 102;
    public static inline var MinEquation:Int = 103;
    public static inline var MaxEquation:Int = 104;

    public static inline var ZeroFactor:Int = 200;
    public static inline var OneFactor:Int = 201;
    public static inline var SrcColorFactor:Int = 202;
    public static inline var OneMinusSrcColorFactor:Int = 203;
    public static inline var SrcAlphaFactor:Int = 204;
    public static inline var OneMinusSrcAlphaFactor:Int = 205;
    public static inline var DstAlphaFactor:Int = 206;
    public static inline var OneMinusDstAlphaFactor:Int = 207;
    public static inline var DstColorFactor:Int = 208;
    public static inline var OneMinusDstColorFactor:Int = 209;
    public static inline var SrcAlphaSaturateFactor:Int = 210;
    public static inline var ConstantColorFactor:Int = 211;
    public static inline var OneMinusConstantColorFactor:Int = 212;
    public static inline var ConstantAlphaFactor:Int = 213;
    public static inline var OneMinusConstantAlphaFactor:Int = 214;

    public static inline var NeverDepth:Int = 0;
    public static inline var AlwaysDepth:Int = 1;
    public static inline var LessDepth:Int = 2;
    public static inline var LessEqualDepth:Int = 3;
    public static inline var EqualDepth:Int = 4;
    public static inline var GreaterEqualDepth:Int = 5;
    public static inline var GreaterDepth:Int = 6;
    public static inline var NotEqualDepth:Int = 7;

    public static inline var MultiplyOperation:Int = 0;
    public static inline var MixOperation:Int = 1;
    public static inline var AddOperation:Int = 2;

    public static inline var NoToneMapping:Int = 0;
    public static inline var LinearToneMapping:Int = 1;
    public static inline var ReinhardToneMapping:Int = 2;
    public static inline var CineonToneMapping:Int = 3;
    public static inline var ACESFilmicToneMapping:Int = 4;
    public static inline var CustomToneMapping:Int = 5;
    public static inline var AgXToneMapping:Int = 6;
    public static inline var NeutralToneMapping:Int = 7;

    public static inline var AttachedBindMode:String = 'attached';
    public static inline var DetachedBindMode:String = 'detached';

    public static inline var UVMapping:Int = 300;
    public static inline var CubeReflectionMapping:Int = 301;
    public static inline var CubeRefractionMapping:Int = 302;
    public static inline var EquirectangularReflectionMapping:Int = 303;
    public static inline var EquirectangularRefractionMapping:Int = 304;
    public static inline var CubeUVReflectionMapping:Int = 306;

    public static inline var RepeatWrapping:Int = 1000;
    public static inline var ClampToEdgeWrapping:Int = 1001;
    public static inline var MirroredRepeatWrapping:Int = 1002;

    public static inline var NearestFilter:Int = 1003;
    public static inline var NearestMipmapNearestFilter:Int = 1004;
    public static inline var NearestMipMapNearestFilter:Int = 1004;
    public static inline var NearestMipmapLinearFilter:Int = 1005;
    public static inline var NearestMipMapLinearFilter:Int = 1005;
    public static inline var LinearFilter:Int = 1006;
    public static inline var LinearMipmapNearestFilter:Int = 1007;
    public static inline var LinearMipMapNearestFilter:Int = 1007;
    public static inline var LinearMipmapLinearFilter:Int = 1008;
    public static inline var LinearMipMapLinearFilter:Int = 1008;

    public static inline var UnsignedByteType:Int = 1009;
    public static inline var ByteType:Int = 1010;
    public static inline var ShortType:Int = 1011;
    public static inline var UnsignedShortType:Int = 1012;
    public static inline var IntType:Int = 1013;
    public static inline var UnsignedIntType:Int = 1014;
    public static inline var FloatType:Int = 1015;
    public static inline var HalfFloatType:Int = 1016;
    public static inline var UnsignedShort4444Type:Int = 1017;
    public static inline var UnsignedShort5551Type:Int = 1018;
    public static inline var UnsignedInt248Type:Int = 1020;
    public static inline var UnsignedInt5999Type:Int = 35902;

    public static inline var AlphaFormat:Int = 1021;
    public static inline var RGBFormat:Int = 1022;
    public static inline var RGBAFormat:Int = 1023;
    public static inline var LuminanceFormat:Int = 1024;
    public static inline var LuminanceAlphaFormat:Int = 1025;
    public static inline var DepthFormat:Int = 1026;
    public static inline var DepthStencilFormat:Int = 1027;
    public static inline var RedFormat:Int = 1028;
    public static inline var RedIntegerFormat:Int = 1029;
    public static inline var RGFormat:Int = 1030;
    public static inline var RGIntegerFormat:Int = 1031;
    public static inline var RGBAIntegerFormat:Int = 1033;

    public static inline var RGB_S3TC_DXT1_Format:Int = 33776;
    public static inline var RGBA_S3TC_DXT1_Format:Int = 33777;
    public static inline var RGBA_S3TC_DXT3_Format:Int = 33778;
    public static inline var RGBA_S3TC_DXT5_Format:Int = 33779;

    public static inline var RGB_PVRTC_4BPPV1_Format:Int = 35840;
    public static inline var RGB_PVRTC_2BPPV1_Format:Int = 35841;
    public static inline var RGBA_PVRTC_4BPPV1_Format:Int = 35842;
    public static inline var RGBA_PVRTC_2BPPV1_Format:Int = 35843;

    public static inline var RGB_ETC1_Format:Int = 36196;
    public static inline var RGB_ETC2_Format:Int = 37492;
    public static inline var RGBA_ETC2_EAC_Format:Int = 37496;

    public static inline var RGBA_ASTC_4x4_Format:Int = 37808;
    public static inline var RGBA_ASTC_5x4_Format:Int = 37809;
    public static inline var RGBA_ASTC_5x5_Format:Int = 37810;
    public static inline var RGBA_ASTC_6x5_Format:Int = 37811;
    public static inline var RGBA_ASTC_6x6_Format:Int = 37812;
    public static inline var RGBA_ASTC_8x5_Format:Int = 37813;
    public static inline var RGBA_ASTC_8x6_Format:Int = 37814;
    public static inline var RGBA_ASTC_8x8_Format:Int = 37815;
    public static inline var RGBA_ASTC_10x5_Format:Int = 37816;
    public static inline var RGBA_ASTC_10x6_Format:Int = 37817;
    public static inline var RGBA_ASTC_10x8_Format:Int = 37818;
    public static inline var RGBA_ASTC_10x10_Format:Int = 37819;
    public static inline var RGBA_ASTC_12x10_Format:Int = 37820;
    public static inline var RGBA_ASTC_12x12_Format:Int = 37821;

    public static inline var RGBA_BPTC_Format:Int = 36492;
    public static inline var RGB_BPTC_SIGNED_Format:Int = 36494;
    public static inline var RGB_BPTC_UNSIGNED_Format:Int = 36495;

    public static inline var RED_RGTC1_Format:Int = 36283;
    public static inline var SIGNED_RED_RGTC1_Format:Int = 36284;
    public static inline var RED_GREEN_RGTC2_Format:Int = 36285;
    public static inline var SIGNED_RED_GREEN_RGTC2_Format:Int = 36286;

    public static inline var LoopOnce:Int = 2200;
    public static inline var LoopRepeat:Int = 2201;
    public static inline var LoopPingPong:Int = 2202;

    public static inline var InterpolateDiscrete:Int = 2300;
    public static inline var InterpolateLinear:Int = 2301;
    public static inline var InterpolateSmooth:Int = 2302;

    public static inline var ZeroCurvatureEnding:Int = 2400;
    public static inline var ZeroSlopeEnding:Int = 2401;
    public static inline var WrapAroundEnding:Int = 2402;

    public static inline var NormalAnimationBlendMode:Int = 2500;
    public static inline var AdditiveAnimationBlendMode:Int = 2501;

    public static inline var TrianglesDrawMode:Int = 0;
    public static inline var TriangleStripDrawMode:Int = 1;
    public static inline var TriangleFanDrawMode:Int = 2;

    public static inline var BasicDepthPacking:Int = 3200;
    public static inline var RGBADepthPacking:Int = 3201;

    public static inline var TangentSpaceNormalMap:Int = 0;
    public static inline var ObjectSpaceNormalMap:Int = 1;

    public static inline var NoColorSpace:String = '';
    public static inline var SRGBColorSpace:String = 'srgb';
    public static inline var LinearSRGBColorSpace:String = 'srgb-linear';
    public static inline var DisplayP3ColorSpace:String = 'display-p3';
    public static inline var LinearDisplayP3ColorSpace:String = 'display-p3-linear';

    public static inline var LinearTransfer:String = 'linear';
    public static inline var SRGBTransfer:String = 'srgb';

    public static inline var Rec709Primaries:String = 'rec709';
    public static inline var P3Primaries:String = 'p3';

    public static inline var ZeroStencilOp:Int = 0;
    public static inline var KeepStencilOp:Int = 7680;
    public static inline var ReplaceStencilOp:Int = 7681;
    public static inline var IncrementStencilOp:Int = 7682;
    public static inline var DecrementStencilOp:Int = 7683;
    public static inline var IncrementWrapStencilOp:Int = 34055;
    public static inline var DecrementWrapStencilOp:Int = 34056;
    public static inline var InvertStencilOp:Int = 5386;

    public static inline var NeverStencilFunc:Int = 512;
    public static inline var LessStencilFunc:Int = 513;
    public static inline var EqualStencilFunc:Int = 514;
    public static inline var LessEqualStencilFunc:Int = 515;
    public static inline var GreaterStencilFunc:Int = 516;
    public static inline var NotEqualStencilFunc:Int = 517;
    public static inline var GreaterEqualStencilFunc:Int = 518;
    public static inline var AlwaysStencilFunc:Int = 519;

    public static inline var NeverCompare:Int = 512;
    public static inline var LessCompare:Int = 513;
    public static inline var EqualCompare:Int = 514;
    public static inline var LessEqualCompare:Int = 515;
    public static inline var GreaterCompare:Int = 516;
    public static inline var NotEqualCompare:Int = 517;
    public static inline var GreaterEqualCompare:Int = 518;
    public static inline var AlwaysCompare:Int = 519;

    public static inline var StaticDrawUsage:Int = 35044;
    public static inline var DynamicDrawUsage:Int = 35048;
    public static inline var StreamDrawUsage:Int = 35040;
    public static inline var StaticReadUsage:Int = 35045;
    public static inline var DynamicReadUsage:Int = 35049;
    public static inline var StreamReadUsage:Int = 35041;
    public static inline var StaticCopyUsage:Int = 35046;
    public static inline var DynamicCopyUsage:Int = 35050;
    public static inline var StreamCopyUsage:Int = 35042;

    public static inline var GLSL1:String = '100';
    public static inline var GLSL3:String = '300 es';

    public static inline var WebGLCoordinateSystem:Int = 2000;
    public static inline var WebGPUCoordinateSystem:Int = 2001;
}