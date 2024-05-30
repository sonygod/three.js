import Node from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';
import { positionView } from './PositionNode.js';
import { diffuseColor, property } from '../core/PropertyNode.js';
import { tslFn } from '../shadernode/ShaderNode.js';
import { loop } from '../utils/LoopNode.js';
import { smoothstep } from '../math/MathNode.js';
import { uniforms } from './UniformsNode.js';

class ClippingNode extends Node {

	public static var ALPHA_TO_COVERAGE:String = 'alphaToCoverage';
	public static var DEFAULT:String = 'default';

	public var scope:String;

	public function new( scope:String = ALPHA_TO_COVERAGE ) {

		super();

		this.scope = scope;

	}

	public function setup( builder ) {

		super.setup( builder );

		var clippingContext = builder.clippingContext;
		var { localClipIntersection, localClippingCount, globalClippingCount } = clippingContext;

		var numClippingPlanes = globalClippingCount + localClippingCount;
		var numUnionClippingPlanes = localClipIntersection ? numClippingPlanes - localClippingCount : numClippingPlanes;

		if ( this.scope == ALPHA_TO_COVERAGE ) {

			return this.setupAlphaToCoverage( clippingContext.planes, numClippingPlanes, numUnionClippingPlanes );

		} else {

			return this.setupDefault( clippingContext.planes, numClippingPlanes, numUnionClippingPlanes );

		}

	}

	public function setupAlphaToCoverage( planes, numClippingPlanes, numUnionClippingPlanes ) {

		return tslFn( function() {

			var clippingPlanes = uniforms( planes );

			var distanceToPlane = property( 'float', 'distanceToPlane' );
			var distanceGradient = property( 'float', 'distanceToGradient' );

			var clipOpacity = property( 'float', 'clipOpacity' );

			clipOpacity.assign( 1 );

			var plane;

			loop( numUnionClippingPlanes, function( { i } ) {

				plane = clippingPlanes.element( i );

				distanceToPlane.assign( positionView.dot( plane.xyz ).negate().add( plane.w ) );
				distanceGradient.assign( distanceToPlane.fwidth().div( 2.0 ) );

				clipOpacity.mulAssign( smoothstep( distanceGradient.negate(), distanceGradient, distanceToPlane ) );

				clipOpacity.equal( 0.0 ).discard();

			} );

			if ( numUnionClippingPlanes < numClippingPlanes ) {

				var unionClipOpacity = property( 'float', 'unionclipOpacity' );

				unionClipOpacity.assign( 1 );

				loop( { start: numUnionClippingPlanes, end: numClippingPlanes }, function( { i } ) {

					plane = clippingPlanes.element( i );

					distanceToPlane.assign( positionView.dot( plane.xyz ).negate().add( plane.w ) );
					distanceGradient.assign( distanceToPlane.fwidth().div( 2.0 ) );

					unionClipOpacity.mulAssign( smoothstep( distanceGradient.negate(), distanceGradient, distanceToPlane ).oneMinus() );

				} );

				clipOpacity.mulAssign( unionClipOpacity.oneMinus() );

			}

			diffuseColor.a.mulAssign( clipOpacity );

			diffuseColor.a.equal( 0.0 ).discard();

		} )();

	}

	public function setupDefault( planes, numClippingPlanes, numUnionClippingPlanes ) {

		return tslFn( function() {

			var clippingPlanes = uniforms( planes );

			var plane;

			loop( numUnionClippingPlanes, function( { i } ) {

				plane = clippingPlanes.element( i );
				positionView.dot( plane.xyz ).greaterThan( plane.w ).discard();

			} );

			if ( numUnionClippingPlanes < numClippingPlanes ) {

				var clipped = property( 'bool', 'clipped' );

				clipped.assign( true );

				loop( { start: numUnionClippingPlanes, end: numClippingPlanes }, function( { i } ) {

					plane = clippingPlanes.element( i );
					clipped.assign( positionView.dot( plane.xyz ).greaterThan( plane.w ).and( clipped ) );

				} );

				clipped.discard();

			}

		} )();

	}

}

export default ClippingNode;

export function clipping() {
	return nodeObject( new ClippingNode() );
}

export function clippingAlpha() {
	return nodeObject( new ClippingNode( ClippingNode.ALPHA_TO_COVERAGE ) );
}