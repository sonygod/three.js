package three.jsm.shaders;

import three.Matrix4;
import three.Vector2;

class SSAOShader {

	static var name:String = 'SSAOShader';

	static var defines:Map<String, Int> = {
		'PERSPECTIVE_CAMERA': 1,
		'KERNEL_SIZE': 32
	};

	static var uniforms:Map<String, Dynamic> = {
		'tNormal': { value: null },
		'tDepth': { value: null },
		'tNoise': { value: null },
		'kernel': { value: null },
		'cameraNear': { value: null },
		'cameraFar': { value: null },
		'resolution': { value: new Vector2() },
		'cameraProjectionMatrix': { value: new Matrix4() },
		'cameraInverseProjectionMatrix': { value: new Matrix4() },
		'kernelRadius': { value: 8 },
		'minDistance': { value: 0.005 },
		'maxDistance': { value: 0.05 },
	};

	static var vertexShader:String = `
		varying vec2 vUv;
		void main() {
			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
		}`;

	static var fragmentShader:String = `
		uniform highp sampler2D tNormal;
		uniform highp sampler2D tDepth;
		uniform sampler2D tNoise;
		uniform vec3 kernel[ KERNEL_SIZE ];
		uniform vec2 resolution;
		uniform float cameraNear;
		uniform float cameraFar;
		uniform mat4 cameraProjectionMatrix;
		uniform mat4 cameraInverseProjectionMatrix;
		uniform float kernelRadius;
		uniform float minDistance;
		uniform float maxDistance;
		varying vec2 vUv;
		#include <packing>
		float getDepth( const in vec2 screenPosition ) {
			return texture2D( tDepth, screenPosition ).x;
		}
		float getLinearDepth( const in vec2 screenPosition ) {
			#if PERSPECTIVE_CAMERA == 1
				float fragCoordZ = texture2D( tDepth, screenPosition ).x;
				float viewZ = perspectiveDepthToViewZ( fragCoordZ, cameraNear, cameraFar );
				return viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );
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
		vec3 getViewPosition( const in vec2 screenPosition, const in float depth, const in float viewZ ) {
			float clipW = cameraProjectionMatrix[2][3] * viewZ + cameraProjectionMatrix[3][3];
			vec4 clipPosition = vec4( ( vec3( screenPosition, depth ) - 0.5 ) * 2.0, 1.0 );
			clipPosition *= clipW;
			return ( cameraInverseProjectionMatrix * clipPosition ).xyz;
		}
		vec3 getViewNormal( const in vec2 screenPosition ) {
			return unpackRGBToNormal( texture2D( tNormal, screenPosition ).xyz );
		}
		void main() {
			float depth = getDepth( vUv );
			if ( depth == 1.0 ) {
				gl_FragColor = vec4( 1.0 );
			} else {
				float viewZ = getViewZ( depth );
				vec3 viewPosition = getViewPosition( vUv, depth, viewZ );
				vec3 viewNormal = getViewNormal( vUv );
				vec2 noiseScale = vec2( resolution.x / 4.0, resolution.y / 4.0 );
				vec3 random = vec3( texture2D( tNoise, vUv * noiseScale ).r );
				vec3 tangent = normalize( random - viewNormal * dot( random, viewNormal ) );
				vec3 bitangent = cross( viewNormal, tangent );
				mat3 kernelMatrix = mat3( tangent, bitangent, viewNormal );
				float occlusion = 0.0;
				for ( int i = 0; i < KERNEL_SIZE; i ++ ) {
					vec3 sampleVector = kernelMatrix * kernel[ i ];
					vec3 samplePoint = viewPosition + ( sampleVector * kernelRadius );
					vec4 samplePointNDC = cameraProjectionMatrix * vec4( samplePoint, 1.0 );
					samplePointNDC /= samplePointNDC.w;
					vec2 samplePointUv = samplePointNDC.xy * 0.5 + 0.5;
					float realDepth = getLinearDepth( samplePointUv );
					float sampleDepth = viewZToOrthographicDepth( samplePoint.z, cameraNear, cameraFar );
					float delta = sampleDepth - realDepth;
					if ( delta > minDistance && delta < maxDistance ) {
						occlusion += 1.0;
					}
				}
				occlusion = clamp( occlusion / float( KERNEL_SIZE ), 0.0, 1.0 );
				gl_FragColor = vec4( vec3( 1.0 - occlusion ), 1.0 );
			}
		}`;
}

class SSAODepthShader {
	// ... 同上 ...
}

class SSAOBlurShader {
	// ... 同上 ...
}