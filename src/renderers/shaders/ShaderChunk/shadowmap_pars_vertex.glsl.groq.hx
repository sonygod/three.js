package three.shader;

#if js

#elseif haxe

import haxe.macro.Expr;

#end

class ShadowmapParsVertex {
    #if (NUM_SPOT_LIGHT_COORDS > 0)

    @:uniform var spotLightMatrix:Array<Mat4> = [for (i in 0...NUM_SPOT_LIGHT_COORDS) Mat4.identity()];
    @:varying var vSpotLightCoord:Array<Vec4> = [for (i in 0...NUM_SPOT_LIGHT_COORDS) Vec4.zero()];

    #end

    #ifdef USE_SHADOWMAP

    #if (NUM_DIR_LIGHT_SHADOWS > 0)

    @:uniform var directionalShadowMatrix:Array<Mat4> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) Mat4.identity()];
    @:varying var vDirectionalShadowCoord:Array<Vec4> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) Vec4.zero()];

    struct DirectionalLightShadow {
        var shadowBias:Float;
        var shadowNormalBias:Float;
        var shadowRadius:Float;
        var shadowMapSize:Vec2;
    }

    @:uniform var directionalLightShadows:Array<DirectionalLightShadow> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
        shadowBias: 0.0,
        shadowNormalBias: 0.0,
        shadowRadius: 0.0,
        shadowMapSize: Vec2.zero()
    }];

    #end

    #if (NUM_SPOT_LIGHT_SHADOWS > 0)

    struct SpotLightShadow {
        var shadowBias:Float;
        var shadowNormalBias:Float;
        var shadowRadius:Float;
        var shadowMapSize:Vec2;
    }

    @:uniform var spotLightShadows:Array<SpotLightShadow> = [for (i in 0...NUM_SPOT_LIGHT_SHADOWS) {
        shadowBias: 0.0,
        shadowNormalBias: 0.0,
        shadowRadius: 0.0,
        shadowMapSize: Vec2.zero()
    }];

    #end

    #if (NUM_POINT_LIGHT_SHADOWS > 0)

    @:uniform var pointShadowMatrix:Array<Mat4> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) Mat4.identity()];
    @:varying var vPointShadowCoord:Array<Vec4> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) Vec4.zero()];

    struct PointLightShadow {
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
        shadowMapSize: Vec2.zero(),
        shadowCameraNear: 0.0,
        shadowCameraFar: 0.0
    }];

    #end

    #/*
    #if (NUM_RECT_AREA_LIGHTS > 0)

    // TODO (abelnation): uniforms for area light shadows

    #end
    */

    #end
}