// transmission_pars_fragment.glsl.hx

#ifdef USE_TRANSMISSION

// Transmission code is based on glTF-Sampler-Viewer
// https://github.com/KhronosGroup/glTF-Sample-Viewer

uniform float transmission : Float;
uniform float thickness : Float;
uniform float attenuationDistance : Float;
uniform vec3 attenuationColor : Vec3;

#ifdef USE_TRANSMISSIONMAP

uniform sampler2D transmissionMap : Sampler2D;

#endif

#ifdef USE_THICKNESSMAP

uniform sampler2D thicknessMap : Sampler2D;

#endif

uniform vec2 transmissionSamplerSize : Vec2;
uniform sampler2D transmissionSamplerMap : Sampler2D;

uniform mat4 modelMatrix : Mat4;
uniform mat4 projectionMatrix : Mat4;

varying vec3 vWorldPosition : Vec3;

// Mipped Bicubic Texture Filtering by N8
// https://www.shadertoy.com/view/Dl2SDW

function w0(a : Float) : Float {
    return (1.0 / 6.0) * (a * (a * (-a + 3.0) - 3.0) + 1.0);
}

function w1(a : Float) : Float {
    return (1.0 / 6.0) * (a * a * (3.0 * a - 6.0) + 4.0);
}

function w2(a : Float) : Float {
    return (1.0 / 6.0) * (a * (a * (-3.0 * a + 3.0) + 3.0) + 1.0);
}

function w3(a : Float) : Float {
    return (1.0 / 6.0) * (a * a * a);
}

// g0 and g1 are the two amplitude functions
function g0(a : Float) : Float {
    return w0(a) + w1(a);
}

function g1(a : Float) : Float {
    return w2(a) + w3(a);
}

// h0 and h1 are the two offset functions
function h0(a : Float) : Float {
    return -1.0 + w1(a) / (w0(a) + w1(a));
}

function h1(a : Float) : Float {
    return 1.0 + w3(a) / (w2(a) + w3(a));
}

function bicubic(tex : Sampler2D, uv : Vec2, texelSize : Vec4, lod : Float) : Vec4 {
    uv = uv * texelSize.zw + 0.5;
    var iuv : Vec2 = floor(uv);
    var fuv : Vec2 = fract(uv);
    var g0x : Float = g0(fuv.x);
    var g1x : Float = g1(fuv.x);
    var h0x : Float = h0(fuv.x);
    var h1x : Float = h1(fuv.x);
    var h0y : Float = h0(fuv.y);
    var h1y : Float = h1(fuv.y);
    var p0 : Vec2 = (vec2(iuv.x + h0x, iuv.y + h0y) - 0.5) * texelSize.xy;
    var p1 : Vec2 = (vec2(iuv.x + h1x, iuv.y + h0y) - 0.5) * texelSize.xy;
    var p2 : Vec2 = (vec2(iuv.x + h0x, iuv.y + h1y) - 0.5) * texelSize.xy;
    var p3 : Vec2 = (vec2(iuv.x + h1x, iuv.y + h1y) - 0.5) * texelSize.xy;
    return g0(fuv.y) * (g0x * textureLod(tex, p0, lod) + g1x * textureLod(tex, p1, lod)) +
           g1(fuv.y) * (g0x * textureLod(tex, p2, lod) + g1x * textureLod(tex, p3, lod));
}

function textureBicubic(sampler : Sampler2D, uv : Vec2, lod : Float) : Vec4 {
    var fLodSize : Vec2 = vec2(textureSize(sampler, Std.int(lod)));
    var cLodSize : Vec2 = vec2(textureSize(sampler, Std.int(lod + 1.0)));
    var fLodSizeInv : Vec2 = 1.0 / fLodSize;
    var cLodSizeInv : Vec2 = 1.0 / cLodSize;
    var fSample : Vec4 = bicubic(sampler, uv, vec4(fLodSizeInv, fLodSize), Std.int(lod));
    var cSample : Vec4 = bicubic(sampler, uv, vec4(cLodSizeInv, cLodSize), Std.int(lod) + 1);
    return mix(fSample, cSample, fract(lod));
}

function getVolumeTransmissionRay(n : Vec3, v : Vec3, thickness : Float, ior : Float, modelMatrix : Mat4) : Vec3 {
    // Direction of refracted light.
    var refractionVector : Vec3 = refract(-v, normalize(n), 1.0 / ior);
    // Compute rotation-independant scaling of the model matrix.
    var modelScale : Vec3;
    modelScale.x = length(vec3(modelMatrix[0].xyz));
    modelScale.y = length(vec3(modelMatrix[1].xyz));
    modelScale.z = length(vec3(modelMatrix[2].xyz));
    // The thickness is specified in local space.
    return normalize(refractionVector) * thickness * modelScale;
}

function applyIorToRoughness(roughness : Float, ior : Float) : Float {
    // Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and
    // an IOR of 1.5 results in the default amount of microfacet refraction.
    return roughness * clamp(ior * 2.0 - 2.0, 0.0, 1.0);
}

function getTransmissionSample(fragCoord : Vec2, roughness : Float, ior : Float) : Vec4 {
    var lod : Float = Math.log2(transmissionSamplerSize.x) * applyIorToRoughness(roughness, ior);
    return textureBicubic(transmissionSamplerMap, fragCoord, lod);
}

function volumeAttenuation(transmissionDistance : Float, attenuationColor : Vec3, attenuationDistance : Float) : Vec3 {
    if (Math.isInfinite(attenuationDistance)) {
        // Attenuation distance is +∞, i.e. the transmitted color is not attenuated at all.
        return vec3(1.0);
    } else {
        // Compute light attenuation using Beer's law.
        var attenuationCoefficient : Vec3 = -Math.log(attenuationColor) / attenuationDistance;
        var transmittance : Vec3 = Math.exp(-attenuationCoefficient * transmissionDistance); // Beer's law
        return transmittance;
    }
}

function getIBLVolumeRefraction(n : Vec3, v : Vec3, roughness : Float, diffuseColor : Vec3, specularColor : Vec3, specularF90 : Float, position : Vec3, modelMatrix : Mat4, viewMatrix : Mat4, projMatrix : Mat4, dispersion : Float, ior : Float, thickness : Float, attenuationColor : Vec3, attenuationDistance : Float) : Vec4 {
    var transmittedLight : Vec4;
    var transmittance : Vec3;

    #ifdef USE_DISPERSION
    var halfSpread : Float = (ior - 1.0) * 0.025 * dispersion;
    var iors : Vec3 = vec3(ior - halfSpread, ior, ior + halfSpread);

    for (i in 0...3) {
        var transmissionRay : Vec3 = getVolumeTransmissionRay(n, v, thickness, iors[i], modelMatrix);
        var refractedRayExit : Vec3 = position + transmissionRay;

        // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
        var ndcPos : Vec4 = projMatrix * viewMatrix * vec4(refractedRayExit, 1.0);
        var refractionCoords : Vec2 = ndcPos.xy / ndcPos.w;
        refractionCoords += 1.0;
        refractionCoords /= 2.0;

        // Sample framebuffer to get pixel the refracted ray hits.
        var transmissionSample : Vec4 = getTransmissionSample(refractionCoords, roughness, iors[i]);
        transmittedLight[i] = transmissionSample[i];
        transmittedLight.a += transmissionSample.a;

        transmittance[i] = diffuseColor[i] * volumeAttenuation(length(transmissionRay), attenuationColor, attenuationDistance)[i];
    }

    transmittedLight.a /= 3.0;

    #else
    var transmissionRay : Vec3 = getVolumeTransmissionRay(n, v, thickness, ior, modelMatrix);
    var refractedRayExit : Vec3 = position + transmissionRay;

    // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
    var ndcPos : Vec4 = projMatrix * viewMatrix * vec4(refractedRayExit, 1.0);
    var refractionCoords : Vec2 = ndcPos.xy / ndcPos.w;
    refractionCoords += 1.0;
    refractionCoords /= 2.0;

    // Sample framebuffer to get pixel the refracted ray hits.
    transmittedLight = getTransmissionSample(refractionCoords, roughness, ior);
    transmittance = diffuseColor * volumeAttenuation(length(transmissionRay), attenuationColor, attenuationDistance);
    #end

    var attenuatedColor : Vec3 = transmittance * transmittedLight.rgb;

    // Get the specular component.
    var F : Vec3 = EnvironmentBRDF(n, v, specularColor, specularF90, roughness);

    // As less light is transmitted, the opacity should be increased. This simple approximation does a decent job 
    // of modulating a CSS background, and has no effect when the buffer is opaque, due to a solid object or clear color.
    var transmittanceFactor : Float = (transmittance.r + transmittance.g + transmittance.b) / 3.0;

    return vec4((1.0 - F) * attenuatedColor, 1.0 - (1.0 - transmittedLight.a) * transmittanceFactor);
}

#endif