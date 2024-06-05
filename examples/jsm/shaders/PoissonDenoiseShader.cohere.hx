import h2d.Matrix4;
import h2d.Vector2;
import h2d.Vector3;

class PoissonDenoiseShader {
    public var name: String = "PoissonDenoiseShader";
    public var defines: { [key: String]: Dynamic; } = {
        'SAMPLES': 16,
        'SAMPLE_VECTORS': generatePdSamplePointInitializer(16, 2, 1),
        'NORMAL_VECTOR_TYPE': 1,
        'DEPTH_VALUE_SOURCE': 0
    };
    public var uniforms: { [key: String]: Dynamic; } = {
        'tDiffuse': { value: null },
        'tNormal': { value: null },
        'tDepth': { value: null },
        'tNoise': { value: null },
        'resolution': { value: new Vector2() },
        'cameraProjectionMatrixInverse': { value: new Matrix4() },
        'lumaPhi': { value: 5.0 },
        'depthPhi': { value: 5.0 },
        'normalPhi': { value: 5.0 },
        'radius': { value: 4.0 },
        'index': { value: 0 }
    };
    public var vertexShader: String = """
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    """;
    public var fragmentShader: String = """
        varying vec2 vUv;
        uniform sampler2D tDiffuse;
        uniform sampler2D tNormal;
        uniform sampler2D tDepth;
        uniform sampler2D tNoise;
        uniform vec2 resolution;
        uniform mat4 cameraProjectionMatrixInverse;
        uniform float lumaPhi;
        uniform float depthPhi;
        uniform float normalPhi;
        uniform float radius;
        uniform int index;

        #include <common>
        #include <packing>

        #ifndef SAMPLE_LUMINANCE
        #define SAMPLE_LUMINANCE dot(vec3(0.2125, 0.7154, 0.0721), a)
        #endif

        #ifndef FRAGMENT_OUTPUT
        #define FRAGMENT_OUTPUT vec4(denoised, 1.)
        #endif

        float getLuminance(const in vec3 a) {
            return SAMPLE_LUMINANCE;
        }

        const vec3 poissonDisk[SAMPLES] = SAMPLE_VECTORS;

        vec3 getViewPosition(const in vec2 screenPosition, const in float depth) {
            vec4 clipSpacePosition = vec4(vec3(screenPosition, depth) * 2.0 - 1.0, 1.0);
            vec4 viewSpacePosition = cameraProjectionMatrixInverse * clipSpacePosition;
            return viewSpacePosition.xyz / viewSpacePosition.w;
        }

        float getDepth(const vec2 uv) {
            #if DEPTH_VALUE_SOURCE == 1
            return textureLod(tDepth, uv.xy, 0.0).a;
            #else
            return textureLod(tDepth, uv.xy, 0.0).r;
            #endif
        }

        float fetchDepth(const ivec2 uv) {
            #if DEPTH_VALUE_SOURCE == 1
            return texelFetch(tDepth, uv.xy, 0).a;
            #else
            return texelFetch(tDepth, uv.xy, 0).r;
            #endif
        }

        vec3 computeNormalFromDepth(const vec2 uv) {
            vec2 size = vec2(textureSize(tDepth, 0));
            ivec2 p = ivec2(uv * size);
            float c0 = fetchDepth(p);
            float l2 = fetchDepth(p - ivec2(2, 0));
            float l1 = fetchDepth(p - ivec2(1, 0));
            float r1 = fetchDepth(p + ivec2(1, 0));
            float r2 = fetchDepth(p + ivec2(2, 0));
            float b2 = fetchDepth(p - ivec2(0, 2));
            float b1 = fetchDepth(p - ivec2(0, 1));
            float t1 = fetchDepth(p + ivec2(0, 1));
            float t2 = fetchDepth(p + ivec2(0, 2));
            float dl = abs((2.0 * l1 - l2) - c0);
            float dr = abs((2.0 * r1 - r2) - c0);
            float db = abs((2.0 * b1 - b2) - c0);
            float dt = abs((2.0 * t1 - t2) - c0);
            vec3 ce = getViewPosition(uv, c0).xyz;
            vec3 dpdx = (dl < dr) ? ce - getViewPosition((uv - vec2(1.0 / size.x, 0.0)), l1).xyz
                                    : -ce + getViewPosition((uv + vec2(1.0 / size.x, 0.0)), r1).xyz;
            vec3 dpdy = (db < dt) ? ce - getViewPosition((uv - vec2(0.0, 1.0 / size.y)), b1).xyz
                                    : -ce + getViewPosition((uv + vec2(0.0, 1.0 / size.y)), t1).xyz;
            return normalize(cross(dpdx, dpdy));
        }

        vec3 getViewNormal(const vec2 uv) {
            #if NORMAL_VECTOR_TYPE == 2
            return normalize(textureLod(tNormal, uv, 0.).rgb);
            #elif NORMAL_VECTOR_TYPE == 1
            return unpackRGBToNormal(textureLod(tNormal, uv, 0.).rgb);
            #else
            return computeNormalFromDepth(uv);
            #endif
        }

        void denoiseSample(in vec3 center, in vec3 viewNormal, in vec3 viewPos, in vec2 sampleUv, inout vec3 denoised, inout float totalWeight) {
            vec4 sampleTexel = textureLod(tDiffuse, sampleUv, 0.0);
            float sampleDepth = getDepth(sampleUv);
            vec3 sampleNormal = getViewNormal(sampleUv);
            vec3 neighborColor = sampleTexel.rgb;
            vec3 viewPosSample = getViewPosition(sampleUv, sampleDepth);

            float normalDiff = dot(viewNormal, sampleNormal);
            float normalSimilarity = pow(max(normalDiff, 0.), normalPhi);
            float lumaDiff = abs(getLuminance(neighborColor) - getLuminance(center));
            float lumaSimilarity = max(1.0 - lumaDiff / lumaPhi, 0.0);
            float depthDiff = abs(dot(viewPos - viewPosSample, viewNormal));
            float depthSimilarity = max(1. - depthDiff / depthPhi, 0.);
            float w = lumaSimilarity * depthSimilarity * normalSimilarity;

            denoised += w * neighborColor;
            totalWeight += w;
        }

        void main() {
            float depth = getDepth(vUv.xy);
            vec3 viewNormal = getViewNormal(vUv);
            if (depth == 1.0 || dot(viewNormal, viewNormal) == 0.) {
                discard;
                return;
            }
            vec4 texel = textureLod(tDiffuse, vUv, 0.0);
            vec3 center = texel.rgb;
            vec3 viewPos = getViewPosition(vUv, depth);

            vec2 noiseResolution = vec2(textureSize(tNoise, 0));
            vec2 noiseUv = vUv * resolution / noiseResolution;
            vec4 noiseTexel = textureLod(tNoise, noiseUv, 0.0);
            vec2 noiseVec = vec2(sin(noiseTexel[index % 4] * 2. * PI), cos(noiseTexel[index % 4] * 2. * PI));
            mat2 rotationMatrix = mat2(noiseVec.x, -noiseVec.y, noiseVec.x, noiseVec.y);

            float totalWeight = 1.0;
            vec3 denoised = texel.rgb;
            for (int i = 0; i < SAMPLES; i++) {
                vec3 sampleDir = poissonDisk[i];
                vec2 offset = rotationMatrix * (sampleDir.xy * (1. + sampleDir.z * (radius - 1.)) / resolution);
                vec2 sampleUv = vUv + offset;
                denoiseSample(center, viewNormal, viewPos, sampleUv, denoised, totalWeight);
            }

            if (totalWeight > 0.) {
                denoised /= totalWeight;
            }
            gl_FragColor = FRAGMENT_OUTPUT;
        }
    """;

    public function new() {

    }

    public static function generatePdSamplePointInitializer(samples: Int, rings: Int, radiusExponent: Int): String {
        var poissonDisk = generateDenoiseSamples(samples, rings, radiusExponent);
        var glslCode = "vec3[SAMPLES](";

        for (i in 0...samples) {
            var sample = poissonDisk[i];
            glslCode += "vec3(${sample.x}, ${sample.y}, ${sample.z})${if (i < samples - 1) "," else ")}";
        }

        return glslCode;
    }

    public static function generateDenoiseSamples(numSamples: Int, numRings: Int, radiusExponent: Int): Array<Vector3> {
        var samples = [];

        for (i in 0...numSamples) {
            var angle = 2 * Math.PI * numRings * i / numSamples;
            var radius = Math.pow(i / (numSamples - 1), radiusExponent);
            samples.push(new Vector3(Math.cos(angle), Math.sin(angle), radius));
        }

        return samples;
    }
}