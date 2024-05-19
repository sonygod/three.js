import haxe.ds.LinkedList;
import haxe.ds.LinkedListNode;
import math.Vector3;
import math.Matrix4;
import math._Matrix;

class ConvexHull {

	public var tolerance:Float = -1;
	public var faces:Array<Face> = []; // the generated faces of the convex hull
	public var newFaces:Array<Face> = []; // this array holds the faces that are generated within a single iteration

	// the vertex lists work as follows:
	//
	// let 'a' and 'b' be 'Face' instances
	// let 'v' be points wrapped as instance of 'Vertex'
	//
	//     [v, v, ..., v, v, v, ...]
	//      ^             ^
	//      |             |
	//  a.outside     b.outside
	//
	public var assigned:VertexList = new VertexList();
	public var unassigned:VertexList = new VertexList();

	public var vertices:Array<VertexNode> = []; 	// vertices of the hull (internal representation of given geometry data)

	public function setFromPoints( points:Array<Vector3> ):ConvexHull {

		// The algorithm needs at least four points.

		if ( points.length >= 4 ) {

			this.makeEmpty();

			for ( v in points ) {

				this.vertices.push( new VertexNode( v ) );

			}

			this.compute();

		}

		return this;

	}

	public function setFromObject( object:Dynamic ) {

		const points = [];

		object.updateMatrixWorld( true );

		object.traverse( function ( node ) {

			const geometry = node.geometry;

			if ( geometry !== undefined ) {

				const attribute = geometry.attributes.position;

				if ( attribute !== undefined ) {

					for ( i = 0; i < attribute.count; i ++ ) {

						const point = new Vector3();

						point.fromBufferAttribute( attribute, i ).applyMatrix4( node.matrixWorld );

						points.push( point );

					}

				}

			}

		} );

		return this.setFromPoints( points );
	}

	public function containsPoint( point:Vector3 ):Bool {

		const faces = this.faces;

		for ( i in 0...faces.length ) {

			const face = faces[ i ];

			// compute signed distance and check on what half space the point lies

			if ( face.distanceToPoint( point ) > this.tolerance ) return false;

		}

		return true;
	}

	public function intersectRay( ray:Ray, target:Vector3 ):Vector3 {

		// based on "Fast Ray-Convex Polyhedron Intersection" by Eric Haines, GRAPHICS GEMS II

		const faces = this.faces;

		var tNear = - Number.MAX_VALUE;
		var tFar = Number.MAX_VALUE;

		for ( i in 0...faces.length ) {

			const face = faces[ i ];

			// interpret faces as planes for the further computation

			const vN = face.distanceToPoint( ray.origin );
			const vD = face.normal.dot( ray.direction );

			// if the origin is on the positive side of a plane (so the plane can "see" the origin) and
			// the ray is turned away or parallel to the plane, there is no intersection

			if ( vN > 0 && vD >= 0 ) return null;

			// compute the distance from the ray’s origin to the intersection with the plane

			const t = ( vD !== 0 ) ? ( - vN / vD ) : 0;

			// only proceed if the distance is positive. a negative distance means the intersection point
			// lies "behind" the origin

			if ( t <= 0 ) continue;

			// now categorized plane as front-facing or back-facing

			if ( vD > 0 ) {

				// plane faces away from the ray, so this plane is a back-face

				tFar = Math.min( t, tFar );

			} else {

				// front-face

				tNear = Math.max( t, tNear );

			}

			if ( tNear > tFar ) {

				// if tNear ever is greater than tFar, the ray must miss the convex hull

				return null;

			}

		}

		// evaluate intersection point

		// always try tNear first since its the closer intersection point

		if ( tNear !== - Number.MAX_VALUE ) {

			ray.at( tNear, target );

		} else {

			ray.at( tFar, target );

		}

		return target;
	}

	public function intersectsRay( ray:Ray ):Bool {

		return this.intersectRay( ray, _v1 ) !== null;
	}

	public function makeEmpty() {

		this.faces = [];
		this.vertices = [];

		return this;
	}

	// Adds a vertex to the 'assigned' list of vertices and assigns it to the given face
	public function addVertexToFace( vertex:VertexNode, face:Face ):ConvexHull {

		vertex.face = face;

		if ( face.outside === null ) {

			this.assigned.append( vertex );

		} else {

			this.assigned.insertBefore( face.outside, vertex );

		}

		face.outside = vertex;

		return this;
	}

	// Removes a vertex from the 'assigned' list of vertices and from the given face
	public function removeVertexFromFace( vertex:VertexNode, face:Face ):ConvexHull {

		if ( vertex === face.outside ) {

			// fix face.outside link

			if ( vertex.next !== null && vertex.next.face === face ) {

				// face has at least 2 outside vertices, move the 'outside' reference

				face.outside = vertex.next;

			} else {

				// vertex was the only outside vertex that face had

				face.outside = null;

			}

		}

		this.assigned.remove( vertex );

		return this;
	}

	// Removes all the visible vertices that a given face is able to see which are stored in the 'assigned' vertex list
	public function removeAllVerticesFromFace( face:Face ):VertexNode {

		if ( face.outside !== null ) {

			// reference to the first and last vertex of this face

			var start:VertexNode = face.outside;
			var end:VertexNode = start;

			while ( end.next !== null && end.next.face === face ) {

				end = end.next;

			}

			this.assigned.removeSubList( start, end );

			// fix references

			start.prev = end.next = null;
			face.outside = null;

			return start;

		}

	}

	// Removes all the visible vertices that 'face' is able to see
	public function deleteFaceVertices( face:Face, absorbingFace:Dynamic ):ConvexHull {

		const faceVertices = this.removeAllVerticesFromFace( face );

		if ( faceVertices !== undefined ) {

			if ( absorbingFace === null ) {

				// mark the vertices to be reassigned to some other face

				this.unassigned.appendChain( faceVertices );


			} else {

				// if there's an absorbing face try to assign as many vertices as possible to it

				var vertex:VertexNode = faceVertices;

				while ( vertex !== null ) {

					// buffer 'next' reference, see .deleteFaceVertices()
					var nextVertex:VertexNode = vertex.next;

					const distance = absorbingFace.distanceToPoint( vertex.point );

					// check if 'vertex' is able to see 'absorbingFace'

					if ( distance > this.tolerance ) {

						this.addVertexToFace( vertex, absorbingFace );

					} else {

						this.unassigned.append( vertex );

					}

					// now assign next vertex

					vertex = nextVertex;

				}

			}

		}

		return this;

	}

	// Reassigns as many vertices as possible from the unassigned list to the new faces
	public function resolveUnassignedPoints( newFaces:Array<Face> ):ConvexHull {

		if ( this.unassigned.isEmpty() === false ) {

			var vertex = this.unassigned.first();

			while ( vertex !== null ) {

				// buffer 'next' reference, see .deleteFaceVertices()
				var nextVertex = vertex.next;

				var maxDistance = this.tolerance;

				var maxFace = null;

				for ( i in 0...newFaces.length ) {

					const face = newFaces[ i ];

					if ( face.mark === Visible ) {

						const distance = face.distanceToPoint( vertex.point );

						if ( distance > maxDistance ) {

							maxDistance = distance;
							maxFace = face;

						}

						if ( maxDistance > 1000 * this.tolerance ) break;

					}

				}

				// 'maxFace' can be null e.g. if there are identical vertices

				if ( maxFace !== null ) {

					this.addVertexToFace( vertex, maxFace );

				}

				vertex = nextVertex;

			}

		}

		return this;

	}

	// Computes the extremes of a simplex which will be the initial hull
	public function computeExtremes():Array<Array<VertexNode>> {

		const min = new Vector3();
		const max = new Vector3();

		const minVertices = [];
		const maxVertices = [];

		// initially assume that the first vertex is the min/max

		for ( i in 0...3 ) {

			minVertices[ i ] = maxVertices[ i ] = this.vertices[ 0 ];

		}

		min.copy( this.vertices[ 0 ].point );
		max.copy( this.vertices[ 0 ].point );

		// compute the min/max vertex on all six directions

		for ( i in 0...this.vertices.length ) {

			const vertex = this.vertices[ i ];
			const point = vertex.point;

			// update the min coordinates

			for ( j in 0...3 ) {

				if ( point.getComponent( j ) < min.getComponent( j ) ) {

					min.setComponent( j, point.getComponent( j ) );
					minVertices[ j ] = vertex;

				}

			}

			// update the max coordinates

			for ( j in 0...3 ) {

				if ( point.getComponent( j ) > max.getComponent( j ) ) {

					max.setComponent( j, point.getComponent( j ) );
					maxVertices[ j ] = vertex;

				}

			}

		}

		// use min/max vectors to compute an optimal epsilon

		this.tolerance = 3 * Math.EPSILON * (
			Math.max( Math.abs( min.x ), Math.abs( max.x ) ) +
			Math.max( Math.abs( min.y ), Math.abs( max.y ) ) +
			Math.max( Math.abs( min.z ), Math.abs( max.z ) )
		);

		return { min: minVertices, max: maxVertices };

	}

	// Computes the initial simplex assigning to its faces all the points
	// that are candidates to form part of the hull
	public function computeInitialHull() {

		const vertices = this.vertices;
		const extremes = this.computeExtremes();
		const min = extremes.min;
		const max = extremes.max;

		// 1. Find the two vertices 'v0' and 'v1' with the greatest 1d separation
		// (max.x - min.x)
		// (max.y - min.y)
		// (max.z - min.z)

		var maxDistance = 0;
		var index = 0;

		for ( i in 0...3 ) {

			const distance = max[ i ].point.getComponent( i ) - min[ i ].point.getComponent( i );

			if ( distance > maxDistance ) {

				maxDistance = distance;
				index = i;

			}

		}

		var v0 = min[ index ];
		var v1 = max[ index ];
		var v2;
		var v3;

		// 2. The next vertex 'v2' is the one farthest to the line formed by 'v0' and 'v1'

		maxDistance = 0;
		_line3.set( v0.point, v1.point );

		for ( i in 0...vertices.length ) {

			const vertex = vertices[ i ];

			if ( vertex !== v0 && vertex !== v1 ) {

				_line3.closestPointToPoint( vertex.point, true, _closestPoint );

				const distance = _closestPoint.distanceToSquared( vertex.point );

				if ( distance > maxDistance ) {

					maxDistance = distance;
					v2 = vertex;

				}

			}

		}

		// 3. The next vertex 'v3' is the one farthest to the plane 'v0', 'v1', 'v2'

		maxDistance = -1;
		_plane.setFromCoplanarPoints( v0.point, v1.point, v2.point );

		for ( i in 0...vertices.length ) {

			const vertex = vertices[ i ];

			if ( vertex !== v0 && vertex !== v1 && vertex !== v2 ) {

				const distance = Math.abs( _plane.distanceToPoint( vertex.point ) );

				if ( distance > maxDistance ) {

					maxDistance = distance;
					v3 = vertex;

				}

			}

		}

		const faces = [];

		if ( _plane.distanceToPoint( v3.point ) < 0 ) {

			// the face is not able to see the point so 'plane.normal' is pointing outside the tetrahedron

			faces.push(
				Face.create( v0, v1, v2 ),
				Face.create( v3, v1, v0 ),
				Face.create( v3, v2, v1 ),
				Face.create( v3, v0, v2 )
			);

			// set the twin edge

			for ( i in 0...3 ) {

				const j = ( i + 1 ) % 3;

				// join face[ i ] i > 0, with the first face
				faces[ i + 1 ].getEdge( 2 ).setTwin( faces[ 0 ].getEdge( j ) );

				// join face[ i ] with face[ i + 1 ], 1 <= i <= 3
				faces[ i + 1 ].getEdge( 0 ).setTwin( faces[ j + 1 ].getEdge( 0 ) );

			}

		} else {

			// the face is able to see the point so 'plane.normal' is pointing inside the tetrahedron

			faces.push(
				Face.create( v0, v2, v1 ),
				Face.create( v3, v0, v1 ),
				Face.create( v3, v1, v2 ),
				Face.create( v3, v2, v0 )
			);

			// set the twin edge

			for ( i in 0...3 ) {

				const j = ( i + 1 ) % 3;

				// join face[ i ] i > 0, with the first face
				faces[ i + 1 ].getEdge( 2 ).setTwin( faces[ 0 ].getEdge( ( 3 - i ) % 3 ) );

				// join face[ i ] with face[ i + 1 ]
				faces[ i + 1 ].getEdge( 0 ).setTwin( faces[ j + 1 ].getEdge( 1 ) );

			}

		}

		// the initial hull is the tetrahedron

		for ( i in 0...4 ) {

			this.faces.push( faces[ i ] );

		}

		// initial assignment of vertices to the faces of the tetrahedron

		for ( i in 0...vertices.length ) {

			const vertex = vertices[ i ];

			if ( vertex !== v0 && vertex !== v1 && vertex !== v2 && vertex !== v3 ) {

				maxDistance = this.tolerance;
				var maxFace = null;

				for ( j in 0...4 ) {

					const distance = this.faces[ j ].distanceToPoint( vertex.point );

					if ( distance > maxDistance ) {

						maxDistance = distance;
						maxFace = this.faces[ j ];

					}

				}

				if ( maxFace !== null ) {

					this.addVertexToFace( vertex, maxFace );

				}

			}

		}

		return this;

	}

	// Removes inactive faces
	public function reindexFaces() {

		const activeFaces = [];

		for ( i in 0...this.faces.length ) {

			const face = this.faces[ i ];

			if ( face.mark === Visible ) {

				activeFaces.push( face );

			}

		}

		this.faces = activeFaces;

		return this;

	}

	// Finds the next vertex to create faces with the current hull
	public function nextVertexToAdd() {

		// if the 'assigned' list of vertices is empty, no vertices are left. return with 'undefined'

		if ( this.assigned.isEmpty() === false ) {

			var eyeVertex, maxDistance = 0;

			// grap the first available face and start with the first visible vertex of that face

			const eyeFace = this.assigned.first().face;
			var vertex = eyeFace.outside;

			// now calculate the farthest vertex that face can see

			while ( vertex !== null && vertex.face === eyeFace ) {

				const distance = eyeFace.distanceToPoint( vertex.point );

				if ( distance > maxDistance ) {

					maxDistance = distance;
					eyeVertex = vertex;

				}

				vertex = vertex.next;

			}

			return eyeVertex;

		}

	}

	// Computes a chain of half edges in CCW order called the 'horizon'.
	// For an edge to be part of the horizon it must join a face that can see
	// 'eyePoint' and a face that cannot see 'eyePoint'.

	public function computeHorizon( eyePoint:Vector3, crossEdge:Edge, face:Face, horizon:Array<Edge> ):ConvexHull {

		// moves face's vertices to the 'unassigned' vertex list

		this.deleteFaceVertices( face, null );

		face.mark = Deleted;

		var edge = crossEdge;

		while ( edge !== null ) {

			const twinEdge = edge.twin;
			const oppositeFace = twinEdge.face;

			if ( oppositeFace.mark === Visible ) {

				if ( oppositeFace.distanceToPoint( eyePoint ) > this.tolerance ) {

					// the opposite face can see the vertex, so proceed with next edge

					this.computeHorizon( eyePoint, twinEdge, oppositeFace, horizon );

				} else {

					// the opposite face can't see the vertex, so this edge is part of the horizon

					horizon.push( edge );

				}

			}

			edge = edge.next;

		}

		return this;

	}

	// Creates a face with the vertices 'eyeVertex.point', 'horizonEdge.tail' and 'horizonEdge.head' in CCW order

	public function addAdjoiningFace( eyeVertex:VertexNode, horizonEdge:Edge ):Edge {

		// all the half edges are created in ccw order thus the face is always pointing outside the hull

		const face = Face.create( eyeVertex, horizonEdge.tail(), horizonEdge.head() );

		this.faces.push( face );

		// join face.getEdge( - 1 ) with the horizon's opposite edge face.getEdge( - 1 ) = face.getEdge( 2 )

		face.getEdge( - 1 ).setTwin( horizonEdge.twin );

		return face.getEdge( 0 ); // the half edge whose vertex is the eyeVertex


	}

	//  Adds 'horizon.length' faces to the hull, each face will be linked with the
	//  horizon opposite face and the face on the left/right

	public function addNewFaces( eyeVertex:VertexNode, horizon:Array<Edge> ):ConvexHull {

		this.newFaces = [];

		var firstSideEdge = null;
		var previousSideEdge = null;

		for ( i in 0...horizon.length ) {

			const horizonEdge = horizon[ i ];

			// returns the right side edge

			const sideEdge = this.addAdjoiningFace( eyeVertex, horizonEdge );

			if ( firstSideEdge === null ) {

				firstSideEdge = sideEdge;

			} else {

				// joins face.getEdge( 1 ) with previousFace.getEdge( 0 )
				sideEdge.next.setTwin( previousSideEdge );

			}

			this.newFaces.push( sideEdge.face );
			previousSideEdge = sideEdge;

		}

		// perform final join of new faces

		firstSideEdge.next.setTwin( previousSideEdge );

		return this;

	}

	// Adds a vertex to the hull

	public function addVertexToHull( eyeVertex:VertexNode ):ConvexHull {

		const horizon = [];

		this.unassigned.clear();

		// remove 'eyeVertex' from 'eyeVertex.face' so that it can't be added to the 'unassigned' vertex list

		this.removeVertexFromFace( eyeVertex, eyeVertex.face );

		this.computeHorizon( eyeVertex.point, null, eyeVertex.face, horizon );

		this.addNewFaces( eyeVertex, horizon );

		// reassign 'unassigned' vertices to the new faces

		this.resolveUnassignedPoints( this.newFaces );

		return	this;

	}

	public function cleanup() {

		this.assigned.clear();
		this.unassigned.clear();
		this.newFaces = [];

		return this;

	}

	public function compute() {

		let vertex:VertexNode;

		this.computeInitialHull();

		// add all available vertices gradually to the hull

		while ( ( vertex = this.nextVertexToAdd() ) !== null ) {

			this.addVertexToHull( vertex );

		}

		this.reindexFaces();

		this.cleanup();

		return this;

	}

}