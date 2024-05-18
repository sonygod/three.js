class HalfEdge {


	constructor( vertex, face ) {

		this.vertex = vertex;
		this.prev = null;
		this.next = null;
		this.twin = null;
		this.face = face;

	}

	head() {

		return this.vertex;

	}

	tail() {

		return this.prev ? this.prev.vertex : null;

	}

	length() {

		const head = this.head();
		const tail = this.tail();

		if ( tail !== null ) {

			return tail.point.distanceTo( head.point );

		}

		return - 1;

	}

	lengthSquared() {

		const head = this.head();
		const tail = this.tail();

		if ( tail !== null ) {

			return tail.point.distanceToSquared( head.point );

		}

		return - 1;

	}

	setTwin( edge ) {

		this.twin = edge;
		edge.twin = this;

		return this;

	}

}