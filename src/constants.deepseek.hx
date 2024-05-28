enum REVISION {
    Revision('165dev');
}

enum MOUSE {
    LEFT(0);
    MIDDLE(1);
    RIGHT(2);
    ROTATE(0);
    DOLLY(1);
    PAN(2);
}

enum TOUCH {
    ROTATE(0);
    PAN(1);
    DOLLY_PAN(2);
    DOLLY_ROTATE(3);
}

enum CullFace {
    None(0);
    Back(1);
    Front(2);
    FrontBack(3);
}

enum ShadowMap {
    Basic(0);
    PCF(1);
    PCFSoft(2);
    VSM(3);
}

enum Side {
    Front(0);
    Back(1);
    Double(2);
}

enum Blending {
    No(0);
    Normal(1);
    Additive(2);
    Subtractive(3);
    Multiply(4);
    Custom(5);
}

enum Equation {
    Add(100);
    Subtract(101);
    ReverseSubtract(102);
    Min(103);
    Max(104);
}

enum Factor {
    Zero(200);
    One(201);
    SrcColor(202);
    OneMinusSrcColor(203);
    SrcAlpha(204);
    OneMinusSrcAlpha(205);
    DstAlpha(206);
    OneMinusDstAlpha(207);
    DstColor(208);
    OneMinusDstColor(209);
    SrcAlphaSaturate(210);
    ConstantColor(211);
    OneMinusConstantColor(212);
    ConstantAlpha(213);
    OneMinusConstantAlpha(214);
}

enum Depth {
    Never(0);
    Always(1);
    Less(2);
    LessEqual(3);
    Equal(4);
    GreaterEqual(5);
    Greater(6);
    NotEqual(7);
}

enum Operation {
    Multiply(0);
    Mix(1);
    Add(2);
}

enum ToneMapping {
    No(0);
    Linear(1);
    Reinhard(2);
    Cineon(3);
    ACESFilmic(4);
    Custom(5);
    AgX(6);
    Neutral(7);
}

enum BindMode {
    Attached('attached');
    Detached('detached');
}

enum Mapping {
    UVMapping(300);
    CubeReflectionMapping(301);
    CubeRefractionMapping(302);
    EquirectangularReflectionMapping(303);
    EquirectangularRefractionMapping(304);
    CubeUVReflectionMapping(306);
}

enum Wrapping {
    Repeat(1000);
    ClampToEdge(1001);
    MirroredRepeat(1002);
}

enum Filter {
    Nearest(1003);
    NearestMipmapNearest(1004);
    NearestMipMapNearest(1004);
    NearestMipmapLinear(1005);
    NearestMipMapLinear(1005);
    Linear(1006);
    LinearMipmapNearest(1007);
    LinearMipMapNearest(1007);
    LinearMipmapLinear(1008);
    LinearMipMapLinear(1008);
}

enum Type {
    UnsignedByte(1009);
    Byte(1010);
    Short(1011);
    UnsignedShort(1012);
    Int(1013);
    UnsignedInt(1014);
    Float(1015);
    HalfFloat(1016);
    UnsignedShort4444(1017);
    UnsignedShort5551(1018);
    UnsignedInt248(1020);
    UnsignedInt5999(35902);
}

enum Format {
    Alpha(1021);
    RGB(1022);
    RGBA(1023);
    Luminance(1024);
    LuminanceAlpha(1025);
    Depth(1026);
    DepthStencil(1027);
    Red(1028);
    RedInteger(1029);
    RG(1030);
    RGInteger(1031);
    RGBAInteger(1033);
}

enum CompressedTextureFormat {
    RGB_S3TC_DXT1(33776);
    RGBA_S3TC_DXT1(33777);
    RGBA_S3TC_DXT3(33778);
    RGBA_S3TC_DXT5(33779);
    RGB_PVRTC_4BPPV1(35840);
    RGB_PVRTC_2BPPV1(35841);
    RGBA_PVRTC_4BPPV1(35842);
    RGBA_PVRTC_2BPPV1(35843);
    RGB_ETC1(36196);
    RGB_ETC2(37492);
    RGBA_ETC2_EAC(37496);
    RGBA_ASTC_4x4(37808);
    RGBA_ASTC_5x4(37809);
    RGBA_ASTC_5x5(37810);
    RGBA_ASTC_6x5(37811);
    RGBA_ASTC_6x6(37812);
    RGBA_ASTC_8x5(37813);
    RGBA_ASTC_8x6(37814);
    RGBA_ASTC_8x8(37815);
    RGBA_ASTC_10x5(37816);
    RGBA_ASTC_10x6(37817);
    RGBA_ASTC_10x8(37818);
    RGBA_ASTC_10x10(37819);
    RGBA_ASTC_12x10(37820);
    RGBA_ASTC_12x12(37821);
    RGBA_BPTC(36492);
    RGB_BPTC_SIGNED(36494);
    RGB_BPTC_UNSIGNED(36495);
    RED_RGTC1(36283);
    SIGNED_RED_RGTC1(36284);
    RED_GREEN_RGTC2(36285);
    SIGNED_RED_GREEN_RGTC2(36286);
}

enum AnimationMode {
    Normal(2500);
    Additive(2501);
}

enum DrawMode {
    Triangles(0);
    TriangleStrip(1);
    TriangleFan(2);
}

enum DepthPacking {
    Basic(3200);
    RGBADepth(3201);
}

enum NormalMap {
    TangentSpace(0);
    ObjectSpace(1);
}

enum ColorSpace {
    NoColorSpace('');
    SRGB('srgb');
    LinearSRGB('srgb-linear');
    DisplayP3('display-p3');
    LinearDisplayP3('display-p3-linear');
}

enum Transfer {
    Linear('linear');
    SRGB('srgb');
}

enum Primaries {
    Rec709('rec709');
    P3('p3');
}

enum StencilOp {
    Zero(0);
    Keep(7680);
    Replace(7681);
    Increment(7682);
    Decrement(7683);
    IncrementWrap(34055);
    DecrementWrap(34056);
    Invert(5386);
}

enum StencilFunc {
    Never(512);
    Less(513);
    Equal(514);
    LessEqual(515);
    Greater(516);
    NotEqual(517);
    GreaterEqual(518);
    Always(519);
}

enum Compare {
    Never(512);
    Less(513);
    Equal(514);
    LessEqual(515);
    Greater(516);
    NotEqual(517);
    GreaterEqual(518);
    Always(519);
}

enum Usage {
    StaticDraw(35044);
    DynamicDraw(35048);
    StreamDraw(35040);
    StaticRead(35045);
    DynamicRead(35049);
    StreamRead(35041);
    StaticCopy(35046);
    DynamicCopy(35050);
    StreamCopy(35042);
}

enum GLSL {
    GLSL1('100');
    GLSL3('300 es');
}

enum CoordinateSystem {
    WebGL(2000);
    WebGPU(2001);
}