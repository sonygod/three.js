/**
 * MDD is a special format that stores a position for every vertex in a model for every frame in an animation.
 * Similar to BVH, it can be used to transfer animation data between different 3D applications or engines.
 *
 * MDD stores its data in binary format (big endian) in the following way:
 *
 * number of frames (a single uint32)
 * number of vertices (a single uint32)
 * time values for each frame (sequence of float32)
 * vertex data for each frame (sequence of float32)
 */

import three.examples.jsm.loaders.MDDLoader;
import three.examples.jsm.loaders.Loader;
import three.examples.jsm.loaders.FileLoader;
import three.examples.jsm.animation.AnimationClip;
import three.examples.jsm.animation.NumberKeyframeTrack;
import three.examples.jsm.core.BufferAttribute;

class MDDLoader extends Loader {

	public function new( manager:Loader.Manager ) {

		super( manager );

	}

	public function load( url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic ) {

		var scope = this;

		var loader = new FileLoader( this.manager );
		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.load( url, function( data ) {

			onLoad( scope.parse( data ) );

		}, onProgress, onError );

	}

	public function parse( data:haxe.io.Bytes ) {

		var view = new haxe.io.Bytes.ofData( data );

		var totalFrames = view.getUint32( 0 );
		var totalPoints = view.getUint32( 4 );

		var offset = 8;

		// animation clip

		var times = new Float32Array( totalFrames );
		var values = new Float32Array( totalFrames * totalFrames ).fill( 0 );

		for ( i in 0...totalFrames ) {

			times[ i ] = view.getFloat32( offset ); offset += 4;
			values[ ( totalFrames * i ) + i ] = 1;

		}

		var track = new NumberKeyframeTrack( '.morphTargetInfluences', times, values );
		var clip = new AnimationClip( 'default', times[ times.length - 1 ], [ track ] );

		// morph targets

		var morphTargets = [];

		for ( i in 0...totalFrames ) {

			var morphTarget = new Float32Array( totalPoints * 3 );

			for ( j in 0...totalPoints ) {

				var stride = ( j * 3 );

				morphTarget[ stride + 0 ] = view.getFloat32( offset ); offset += 4; // x
				morphTarget[ stride + 1 ] = view.getFloat32( offset ); offset += 4; // y
				morphTarget[ stride + 2 ] = view.getFloat32( offset ); offset += 4; // z

			}

			var attribute = new BufferAttribute( morphTarget, 3 );
			attribute.name = 'morph_' + i;

			morphTargets.push( attribute );

		}

		return {
			morphTargets: morphTargets,
			clip: clip
		};

	}

}

export MDDLoader;