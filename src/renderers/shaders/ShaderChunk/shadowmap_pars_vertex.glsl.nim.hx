package three.js.src.renderers.shaders.ShaderChunk;

#if NUM_SPOT_LIGHT_COORDS > 0

	@:uniform("mat4") var spotLightMatrix:Array<Float32Array>;
	@:varying("vec4") var vSpotLightCoord:Array<Float32Array>;

#end

#if USE_SHADOWMAP

	#if NUM_DIR_LIGHT_SHADOWS > 0

		@:uniform("mat4") var directionalShadowMatrix:Array<Float32Array>;
		@:varying("vec4") var vDirectionalShadowCoord:Array<Float32Array>;

		typedef DirectionalLightShadow = {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
		};

		@:uniform("DirectionalLightShadow") var directionalLightShadows:Array<DirectionalLightShadow>;

	#end

	#if NUM_SPOT_LIGHT_SHADOWS > 0

		typedef SpotLightShadow = {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
		};

		@:uniform("SpotLightShadow") var spotLightShadows:Array<SpotLightShadow>;

	#end

	#if NUM_POINT_LIGHT_SHADOWS > 0

		@:uniform("mat4") var pointShadowMatrix:Array<Float32Array>;
		@:varying("vec4") var vPointShadowCoord:Array<Float32Array>;

		typedef PointLightShadow = {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
			var shadowCameraNear:Float;
			var shadowCameraFar:Float;
		};

		@:uniform("PointLightShadow") var pointLightShadows:Array<PointLightShadow>;

	#end

	/*
	#if NUM_RECT_AREA_LIGHTS > 0

		// TODO (abelnation): uniforms for area light shadows

	#end
	*/

#end