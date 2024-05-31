package three.constants;

class Constants {
    public static inline var REVISION:String = '165dev';

    public static inline var MOUSE:Dynamic = {
        LEFT: 0, MIDDLE: 1, RIGHT: 2, ROTATE: 0, DOLLY: 1, PAN: 2
    };
    public static inline var TOUCH:Dynamic = {
        ROTATE: 0, PAN: 1, DOLLY_PAN: 2, DOLLY_ROTATE: 3
    };
    public static inline var CullFaceNone:Int = 0;
    public static inline var CullFaceBack:Int = 1;
    public static inline var CullFaceFront:Int = 2;
    public static inline var CullFaceFrontBack:Int = 3;
    public static inline var BasicShadowMap:Int = 0;
    public static inline var PCFShadowMap:Int = 1;
    public static inline var PCFSoftShadowMap:Int = 2;
    // 继续列出其他常量...

    public static inline var AttachedBindMode:String = 'attached';
    public static inline var DetachedBindMode:String = 'detached';

    public static inline var UVMapping:Int = 300;
    // 继续列出其他映射类型和过滤器类型...

    // Color space string identifiers
    public static inline var NoColorSpace:String = '';
    public static inline var SRGBColorSpace:String = 'srgb';
    // 继续...

    // Stencil operations
    public static inline var ZeroStencilOp:Int = 0;
    public static inline var KeepStencilOp:Int = 7680;
    // 继续...
}