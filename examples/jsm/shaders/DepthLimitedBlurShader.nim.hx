import three.js.examples.jsm.math.Vector2;

/**
 * TODO
 */

class DepthLimitedBlurShader {

	static var name:String = 'DepthLimitedBlurShader';

	static var defines:haxe.ds.StringMap<Int> = {
		'KERNEL_RADIUS': 4,
		'DEPTH_PACKING': 1,
		'PERSPECTIVE_CAMERA': 1
	};

	static var uniforms:haxe.ds.StringMap<Dynamic> = {
		'tDiffuse': { value: null },
		'size': { value: new Vector2( 512, 512 ) },
		'sampleUvOffsets': { value: [ new Vector2( 0, 0 ) ] },
		'sampleWeights': { value: [ 1.0 ] },
		'tDepth': { value: null },
		'cameraNear': { value: 10 },
		'cameraFar': { value: 1000 },
		'depthCutoff': { value: 10 },
	};

	static var vertexShader:String = "#include <common>\n\nuniform vec2 size;\n\nvarying vec2 vUv;\nvarying vec2 vInvSize;\n\nvoid main() {\n\tvUv = uv;\n\tvInvSize = 1.0 / size;\n\ngl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}";

	static var fragmentShader:String = "#include <common>\n#include <packing>\n\nuniform sampler2D tDiffuse;\nuniform sampler2D tDepth;\n\nuniform float cameraNear;\nuniform float cameraFar;\nuniform float depthCutoff;\n\nuniform vec2 sampleUvOffsets[ KERNEL_RADIUS + 1 ];\nuniform float sampleWeights[ KERNEL_RADIUS + 1 ];\n\nvarying vec2 vUv;\nvarying vec2 vInvSize;\n\nfloat getDepth( const in vec2 screenPosition ) {\n\t#if DEPTH_PACKING == 1\n\treturn unpackRGBAToDepth( texture2D( tDepth, screenPosition ) );\n\t#else\n\treturn texture2D( tDepth, screenPosition ).x;\n\t#endif\n}\n\nfloat getViewZ( const in float depth ) {\n\t#if PERSPECTIVE_CAMERA == 1\n\treturn perspectiveDepthToViewZ( depth, cameraNear, cameraFar );\n\t#else\n\treturn orthographicDepthToViewZ( depth, cameraNear, cameraFar );\n\t#endif\n}\n\nvoid main() {\n\tfloat depth = getDepth( vUv );\n\tif( depth >= ( 1.0 - EPSILON ) ) {\n\t\tdiscard;\n\t}\n\n\tfloat centerViewZ = -getViewZ( depth );\n\tbool rBreak = false, lBreak = false;\n\n\tfloat weightSum = sampleWeights[0];\n\tvec4 diffuseSum = texture2D( tDiffuse, vUv ) * weightSum;\n\n\tfor( int i = 1; i <= KERNEL_RADIUS; i ++ ) {\n\n\t\tfloat sampleWeight = sampleWeights[i];\n\t\tvec2 sampleUvOffset = sampleUvOffsets[i] * vInvSize;\n\n\t\tvec2 sampleUv = vUv + sampleUvOffset;\n\t\tfloat viewZ = -getViewZ( getDepth( sampleUv ) );\n\n\t\tif( abs( viewZ - centerViewZ ) > depthCutoff ) rBreak = true;\n\n\t\tif( ! rBreak ) {\n\t\t\tdiffuseSum += texture2D( tDiffuse, sampleUv ) * sampleWeight;\n\t\t\tweightSum += sampleWeight;\n\t\t}\n\n\t\tsampleUv = vUv - sampleUvOffset;\n\t\tviewZ = -getViewZ( getDepth( sampleUv ) );\n\n\t\tif( abs( viewZ - centerViewZ ) > depthCutoff ) lBreak = true;\n\n\t\tif( ! lBreak ) {\n\t\t\tdiffuseSum += texture2D( tDiffuse, sampleUv ) * sampleWeight;\n\t\t\tweightSum += sampleWeight;\n\t\t}\n\n\t}\n\n\tgl_FragColor = diffuseSum / weightSum;\n}";

}

class BlurShaderUtils {

	static function createSampleWeights( kernelRadius:Int, stdDev:Float ) {

		var weights:Array<Float> = [];

		for ( i in 0...kernelRadius + 1 ) {

			weights.push( gaussian( i, stdDev ) );

		}

		return weights;

	}

	static function createSampleOffsets( kernelRadius:Int, uvIncrement:Vector2 ) {

		var offsets:Array<Vector2> = [];

		for ( i in 0...kernelRadius + 1 ) {

			offsets.push( uvIncrement.clone().multiplyScalar( i ) );

		}

		return offsets;

	}

	static function configure( material:Dynamic, kernelRadius:Int, stdDev:Float, uvIncrement:Vector2 ) {

		material.defines[ 'KERNEL_RADIUS' ] = kernelRadius;
		material.uniforms[ 'sampleUvOffsets' ].value = BlurShaderUtils.createSampleOffsets( kernelRadius, uvIncrement );
		material.uniforms[ 'sampleWeights' ].value = BlurShaderUtils.createSampleWeights( kernelRadius, stdDev );
		material.needsUpdate = true;

	}

}

function gaussian( x:Int, stdDev:Float ) {

	return Math.exp( - ( x * x ) / ( 2.0 * ( stdDev * stdDev ) ) ) / ( Math.sqrt( 2.0 * Math.PI ) * stdDev );

}