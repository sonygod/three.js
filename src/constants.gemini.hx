class Constants {
  public static final REVISION:String = "165dev";

  public static final MOUSE = {
    LEFT: 0,
    MIDDLE: 1,
    RIGHT: 2,
    ROTATE: 0,
    DOLLY: 1,
    PAN: 2
  };

  public static final TOUCH = {
    ROTATE: 0,
    PAN: 1,
    DOLLY_PAN: 2,
    DOLLY_ROTATE: 3
  };

  public static final CullFaceNone:Int = 0;
  public static final CullFaceBack:Int = 1;
  public static final CullFaceFront:Int = 2;
  public static final CullFaceFrontBack:Int = 3;

  public static final BasicShadowMap:Int = 0;
  public static final PCFShadowMap:Int = 1;
  public static final PCFSoftShadowMap:Int = 2;
  public static final VSMShadowMap:Int = 3;

  public static final FrontSide:Int = 0;
  public static final BackSide:Int = 1;
  public static final DoubleSide:Int = 2;

  public static final NoBlending:Int = 0;
  public static final NormalBlending:Int = 1;
  public static final AdditiveBlending:Int = 2;
  public static final SubtractiveBlending:Int = 3;
  public static final MultiplyBlending:Int = 4;
  public static final CustomBlending:Int = 5;

  public static final AddEquation:Int = 100;
  public static final SubtractEquation:Int = 101;
  public static final ReverseSubtractEquation:Int = 102;
  public static final MinEquation:Int = 103;
  public static final MaxEquation:Int = 104;

  public static final ZeroFactor:Int = 200;
  public static final OneFactor:Int = 201;
  public static final SrcColorFactor:Int = 202;
  public static final OneMinusSrcColorFactor:Int = 203;
  public static final SrcAlphaFactor:Int = 204;
  public static final OneMinusSrcAlphaFactor:Int = 205;
  public static final DstAlphaFactor:Int = 206;
  public static final OneMinusDstAlphaFactor:Int = 207;
  public static final DstColorFactor:Int = 208;
  public static final OneMinusDstColorFactor:Int = 209;
  public static final SrcAlphaSaturateFactor:Int = 210;
  public static final ConstantColorFactor:Int = 211;
  public static final OneMinusConstantColorFactor:Int = 212;
  public static final ConstantAlphaFactor:Int = 213;
  public static final OneMinusConstantAlphaFactor:Int = 214;

  public static final NeverDepth:Int = 0;
  public static final AlwaysDepth:Int = 1;
  public static final LessDepth:Int = 2;
  public static final LessEqualDepth:Int = 3;
  public static final EqualDepth:Int = 4;
  public static final GreaterEqualDepth:Int = 5;
  public static final GreaterDepth:Int = 6;
  public static final NotEqualDepth:Int = 7;

  public static final MultiplyOperation:Int = 0;
  public static final MixOperation:Int = 1;
  public static final AddOperation:Int = 2;

  public static final NoToneMapping:Int = 0;
  public static final LinearToneMapping:Int = 1;
  public static final ReinhardToneMapping:Int = 2;
  public static final CineonToneMapping:Int = 3;
  public static final ACESFilmicToneMapping:Int = 4;
  public static final CustomToneMapping:Int = 5;
  public static final AgXToneMapping:Int = 6;
  public static final NeutralToneMapping:Int = 7;

  public static final AttachedBindMode:String = "attached";
  public static final DetachedBindMode:String = "detached";

  public static final UVMapping:Int = 300;
  public static final CubeReflectionMapping:Int = 301;
  public static final CubeRefractionMapping:Int = 302;
  public static final EquirectangularReflectionMapping:Int = 303;
  public static final EquirectangularRefractionMapping:Int = 304;
  public static final CubeUVReflectionMapping:Int = 306;

  public static final RepeatWrapping:Int = 1000;
  public static final ClampToEdgeWrapping:Int = 1001;
  public static final MirroredRepeatWrapping:Int = 1002;

  public static final NearestFilter:Int = 1003;
  public static final NearestMipmapNearestFilter:Int = 1004;
  public static final NearestMipmapLinearFilter:Int = 1005;
  public static final LinearFilter:Int = 1006;
  public static final LinearMipmapNearestFilter:Int = 1007;
  public static final LinearMipmapLinearFilter:Int = 1008;

  public static final UnsignedByteType:Int = 1009;
  public static final ByteType:Int = 1010;
  public static final ShortType:Int = 1011;
  public static final UnsignedShortType:Int = 1012;
  public static final IntType:Int = 1013;
  public static final UnsignedIntType:Int = 1014;
  public static final FloatType:Int = 1015;
  public static final HalfFloatType:Int = 1016;
  public static final UnsignedShort4444Type:Int = 1017;
  public static final UnsignedShort5551Type:Int = 1018;
  public static final UnsignedInt248Type:Int = 1020;
  public static final UnsignedInt5999Type:Int = 35902;

  public static final AlphaFormat:Int = 1021;
  public static final RGBFormat:Int = 1022;
  public static final RGBAFormat:Int = 1023;
  public static final LuminanceFormat:Int = 1024;
  public static final LuminanceAlphaFormat:Int = 1025;
  public static final DepthFormat:Int = 1026;
  public static final DepthStencilFormat:Int = 1027;
  public static final RedFormat:Int = 1028;
  public static final RedIntegerFormat:Int = 1029;
  public static final RGFormat:Int = 1030;
  public static final RGIntegerFormat:Int = 1031;
  public static final RGBAIntegerFormat:Int = 1033;

  public static final RGB_S3TC_DXT1_Format:Int = 33776;
  public static final RGBA_S3TC_DXT1_Format:Int = 33777;
  public static final RGBA_S3TC_DXT3_Format:Int = 33778;
  public static final RGBA_S3TC_DXT5_Format:Int = 33779;

  public static final RGB_PVRTC_4BPPV1_Format:Int = 35840;
  public static final RGB_PVRTC_2BPPV1_Format:Int = 35841;
  public static final RGBA_PVRTC_4BPPV1_Format:Int = 35842;
  public static final RGBA_PVRTC_2BPPV1_Format:Int = 35843;

  public static final RGB_ETC1_Format:Int = 36196;
  public static final RGB_ETC2_Format:Int = 37492;
  public static final RGBA_ETC2_EAC_Format:Int = 37496;

  public static final RGBA_ASTC_4x4_Format:Int = 37808;
  public static final RGBA_ASTC_5x4_Format:Int = 37809;
  public static final RGBA_ASTC_5x5_Format:Int = 37810;
  public static final RGBA_ASTC_6x5_Format:Int = 37811;
  public static final RGBA_ASTC_6x6_Format:Int = 37812;
  public static final RGBA_ASTC_8x5_Format:Int = 37813;
  public static final RGBA_ASTC_8x6_Format:Int = 37814;
  public static final RGBA_ASTC_8x8_Format:Int = 37815;
  public static final RGBA_ASTC_10x5_Format:Int = 37816;
  public static final RGBA_ASTC_10x6_Format:Int = 37817;
  public static final RGBA_ASTC_10x8_Format:Int = 37818;
  public static final RGBA_ASTC_10x10_Format:Int = 37819;
  public static final RGBA_ASTC_12x10_Format:Int = 37820;
  public static final RGBA_ASTC_12x12_Format:Int = 37821;

  public static final RGBA_BPTC_Format:Int = 36492;
  public static final RGB_BPTC_SIGNED_Format:Int = 36494;
  public static final RGB_BPTC_UNSIGNED_Format:Int = 36495;

  public static final RED_RGTC1_Format:Int = 36283;
  public static final SIGNED_RED_RGTC1_Format:Int = 36284;
  public static final RED_GREEN_RGTC2_Format:Int = 36285;
  public static final SIGNED_RED_GREEN_RGTC2_Format:Int = 36286;

  public static final LoopOnce:Int = 2200;
  public static final LoopRepeat:Int = 2201;
  public static final LoopPingPong:Int = 2202;

  public static final InterpolateDiscrete:Int = 2300;
  public static final InterpolateLinear:Int = 2301;
  public static final InterpolateSmooth:Int = 2302;

  public static final ZeroCurvatureEnding:Int = 2400;
  public static final ZeroSlopeEnding:Int = 2401;
  public static final WrapAroundEnding:Int = 2402;

  public static final NormalAnimationBlendMode:Int = 2500;
  public static final AdditiveAnimationBlendMode:Int = 2501;

  public static final TrianglesDrawMode:Int = 0;
  public static final TriangleStripDrawMode:Int = 1;
  public static final TriangleFanDrawMode:Int = 2;

  public static final BasicDepthPacking:Int = 3200;
  public static final RGBADepthPacking:Int = 3201;

  public static final TangentSpaceNormalMap:Int = 0;
  public static final ObjectSpaceNormalMap:Int = 1;

  // Color space string identifiers, matching CSS Color Module Level 4 and WebGPU names where available.
  public static final NoColorSpace:String = "";
  public static final SRGBColorSpace:String = "srgb";
  public static final LinearSRGBColorSpace:String = "srgb-linear";
  public static final DisplayP3ColorSpace:String = "display-p3";
  public static final LinearDisplayP3ColorSpace:String = "display-p3-linear";

  public static final LinearTransfer:String = "linear";
  public static final SRGBTransfer:String = "srgb";

  public static final Rec709Primaries:String = "rec709";
  public static final P3Primaries:String = "p3";

  public static final ZeroStencilOp:Int = 0;
  public static final KeepStencilOp:Int = 7680;
  public static final ReplaceStencilOp:Int = 7681;
  public static final IncrementStencilOp:Int = 7682;
  public static final DecrementStencilOp:Int = 7683;
  public static final IncrementWrapStencilOp:Int = 34055;
  public static final DecrementWrapStencilOp:Int = 34056;
  public static final InvertStencilOp:Int = 5386;

  public static final NeverStencilFunc:Int = 512;
  public static final LessStencilFunc:Int = 513;
  public static final EqualStencilFunc:Int = 514;
  public static final LessEqualStencilFunc:Int = 515;
  public static final GreaterStencilFunc:Int = 516;
  public static final NotEqualStencilFunc:Int = 517;
  public static final GreaterEqualStencilFunc:Int = 518;
  public static final AlwaysStencilFunc:Int = 519;

  public static final NeverCompare:Int = 512;
  public static final LessCompare:Int = 513;
  public static final EqualCompare:Int = 514;
  public static final LessEqualCompare:Int = 515;
  public static final GreaterCompare:Int = 516;
  public static final NotEqualCompare:Int = 517;
  public static final GreaterEqualCompare:Int = 518;
  public static final AlwaysCompare:Int = 519;

  public static final StaticDrawUsage:Int = 35044;
  public static final DynamicDrawUsage:Int = 35048;
  public static final StreamDrawUsage:Int = 35040;
  public static final StaticReadUsage:Int = 35045;
  public static final DynamicReadUsage:Int = 35049;
  public static final StreamReadUsage:Int = 35041;
  public static final StaticCopyUsage:Int = 35046;
  public static final DynamicCopyUsage:Int = 35050;
  public static final StreamCopyUsage:Int = 35042;

  public static final GLSL1:String = "100";
  public static final GLSL3:String = "300 es";

  public static final WebGLCoordinateSystem:Int = 2000;
  public static final WebGPUCoordinateSystem:Int = 2001;
}


This Haxe code defines a class `Constants` that encapsulates all the constants from the original JavaScript code. This is a more structured approach in Haxe compared to the loose `export` statements in JavaScript. 

This Haxe code can be used by referencing the `Constants` class and accessing its static fields:


class Main {
  static function main() {
    trace(Constants.REVISION);
    trace(Constants.MOUSE.LEFT);
    trace(Constants.UnsignedInt5999Type);
  }
}