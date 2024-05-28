import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import open

class MyShader {
	public static var code:String =
		"#if NUM_SPOT_LIGHT_COORDS > 0 \n" +
		"uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ]; \n" +
		"varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ]; \n" +
		"#endif \n" +
		"#ifdef USE_SHADOWMAP \n" +
		"#if NUM_DIR_LIGHT_SHADOWS > 0 \n" +
		"uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ]; \n" +
		"varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ]; \n" +
		"struct DirectionalLightShadow { \n" +
		"float shadowBias; \n" +
		"float shadowNormalBias; \n" +
		"float shadowRadius; \n" +
		"vec2 shadowMapSize; \n" +
		"} \n" +
		"uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ]; \n" +
		"#endif \n" +
		"#if NUM_SPOT_LIGHT_SHADOWS > 0 \n" +
		"struct SpotLightShadow { \n" +
		"float shadowBias; \n" +
		"float shadowNormalBias; \n" +
		"float shadowRadius; \n" +
		"vec2 shadowMapSize; \n" +
		"} \n" +
		"uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ]; \n" +
		"#endif \n" +
		"#if NUM_POINT_LIGHT_SHADOWS > 0 \n" +
		"uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ]; \n" +
		"varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ]; \n" +
		"struct PointLightShadow { \n" +
		"float shadowBias; \n" +
		"float shadowNormalBias; \n" +
		"float shadowRadius; \n" +
		"vec2 shadowMapSize; \n" +
		"float shadowCameraNear; \n" +
		"float shadowCameraFar; \n" +
		"} \n" +
		"uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ]; \n" +
		"#endif";
}