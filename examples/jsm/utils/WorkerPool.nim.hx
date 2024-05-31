/**
 * @author Deepkolos / https://github.com/deepkolos
 */

class WorkerPool {

	var pool:Int;
	var queue:Array<Dynamic>;
	var workers:Array<Dynamic>;
	var workersResolve:Array<Dynamic>;
	var workerStatus:Int;
	var workerCreator:Dynamic;

	public function new( pool:Int = 4 ) {

		this.pool = pool;
		this.queue = [];
		this.workers = [];
		this.workersResolve = [];
		this.workerStatus = 0;

	}

	private function _initWorker( workerId:Int ) {

		if ( ! this.workers[ workerId ] ) {

			var worker = this.workerCreator();
			worker.addEventListener( 'message', this._onMessage.bind( this, workerId ) );
			this.workers[ workerId ] = worker;

		}

	}

	private function _getIdleWorker() {

		for ( i in 0...this.pool )
			if ( ! ( this.workerStatus & ( 1 << i ) ) ) return i;

		return - 1;

	}

	private function _onMessage( workerId:Int, msg:Dynamic ) {

		var resolve = this.workersResolve[ workerId ];
		if (resolve != null) resolve( msg );

		if ( this.queue.length > 0 ) {

			var { resolve, msg, transfer } = this.queue.shift();
			this.workersResolve[ workerId ] = resolve;
			this.workers[ workerId ].postMessage( msg, transfer );

		} else {

			this.workerStatus ^= 1 << workerId;

		}

	}

	public function setWorkerCreator( workerCreator:Dynamic ) {

		this.workerCreator = workerCreator;

	}

	public function setWorkerLimit( pool:Int ) {

		this.pool = pool;

	}

	public function postMessage( msg:Dynamic, transfer:Dynamic ) {

		return new Promise( function( resolve:Dynamic ) {

			var workerId = this._getIdleWorker();

			if ( workerId != - 1 ) {

				this._initWorker( workerId );
				this.workerStatus |= 1 << workerId;
				this.workersResolve[ workerId ] = resolve;
				this.workers[ workerId ].postMessage( msg, transfer );

			} else {

				this.queue.push( { resolve, msg, transfer } );

			}

		} );

	}

	public function dispose() {

		for ( worker in this.workers ) worker.terminate();
		this.workersResolve.length = 0;
		this.workers.length = 0;
		this.queue.length = 0;
		this.workerStatus = 0;

	}

}