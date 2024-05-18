@:glsl
class ShadowmapParsVertex {
  #if NUM_SPOT_LIGHT_COORDS > 0
  @:uniform var spotLightMatrix:Array<Mat4> = [for (i in 0...NUM_SPOT_LIGHT_COORDS) mat4.create()];
  @:varying var vSpotLightCoord:Array<Vec4> = [for (i in 0...NUM_SPOT_LIGHT_COORDS) vec4.create()];
  #end

  #ifdef USE_SHADOWMAP
  #if NUM_DIR_LIGHT_SHADOWS > 0
  @:uniform var directionalShadowMatrix:Array<Mat4> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) mat4.create()];
  @:varying var vDirectionalShadowCoord:Array<Vec4> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) vec4.create()];

  typedef DirectionalLightShadow = {
    var shadowBias:Float;
    var shadowNormalBias:Float;
    var shadowRadius:Float;
    var shadowMapSize:Vec2;
  }

  @:uniform var directionalLightShadows:Array<DirectionalLightShadow> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
    shadowBias: 0.0,
    shadowNormalBias: 0.0,
    shadowRadius: 0.0,
    shadowMapSize: vec2.create()
  }];
  #end

  #if NUM_SPOT_LIGHT_SHADOWS > 0
  typedef SpotLightShadow = {
    var shadowBias:Float;
    var shadowNormalBias:Float;
    var shadowRadius:Float;
    var shadowMapSize:Vec2;
  }

  @:uniform var spotLightShadows:Array<SpotLightShadow> = [for (i in 0...NUM_SPOT_LIGHT_SHADOWS) {
    shadowBias: 0.0,
    shadowNormalBias: 0.0,
    shadowRadius: 0.0,
    shadowMapSize: vec2.create()
  }];
  #end

  #if NUM_POINT_LIGHT_SHADOWS > 0
  @:uniform var pointShadowMatrix:Array<Mat4> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) mat4.create()];
  @:varying var vPointShadowCoord:Array<Vec4> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) vec4.create()];

  typedef PointLightShadow = {
    var shadowBias:Float;
    var shadowNormalBias:Float;
    var shadowRadius:Float;
    var shadowMapSize:Vec2;
    var shadowCameraNear:Float;
    var shadowCameraFar:Float;
  }

  @:uniform var pointLightShadows:Array<PointLightShadow> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) {
    shadowBias: 0.0,
    shadowNormalBias: 0.0,
    shadowRadius: 0.0,
    shadowMapSize: vec2.create(),
    shadowCameraNear: 0.0,
    shadowCameraFar: 0.0
  }];
  #end
  #end
}