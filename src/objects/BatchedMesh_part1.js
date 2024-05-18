class MultiDrawRenderList {

	constructor() {

		this.index = 0;
		this.pool = [];
		this.list = [];

	}

	push( drawRange, z ) {

		const pool = this.pool;
		const list = this.list;
		if ( this.index >= pool.length ) {

			pool.push( {

				start: - 1,
				count: - 1,
				z: - 1,

			} );

		}

		const item = pool[ this.index ];
		list.push( item );
		this.index ++;

		item.start = drawRange.start;
		item.count = drawRange.count;
		item.z = z;

	}

	reset() {

		this.list.length = 0;
		this.index = 0;

	}

}