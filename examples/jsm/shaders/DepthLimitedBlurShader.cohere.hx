package;

import js.three.WebGLRenderTarget;
import js.three.WebGLRenderTargetParameter;
import js.three.WebGLRenderTargetParameters;
import js.three.WebGLRenderer;
import js.three.WebGLRendererParameters;
import js.three.WebGLCubeRenderTarget;
import js.three.WebGLCubeRenderTargetParameter;
import js.three.WebGLCubeRenderTargetParameters;
import js.three.WebGLCubeTexture;
import js.three.WebGLCubeTextureParameter;
import js.three.WebGLCubeTextureParameters;
import js.three.WebGLMultisampleRenderTarget;
import js.three.WebGLMultisampleRenderTargetParameter;
import js.three.WebGLMultisampleRenderTargetParameters;
import js.three.WebGLProperties;
import js.three.WebGLShadowMap;
import js.three.WebGLShadowMapType;
import js.three.WebGLSL;
import js.three.WebXRManager;
import js.three.WebXRManagerParameter;
import js.three.WebXRSessionType;
import js.three.XRRigidTransform;
import js.three.XRRigidTransformParameter;
import js.three.XRRigidTransformParameters;
import js.three.XRRigidTransformSpace;
import js.three.XRRigidTransformSpaceParameter;
import js.three.XRRigidTransformSpaces;
import js.three.XRSessions;
import js.three.XRSessionsParameter;
import js.three.XRSessionsParameters;
import js.three.XRSpace;
import js.three.XRSpaceParameter;
import js.three.XRView;
import js.three.XRViewParameter;
import js.three.XRViewport;
import js.three.XRViewportParameter;
import js.three.sRGBEncoding;
import js.three.sec;
import js.three.set;
import js.three.setBenchmarking;
import js.three.setDebug;
import js.three.setLogLevel;
import js.three.setObjectRISConvention;
import js.three.setObjectRISConventionParameter;
import js.three.setPerfOverride;
import js.three.setPerfOverrideParameter;
import jsOverlapMatrix;
import js.tbd;
import js.undefined;
import js.unimplemented;
import js.unimplementedOverride;
import js.unimplementedAbstract;
import js.unimplementedInterface;
import js.untyped;
import js.Vector2;
import js.Vector2Parameter;
import js.Vector2Parameters;
import js.Vector3;
import js.Vector3Parameter;
import js.Vector3Parameters;
import js.Vector4;
import js.Vector4Parameter;
import js.Vector4Parameters;
import js.Vertex;
import js.VertexNormal;
import js.VertexParameter;
import js.VertexParameters;
import js.VertexTangent;
import js.VertexTangentParameter;
import js.VertexTangentParameters;
import js.VertexColors;
import js.VertexColorsParameter;
import js.VertexColorsParameters;
import js.VertexIndex;
import js.VertexIndexParameter;
import js.VertexIndexParameters;
import js.VertexIndices;
import js.VertexIndicesParameter;
import js.VertexIndicesParameters;
import js.VertexMorphTarget;
import js.VertexMorphTargetParameter;
import js.VertexMorphTargetParameters;
import js.VertexMorphTargets;
import js.VertexMorphTargetsParameter;
import js.VertexMorphTargetsParameters;
import js.VertexPosition;
import js.VertexPositionParameter;
import js.VertexPositionParameters;
import js.VertexTangents;
import js.VertexTangentsParameter;
import js.VertexTangentsParameters;
import js.VertexUvs;
import js.VertexUvsParameter;
import js.VertexUvsParameters;
import js.Vertices;
import js.VerticesParameter;
import js.VerticesParameters;
import js.VertexWeights;
import js.VertexWeightsParameter;
import js.VertexWeightsParameters;
import js.VisibleFaceIndices;
import js.VisibleFaceIndicesParameter;
import js.VisibleFaceIndicesParameters;
import js.WebGL;
import js.WebGL2RenderingContext;
import js.WebGLActiveInfo;
import js.WebGLBuffer;
import js.WebGLBufferParameter;
import js.WebGLContextAttributes;
import js.WebGLContextEvent;
import js.WebGLContextEventParameter;
import js.WebGLContextAttributesParameter;
import js.WebGLContextAttributesParameters;
import js.WebGLFramebuffer;
import js.WebGLFramebufferParameter;
import jsMultiplier;
import js.WebGLProgram;
import js.WebGLProgramParameter;
import js.WebGLQuery;
import js.WebGLQueryParameter;
import js.WebGLRenderbuffer;
import js.WebGLRenderbufferParameter;
import js.WebGLRenderingContext;
import js.WebGLShader;
import js.WebGLShaderParameter;
import js.WebGLShaderPrecisionFormat;
import js.WebGLShaderPrecisionFormatParameter;
import js.WebGLSampler;
import js.WebGLSamplerParameter;
import js.WebGLTexture;
import js.WebGLTextureParameter;
import js.WebGLTextureParameters;
import js.WebGLTransformFeedback;
import js.WebGLTransformFeedbackParameter;
import js.WebGLUniformLocation;
import js.WebGLUniformLocationParameter;
import js.WebGLVertexArrayObject;
import js.WebGLVertexArrayObjectParameter;
import js.WebGLVertexArrayObjectOES;
import js.WebGLVertexArrayObjectOESParameter;
import js.WebGLVertexArrayObjectParameter;
import js.WebGLVertexArrayObjectParameters;
import js.WebGL2RenderingContextParameter;
import js.WebGL2RenderingContextParameters;
import js.WebGLActiveInfoParameter;
import js.WebGLActiveInfoParameters;
import js.WebGLBufferParameter;
import js.WebGLBufferParameters;
import js.WebGLContextEventParameter;
import js.WebGLContextEventParameters;
import js.WebGLFramebufferParameter;
import js.WebGLFramebufferParameters;
import js.WebGLProgramParameter;
import js.WebGLProgramParameters;
import js.WebGLQueryParameter;
import js.WebGLQueryParameters;
import js.WebGLRenderbufferParameter;
import js.WebGLRenderbufferParameters;
import js.WebGLRenderingContextParameter;
import js.WebGLRenderingContextParameters;
import js.WebGLShaderParameter;
import js.WebGLShaderParameters;
import js.WebGLSamplerParameter;
import js.WebGLSamplerParameters;
import js.WebGLTextureParameter;
import js.WebGLTextureParameters;
import js.WebGLTransformFeedbackParameter;
import js.WebGLTransformFeedbackParameters;
import js.WebGLUniformLocationParameter;
import js.WebGLUniformLocationParameters;
import js.WebGLVertexArrayObjectParameter;
import js.WebGLVertexArrayObjectParameters;
import js.WebGLVertexArrayObjectOESParameter;
import js.WebGLVertexArrayObjectOESParameters;
import js.WebGLActiveInfoParameters;
import js.WebGLBufferParameters;
import js.WebGLFramebufferParameters;
import js.WebGLProgramParameters;
import js.WebGLQueryParameters;
import js.WebGLRenderbufferParameters;
import js.WebGLRenderingContextParameters;
import js.WebGLShaderParameters;
import js.WebGLSamplerParameters;
import js.WebGLTextureParameters;
import js.WebGLTransformFeedbackParameters;
import js.WebGLUniformLocationParameters;
import js.WebGLVertexArrayObjectParameters;
import js.WebGLVertexArrayObjectOESParameters;
import js.WebGLActiveInfo;
import js.WebGLBuffer;
import js.WebGLContextAttributes;
import js.WebGLContextEvent;
import js.WebGLFramebuffer;
import js.WebGLProgram;
import js.WebGLQuery;
import js.WebGLRenderbuffer;
import js
import js.WebGLShader;
import js.WebGLShaderPrecisionFormat;
import js.WebGLSampler;
import js.WebGLTexture;
import js.WebGLTransformFeedback;
import js.WebGLUniformLocation;
import js.WebGLVertexArrayObject;
import js.WebGLVertexArrayObjectOES;
import js.WebGLActiveInfo;
import js.WebGLBuffer;
import js.WebGLContextAttributes;
import js.WebGLContextEvent;
import js.WebGLFramebuffer;
import js.WebGLProgram;
import js.WebGLQuery;
import js.WebGLRenderbuffer;
import js.WebGLRenderingContext;
import js.WebGLShader;
import js.WebGLShaderPrecisionFormat;
import js.WebGLSampler;
import js.WebGLTexture;
import js.WebGLTransformFeedback;
import js.WebGLUniformLocation;
import js.WebGLVertexArrayObject;
import js.WebGLVertexArrayObjectOES;

class DepthLimitedBlurShader {
    public var name: String;
    public var defines: { [key: String]: Int };
    public var uniforms: { [key: String]: { value: untyped } };
    public var vertexShader: String;
    public var fragmentShader: String;

    public function new() {
        name = 'DepthLimitedBlurShader';
        defines = {
            'KERNEL_RADIUS': 4,
            'DEPTH_PACKING': 1,
            'PERSPECTIVE_CAMERA': 1
        };
        uniforms = {
            'tDiffuse': { value: null },
            'size': { value: new Vector2(512, 512) },
            'sampleUvOffsets': { value: [new Vector2(0, 0)] },
            'sampleWeights': { value: [1.0] },
            'tDepth': { value: null },
            'cameraNear': { value: 10 },
            'cameraFar': { value: 1000 },
            'depthCutoff': { value: 10 }
        };
        vertexShader = """
            #include <common>

            uniform vec2 size;

            varying vec2 vUv;
            varying vec2 vInvSize;

            void main() {
                vUv = uv;
                vInvSize = 1.0 / size;

                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        """;
        fragmentShader = """
            #include <common>
            #include <packing>

            uniform sampler2D tDiffuse;
            uniform sampler2D tDepth;

            uniform float cameraNear;
            uniform float cameraFar;
            uniform float depthCutoff;

            uniform vec2 sampleUvOffsets[KERNEL_RADIUS + 1];
            uniform float sampleWeights[KERNEL_RADIUS + 1];

            varying vec2 vUv;
            varying vec2 vInvSize;

            float getDepth(const in vec2 screenPosition) {
                #if DEPTH_PACKING == 1
                return unpackRGBAToDepth(texture2D(tDepth, screenPosition));
                #else
                return texture2D(tDepth, screenPosition).x;
                #endif
            }

            float getViewZ(const in float depth) {
                #if PERSPECTIVE_CAMERA == 1
                return perspectiveDepthToViewZ(depth, cameraNear, cameraFar);
                #else
                return orthographicDepthToViewZ(depth, cameraNear, cameraFar);
                #endif
            }

            void main() {
                float depth = getDepth(vUv);
                if (depth >= (1.0 - EPSILON)) {
                    discard;
                }

                float centerViewZ = -getViewZ(depth);
                bool rBreak = false, lBreak = false;

                float weightSum = sampleWeights[0];
                vec4 diffuseSum = texture2D(tDiffuse, vUv) * weightSum;

                for (int i = 1; i <= KERNEL_RADIUS; i++) {

                    float sampleWeight = sampleWeights[i];
                    vec2 sampleUvOffset = sampleUvOffsets[i] * vInvSize;

                    vec2 sampleUv = vUv + sampleUvOffset;
                    float viewZ = -getViewZ(getDepth(sampleUv));

                    if (abs(viewZ - centerViewZ) > depthCutoff) rBreak = true;

                    if (!rBreak) {
                        diffuseSum += texture2D(tDiffuse, sampleUv) * sampleWeight;
                        weightSum += sampleWeight;
                    }

                    sampleUv = vUv - sampleUvOffset;
                    viewZ = -getViewZ(getDepth(sampleUv));

                    if (abs(viewZ - centerViewZ) > depthCutoff) lBreak = true;

                    if (!lBreak) {
                        diffuseSum += texture2D(tDiffuse, sampleUv) * sampleWeight;
                        weightSum += sampleWeight;
                    }

                }

                gl_FragColor = diffuseSum / weightSum;
            }
        """;
    }
}

class BlurShaderUtils {
    public static function createSampleWeights(kernelRadius: Int, stdDev: Float): Array<Float> {
        var weights = [];
        for (i in 0...(kernelRadius + 1)) {
            weights.push(gaussian(i, stdDev));
        }
        return weights;
    }

    public static function createSampleOffsets(kernelRadius: Int, uvIncrement: Vector2): Array<Vector2> {
        var offsets = [];
        for (i in 0...(kernelRadius + 1)) {
            offsets.push(uvIncrement.clone().multiplyScalar(i));
        }
        return offsets;
    }

    public static function configure(material: untyped, kernelRadius: Int, stdDev: Float, uvIncrement: Vector2) {
        material.defines['KERNEL_RADIUS'] = kernelRadius;
        material.uniforms['sampleUvOffsets'].value = createSampleOffsets(kernelRadius, uvIncrement);
        material.uniforms['sampleWeights'].value = createSampleWeights(kernelRadius, stdDev);
        material.needsUpdate = true;
    }

    private static function gaussian(x: Int, stdDev: Float): Float {
        return Math.exp(-(x * x) / (2.0 * (stdDev * stdDev))) / (Math.sqrt(2.0 * Math.PI) * stdDev);
    }
}

class Main {
    public static function main() {
        var shader = new DepthLimitedBlurShader();
        #if js
        trace(shader.name);
        #end
    }
}