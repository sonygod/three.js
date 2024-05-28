package three.js.src.renderers.shaders.ShaderChunk;

class ShadowmapParsFragmentGlsl 
{
    #if NUM_SPOT_LIGHT_COORDS > 0
    var vSpotLightCoord:Array<Vec4> = [for (i in 0...NUM_SPOT_LIGHT_COORDS) vec4(0, 0, 0, 0)];
    #end

    #if NUM_SPOT_LIGHT_MAPS > 0
    var spotLightMap:Array<Sampler2D> = [for (i in 0...NUM_SPOT_LIGHT_MAPS) new Sampler2D()];
    #end

    #ifdef USE_SHADOWMAP

    #if NUM_DIR_LIGHT_SHADOWS > 0
    var directionalShadowMap:Array<Sampler2D> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) new Sampler2D()];
    var vDirectionalShadowCoord:Array<Vec4> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) vec4(0, 0, 0, 0)];
    struct DirectionalLightShadow {
        var shadowBias:Float;
        var shadowNormalBias:Float;
        var shadowRadius:Float;
        var shadowMapSize:Vec2;
    }
    var directionalLightShadows:Array<DirectionalLightShadow> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) new DirectionalLightShadow(0, 0, 0, vec2(0, 0))];
    #end

    #if NUM_SPOT_LIGHT_SHADOWS > 0
    var spotShadowMap:Array<Sampler2D> = [for (i in 0...NUM_SPOT_LIGHT_SHADOWS) new Sampler2D()];
    struct SpotLightShadow {
        var shadowBias:Float;
        var shadowNormalBias:Float;
        var shadowRadius:Float;
        var shadowMapSize:Vec2;
    }
    var spotLightShadows:Array<SpotLightShadow> = [for (i in 0...NUM_SPOT_LIGHT_SHADOWS) new SpotLightShadow(0, 0, 0, vec2(0, 0))];
    #end

    #if NUM_POINT_LIGHT_SHADOWS > 0
    var pointShadowMap:Array<Sampler2D> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) new Sampler2D()];
    var vPointShadowCoord:Array<Vec4> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) vec4(0, 0, 0, 0)];
    struct PointLightShadow {
        var shadowBias:Float;
        var shadowNormalBias:Float;
        var shadowRadius:Float;
        var shadowMapSize:Vec2;
        var shadowCameraNear:Float;
        var shadowCameraFar:Float;
    }
    var pointLightShadows:Array<PointLightShadow> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) new PointLightShadow(0, 0, 0, vec2(0, 0), 0, 0)];
    #end

    /**
     * Texture sampling with comparison
     * @param depths 
     * @param uv 
     * @param compare 
     * @return 
     */
    inline function texture2DCompare(depths:Sampler2D, uv:Vec2, compare:Float):Float {
        return step(compare, unpackRGBAToDepth(texture2D(depths, uv)));
    }

    /**
     * Unpacks a 2-channel vector from a 4-channel texture
     * @param shadow 
     * @param uv 
     * @return 
     */
    inline function texture2DDistribution(shadow:Sampler2D, uv:Vec2):Vec2 {
        return unpackRGBATo2Half(texture2D(shadow, uv));
    }

    /**
     * Variance Shadow Mapping
     * @param shadow 
     * @param uv 
     * @param compare 
     * @return 
     */
    inline function VSMShadow(shadow:Sampler2D, uv:Vec2, compare:Float):Float {
        var occlusion:Float = 1.0;

        var distribution:Vec2 = texture2DDistribution(shadow, uv);

        var hard_shadow:Float = step(compare, distribution.x); // Hard Shadow

        if (hard_shadow != 1.0) {
            var distance:Float = compare - distribution.x;
            var variance:Float = max(0.00000, distribution.y * distribution.y);
            var softness_probability:Float = variance / (variance + distance * distance); // Chebeyshevs inequality
            softness_probability = clamp((softness_probability - 0.3) / (0.95 - 0.3), 0.0, 1.0); // 0.3 reduces light bleed
            occlusion = clamp(max(hard_shadow, softness_probability), 0.0, 1.0);
        }

        return occlusion;
    }

    /**
     * Get shadow
     * @param shadowMap 
     * @param shadowMapSize 
     * @param shadowBias 
     * @param shadowRadius 
     * @param shadowCoord 
     * @return 
     */
    inline function getShadow(shadowMap:Sampler2D, shadowMapSize:Vec2, shadowBias:Float, shadowRadius:Float, shadowCoord:Vec4):Float {
        var shadow:Float = 1.0;

        shadowCoord.xyz /= shadowCoord.w;
        shadowCoord.z += shadowBias;

        var inFrustum:Bool = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
        var frustumTest:Bool = inFrustum && shadowCoord.z <= 1.0;

        if (frustumTest) {
            #if defined( SHADOWMAP_TYPE_PCF )
            var texelSize:Vec2 = vec2(1.0) / shadowMapSize;
            var dx0:Float = -texelSize.x * shadowRadius;
            var dy0:Float = -texelSize.y * shadowRadius;
            var dx1:Float = texelSize.x * shadowRadius;
            var dy1:Float = texelSize.y * shadowRadius;
            var dx2:Float = dx0 / 2.0;
            var dy2:Float = dy0 / 2.0;
            var dx3:Float = dx1 / 2.0;
            var dy3:Float = dy1 / 2.0;

            shadow = (
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx0, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(0.0, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx1, dy0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx2, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(0.0, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx3, dy2), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx0, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx2, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy, shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx3, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx1, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx2, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(0.0, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx3, dy3), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx0, dy1), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(0.0, dy1), shadowCoord.z) +
                texture2DCompare(shadowMap, shadowCoord.xy + vec2(dx1, dy1), shadowCoord.z)
            ) * (1.0 / 17.0);

            #elseif defined( SHADOWMAP_TYPE_PCF_SOFT )

            var texelSize:Vec2 = vec2(1.0) / shadowMapSize;
            var dx:Float = texelSize.x;
            var dy:Float = texelSize.y;

            var uv:Vec2 = shadowCoord.xy;
            var f:Vec2 = fract(uv * shadowMapSize + 0.5);
            uv -= f * texelSize;

            shadow = (
                texture2DCompare(shadowMap, uv, shadowCoord.z) +
                texture2DCompare(shadowMap, uv + vec2(dx, 0.0), shadowCoord.z) +
                texture2DCompare(shadowMap, uv + vec2(0.0, dy), shadowCoord.z) +
                texture2DCompare(shadowMap, uv + texelSize, shadowCoord.z) +
                mix(texture2DCompare(shadowMap, uv + vec2(-dx, 0.0), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + vec2(2.0 * dx, 0.0), shadowCoord.z),
                     f.x) +
                mix(texture2DCompare(shadowMap, uv + vec2(-dx, dy), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + vec2(2.0 * dx, dy), shadowCoord.z),
                     f.x) +
                mix(texture2DCompare(shadowMap, uv + vec2(0.0, -dy), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + vec2(0.0, 2.0 * dy), shadowCoord.z),
                     f.y) +
                mix(texture2DCompare(shadowMap, uv + vec2(dx, -dy), shadowCoord.z),
                     texture2DCompare(shadowMap, uv + vec2(dx, 2.0 * dy), shadowCoord.z),
                     f.y) +
                mix(mix(texture2DCompare(shadowMap, uv + vec2(-dx, -dy), shadowCoord.z),
                         texture2DCompare(shadowMap, uv + vec2(2.0 * dx, -dy), shadowCoord.z),
                         f.x),
                     mix(texture2DCompare(shadowMap, uv + vec2(-dx, 2.0 * dy), shadowCoord.z),
                         texture2DCompare(shadowMap, uv + vec2(2.0 * dx, 2.0 * dy), shadowCoord.z),
                         f.x),
                     f.y)
            ) * (1.0 / 9.0);

            #elseif defined( SHADOWMAP_TYPE_VSM )

            shadow = VSMShadow(shadowMap, shadowCoord.xy, shadowCoord.z);

            #else // no percentage-closer filtering:

            shadow = texture2DCompare(shadowMap, shadowCoord.xy, shadowCoord.z);

            #end
        }

        return shadow;
    }

    /**
     * Cube to UV mapping
     * @param v 
     * @param texelSizeY 
     * @return 
     */
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

        return vec2(0.125, 0.25) * planar + vec2(0.375, 0.75);
    }

    /**
     * Get point shadow
     * @param shadowMap 
     * @param shadowMapSize 
     * @param shadowBias 
     * @param shadowRadius 
     * @param shadowCoord 
     * @param shadowCameraNear 
     * @param shadowCameraFar 
     * @return 
     */
    inline function getPointShadow(shadowMap:Sampler2D, shadowMapSize:Vec2, shadowBias:Float, shadowRadius:Float, shadowCoord:Vec4, shadowCameraNear:Float, shadowCameraFar:Float):Float {
        var shadow:Float = 1.0;

        var lightToPosition:Vec3 = shadowCoord.xyz;
        var lightToPositionLength:Float = length(lightToPosition);

        if (lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0) {
            var dp:Float = (lightToPositionLength - shadowCameraNear) / (shadowCameraFar - shadowCameraNear); // need to clamp?
            dp += shadowBias;

            var bd3D:Vec3 = normalize(lightToPosition);

            var texelSize:Vec2 = vec2(1.0) / (shadowMapSize * vec2(4.0, 2.0));

            #if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )

            var offset:Vec2 = vec2(-1, 1) * shadowRadius * texelSize.y;

            shadow = (
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.x, offset.y, offset.y), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.y, offset.y, offset.y), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.x, offset.y, offset.x), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.y, offset.y, offset.x), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D, texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.x, offset.x, offset.y), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.y, offset.x, offset.y), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.x, offset.x, offset.x), texelSize.y), dp) +
                texture2DCompare(shadowMap, cubeToUV(bd3D + vec3(offset.y, offset.x, offset.x), texelSize.y), dp)
            ) * (1.0 / 9.0);

            #else // no percentage-closer filtering

            shadow = texture2DCompare(shadowMap, cubeToUV(bd3D, texelSize.y), dp);

            #end
        }

        return shadow;
    }
}