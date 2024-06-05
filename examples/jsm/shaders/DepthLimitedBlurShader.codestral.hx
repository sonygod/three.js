import js.html.WebGLRenderingContext;
import three.math.Vector2;
import three.materials.ShaderMaterial;

class DepthLimitedBlurShader {
    public static var name:String = "DepthLimitedBlurShader";

    public static var defines:Dynamic = {
        'KERNEL_RADIUS': 4,
        'DEPTH_PACKING': 1,
        'PERSPECTIVE_CAMERA': 1
    };

    public static var uniforms:Dynamic = {
        'tDiffuse': { value: null },
        'size': { value: new Vector2(512, 512) },
        'sampleUvOffsets': { value: [new Vector2(0, 0)] },
        'sampleWeights': { value: [1.0] },
        'tDepth': { value: null },
        'cameraNear': { value: 10 },
        'cameraFar': { value: 1000 },
        'depthCutoff': { value: 10 },
    };

    public static var vertexShader:String = """
        #include <common>

        uniform vec2 size;

        varying vec2 vUv;
        varying vec2 vInvSize;

        void main() {
            vUv = uv;
            vInvSize = 1.0 / size;

            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader:String = """
        #include <common>
        #include <packing>

        uniform sampler2D tDiffuse;
        uniform sampler2D tDepth;

        uniform float cameraNear;
        uniform float cameraFar;
        uniform float depthCutoff;

        uniform vec2 sampleUvOffsets[ KERNEL_RADIUS + 1 ];
        uniform float sampleWeights[ KERNEL_RADIUS + 1 ];

        varying vec2 vUv;
        varying vec2 vInvSize;

        float getDepth( const in vec2 screenPosition ) {
            #if DEPTH_PACKING == 1
            return unpackRGBAToDepth( texture2D( tDepth, screenPosition ) );
            #else
            return texture2D( tDepth, screenPosition ).x;
            #endif
        }

        float getViewZ( const in float depth ) {
            #if PERSPECTIVE_CAMERA == 1
            return perspectiveDepthToViewZ( depth, cameraNear, cameraFar );
            #else
            return orthographicDepthToViewZ( depth, cameraNear, cameraFar );
            #endif
        }

        void main() {
            float depth = getDepth( vUv );
            if( depth >= ( 1.0 - EPSILON ) ) {
                discard;
            }

            float centerViewZ = -getViewZ( depth );
            bool rBreak = false, lBreak = false;

            float weightSum = sampleWeights[0];
            vec4 diffuseSum = texture2D( tDiffuse, vUv ) * weightSum;

            for( int i = 1; i <= KERNEL_RADIUS; i ++ ) {

                float sampleWeight = sampleWeights[i];
                vec2 sampleUvOffset = sampleUvOffsets[i] * vInvSize;

                vec2 sampleUv = vUv + sampleUvOffset;
                float viewZ = -getViewZ( getDepth( sampleUv ) );

                if( abs( viewZ - centerViewZ ) > depthCutoff ) rBreak = true;

                if( ! rBreak ) {
                    diffuseSum += texture2D( tDiffuse, sampleUv ) * sampleWeight;
                    weightSum += sampleWeight;
                }

                sampleUv = vUv - sampleUvOffset;
                viewZ = -getViewZ( getDepth( sampleUv ) );

                if( abs( viewZ - centerViewZ ) > depthCutoff ) lBreak = true;

                if( ! lBreak ) {
                    diffuseSum += texture2D( tDiffuse, sampleUv ) * sampleWeight;
                    weightSum += sampleWeight;
                }

            }

            gl_FragColor = diffuseSum / weightSum;
        }
    """;
}

class BlurShaderUtils {
    public static function createSampleWeights(kernelRadius:Int, stdDev:Float):Array<Float> {
        var weights:Array<Float> = [];

        for (var i:Int = 0; i <= kernelRadius; i++) {
            weights.push(gaussian(i, stdDev));
        }

        return weights;
    }

    public static function createSampleOffsets(kernelRadius:Int, uvIncrement:Vector2):Array<Vector2> {
        var offsets:Array<Vector2> = [];

        for (var i:Int = 0; i <= kernelRadius; i++) {
            offsets.push(uvIncrement.clone().multiplyScalar(i));
        }

        return offsets;
    }

    public static function configure(material:ShaderMaterial, kernelRadius:Int, stdDev:Float, uvIncrement:Vector2) {
        material.defines['KERNEL_RADIUS'] = kernelRadius;
        material.uniforms['sampleUvOffsets'].value = BlurShaderUtils.createSampleOffsets(kernelRadius, uvIncrement);
        material.uniforms['sampleWeights'].value = BlurShaderUtils.createSampleWeights(kernelRadius, stdDev);
        material.needsUpdate = true;
    }
}

function gaussian(x:Int, stdDev:Float):Float {
    return Math.exp(-(x * x) / (2.0 * (stdDev * stdDev))) / (Math.sqrt(2.0 * Math.PI) * stdDev);
}