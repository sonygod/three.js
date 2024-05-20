class ShadowMapParsVertex {
    public static var NUM_SPOT_LIGHT_COORDS:Int;
    public static var spotLightMatrix(default, null):Array<Mat4>;
    public static var vSpotLightCoord(default, null):Array<Vec4>;

    public static var USE_SHADOWMAP:Bool;
    public static var NUM_DIR_LIGHT_SHADOWS:Int;
    public static var directionalShadowMatrix(default, null):Array<Mat4>;
    public static var vDirectionalShadowCoord(default, null):Array<Vec4>;

    public static var directionalLightShadows(default, null):Array<DirectionalLightShadow>;

    public static var NUM_SPOT_LIGHT_SHADOWS:Int;
    public static var spotLightShadows(default, null):Array<SpotLightShadow>;

    public static var NUM_POINT_LIGHT_SHADOWS:Int;
    public static var pointShadowMatrix(default, null):Array<Mat4>;
    public static var vPointShadowCoord(default, null):Array<Vec4>;
    public static var pointLightShadows(default, null):Array<PointLightShadow>;

    public static function new():Void {}
}

class DirectionalLightShadow {
    public var shadowBias:Float;
    public var shadowNormalBias:Float;
    public var shadowRadius:Float;
    public var shadowMapSize:Vec2;

    public function new():Void {}
}

class SpotLightShadow {
    public var shadowBias:Float;
    public var shadowNormalBias:Float;
    public var shadowRadius:Float;
    public var shadowMapSize:Vec2;

    public function new():Void {}
}

class PointLightShadow {
    public var shadowBias:Float;
    public var shadowNormalBias:Float;
    public var shadowRadius:Float;
    public var shadowMapSize:Vec2;
    public var shadowCameraNear:Float;
    public var shadowCameraFar:Float;

    public function new():Void {}
}