package renderers.shaders.ShaderChunk;

import openfl.display3D.textures.Texture;
import openfl.display3D.Context3D;

class ShadowMapParsFragment {
    // uniforms

    #if ( NUM_SPOT_LIGHT_COORDS > 0 )
    @:uniform public var vSpotLightCoord:Array<Vec4> = [];
    #end

    #if ( NUM_SPOT_LIGHT_MAPS > 0 )
    @:uniform public var spotLightMap:Array<Texture> = [];
    #end

    #ifdef USE_SHADOWMAP

        #if ( NUM_DIR_LIGHT_SHADOWS > 0 )
        @:uniform public var directionalShadowMap:Array<Texture> = [];
        @:uniform public var vDirectionalShadowCoord:Array<Vec4> = [];
        #end

        #if ( NUM_SPOT_LIGHT_SHADOWS > 0 )
        @:uniform public var spotShadowMap:Array<Texture> = [];
        #end

        #if ( NUM_POINT_LIGHT_SHADOWS > 0 )
        @:uniform public var pointShadowMap:Array<Texture> = [];
        @:uniform public var vPointShadowCoord:Array<Vec4> = [];
        #end

        // struct DirectionalLightShadow {
        //     float shadowBias;
        //     float shadowNormalBias;
        //     float shadowRadius;
        //     vec2 shadowMapSize;
        // };

        @:uniform public var directionalLightShadows:Array<DirectionalLightShadow> = [];

        // struct SpotLightShadow {
        //     float shadowBias;
        //     float shadowNormalBias;
        //     float shadowRadius;
        //     vec2 shadowMapSize;
        // };

        @:uniform public var spotLightShadows:Array<SpotLightShadow> = [];

        // struct PointLightShadow {
        //     float shadowBias;
        //     float shadowNormalBias;
        //     float shadowRadius;
        //     vec2 shadowMapSize;
        //     float shadowCameraNear;
        //     float shadowCameraFar;
        // };

        @:uniform public var pointLightShadows:Array<PointLightShadow> = [];

    #end

    inline function texture2DCompare(sampler:Texture, uv:Vec2, compare:Float):Float {
        return step(compare, unpackRGBAToDepth(texture2D(sampler, uv)));
    }

    inline function texture2DDistribution(sampler:Texture, uv:Vec2):Vec2 {
        return unpackRGBATo2Half(texture2D(sampler, uv));
    }

    inline function VSMShadow(sampler:Texture, uv:Vec2, compare:Float):Float {
        var occlusion:Float = 1.0;

        var distribution:Vec2 = texture2DDistribution(sampler, uv);

        var hardShadow:Float = step(compare, distribution.x); // Hard Shadow

        if (hardShadow != 1.0) {
            var distance:Float = compare - distribution.x;
            var variance:Float = max(0.00000, distribution.y * distribution.y);
            var softnessProbability:Float = variance / (variance + distance * distance); // Chebeyshevs inequality
            softnessProbability = clamp((softnessProbability - 0.3) / (0.95 - 0.3), 0.0, 1.0); // 0.3 reduces light bleed
            occlusion = clamp(max(hardShadow, softnessProbability), 0.0, 1.0);
        }

        return occlusion;
    }

    inline function getShadow(shadowMap:Texture, shadowMapSize:Vec2, shadowBias:Float, shadowRadius:Float, shadowCoord:Vec4):Float {
        var shadow:Float = 1.0;

        shadowCoord.xyz /= shadowCoord.w;
        shadowCoord.z += shadowBias;

        var inFrustum:Bool = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
        var frustumTest:Bool = inFrustum && shadowCoord.z <= 1.0;

        if (frustumTest) {
            #if ( SHADOWMAP_TYPE_PCF )
            var texelSize:Vec2 = Vec2(1.0) / shadowMapSize;
            var dx0:Float = -texelSize.x * shadowRadius;
            var dy0:Float = -texelSize.y * shadowRadius;
            var dx1:Float = +texelSize.x * shadowRadius;
            var dy1:Float = +texelSize.y * shadowRadius;
            var dx2:Float = dx0 / 2.0;
            var dy2:Float = dy0 / 2.0;
            var dx3:Float = dx1 / 2.0;
            var dy3:Float = dy1 / 2.0;

            shadow = (
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx0, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(0.0, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx1, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx2, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(0.0, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx3, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx0, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx2, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy, shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx3, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx1, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx2, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(0.0, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx3, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx0, dy1), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(0.0, dy1), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + Vec2(dx1, dy1), shadowCoord.z)
            ) * (1.0 / 17.0);

            #elseif ( SHADOWMAP_TYPE_PCF_SOFT )
            var texelSize:Vec2 = Vec2(1.0) / shadowMapSize;
            var dx:Float = texelSize.x;
            var dy:Float = texelSize.y;

            var uv:Vec2 = shadowCoord.xy;
            var f:Vec2 = fract(uv * shadowMapSize + 0.5);
            uv -= f * texelSize;

            shadow = (
                texture2DCompare(shadowMap, uv, shadowCoord.z) +
                texture2DCompare(shadowMap, uv + Vec2(dx, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, uv + Vec2(0.0, dy), shadowCoord.z) +
                texture2DCompare(shadowMap, uv + texelSize, shadowCoord.z) +
                mix(texture2DCompare(shadowMap, uv + Vec2(-dx, 0.0), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + Vec2(2.0 * dx, 0.0), shadowCoord.z),
                     f.x) +
                mix(texture2DCompare(shadowMap, uv + Vec2(-dx, dy), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + Vec2(2.0 * dx, dy), shadowCoord.z),
                     f.x) +
                mix(texture2DCompare(shadowMap, uv + Vec2(0.0, -dy), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + Vec2(0.0, 2.0 * dy), shadowCoord.z),
                     f.y) +
                mix(mix(texture2DCompare(shadowMap, uv + Vec2(-dx, -dy), shadowCoord.z),
                       texture2DCompare(shadowMap, uv + Vec2(2.0 * dx, -dy), shadowCoord.z),
                       f.x),
                     mix(texture2DCompare(shadowMap, uv + Vec2(-dx, 2.0 * dy), shadowCoord.z),
                          texture2DCompare(shadowMap, uv + Vec2(2.0 * dx, 2.0 * dy), shadowCoord.z),
                          f.x),
                     f.y)
            ) * (1.0 / 9.0);

            #elseif ( SHADOWMAP_TYPE_VSM )
            shadow = VSMShadow(shadowMap, shadowCoord.xy, shadowCoord.z);

            #else
            shadow = texture2DCompare(shadowMap, shadowCoord.xy, shadowCoord.z);

            #end
        }

        return shadow;
    }

    inline function cubeToUV(v:Vec3, texelSizeY:Float):Vec2 {
        var absV:Vec3 = abs(v);

        var scaleToCube:Float = 1.0 / max(absV.x, max(absV.y, absV.z));
        absV *= scaleToCube;

        v *= scaleToCube * (1.0 - 2.0 * texelSizeY);

        var planar:Vec2 = v.xy;

        var almostATexel:Float = 1.5 * texelSizeY;
        var almostOne:Float = 1.0 - almostATexel;

        if (absV.z >= almostOne) {
            if (v.z > 0.0)
                planar.x = 4.0 - v.x;
        } else if (absV.x >= almostOne) {
            var signX:Float = sign(v.x);
            planar.x = v.z * signX + 2.0 * signX;
        } else if (absV.y >= almostOne) {
            var signY:Float = sign(v.y);
            planar.x = v.x + 2.0 * signY + 2.0;
            planar.y = v.z * signY - 2.0;
        }

        return Vec2(0.125, 0.25) * planar + Vec2(0.375, 0.75);
    }

    inline function getPointShadow(shadowMap:Texture, shadowMapSize:Vec2, shadowBias:Float, shadowRadius:Float, shadowCoord:Vec4, shadowCameraNear:Float, shadowCameraFar:Float):Float {
        var shadow:Float = 1.0;

        var lightToPosition:Vec3 = shadowCoord.xyz;
        var lightToPositionLength:Float = length(lightToPosition);

        if (lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0) {
            var dp:Float = (lightToPositionLength - shadowCameraNear) / (shadowCameraFar - shadowCameraNear);
            dp += shadowBias;

            var bd3D:Vec3 = normalize(lightToPosition);

            var texelSize:Vec2 = Vec2(1.0) / (shadowMapSize * Vec2(4.0, 2.0));

            #if ( SHADOWMAP_TYPE_PCF ) || ( SHADOWMAP_TYPE_PCF_SOFT ) || ( SHADOWMAP_TYPE_VSM )
            var offset:Vec2 = Vec2(-1, 1) * shadowRadius * texelSize.y;

            shadow = (
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.x, offset.y, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.y, offset.y, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.x, offset.y, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.y, offset.y, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D, texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.x, offset.x, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.y, offset.x, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.x, offset.x, 0.0), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + Vec3(offset.y, offset.x, 0.0), texelSize.y), dp)
            ) * (1.0 / 9.0);

            #else
            shadow = texture2DCompare(shadowMap, cubeToUV(bd3D, texelSize.y), dp);

            #end
        }

        return shadow;
    }
}