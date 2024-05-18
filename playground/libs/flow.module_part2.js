class PointerMonitor {

	constructor() {

		this.x = 0;
		this.y = 0;
		this.started = false;

		this._onMoveEvent = ( e ) => {

			const event = e.touches ? e.touches[ 0 ] : e;

			this.x = event.clientX;
			this.y = event.clientY;

		};

	}

	start() {

		if ( this.started ) return;

		this.started = true;

		window.addEventListener( 'wheel', this._onMoveEvent, true );

		window.addEventListener( 'mousedown', this._onMoveEvent, true );
		window.addEventListener( 'touchstart', this._onMoveEvent, true );

		window.addEventListener( 'mousemove', this._onMoveEvent, true );
		window.addEventListener( 'touchmove', this._onMoveEvent, true );

		window.addEventListener( 'dragover', this._onMoveEvent, true );

		return this;

	}

}