/**
 * @author Deepkolos / https://github.com/deepkolos
 */

class WorkerPool {

	var pool:Int;
	var queue:Array<{resolve:Dynamic->Void, msg:Dynamic, transfer:Array<Dynamic>}>;
	var workers:Array<Worker>;
	var workersResolve:Array<Dynamic->Void>;
	var workerStatus:Int;
	var workerCreator:Dynamic->Worker;

	public function new(pool:Int = 4) {
		this.pool = pool;
		this.queue = [];
		this.workers = [];
		this.workersResolve = [];
		this.workerStatus = 0;
	}

	private function _initWorker(workerId:Int):Void {
		if (!this.workers[workerId]) {
			var worker = this.workerCreator();
			worker.onmessage = (msg) -> this._onMessage(workerId, msg);
			this.workers[workerId] = worker;
		}
	}

	private function _getIdleWorker():Int {
		for (workerId in 0...this.pool) {
			if (!(this.workerStatus & (1 << workerId))) return workerId;
		}
		return -1;
	}

	private function _onMessage(workerId:Int, msg:Dynamic):Void {
		var resolve = this.workersResolve[workerId];
		if (resolve != null) resolve(msg);
		if (this.queue.length > 0) {
			var {resolve, msg, transfer} = this.queue.shift();
			this.workersResolve[workerId] = resolve;
			this.workers[workerId].postMessage(msg, transfer);
		} else {
			this.workerStatus ^= 1 << workerId;
		}
	}

	public function setWorkerCreator(workerCreator:Dynamic->Worker):Void {
		this.workerCreator = workerCreator;
	}

	public function setWorkerLimit(pool:Int):Void {
		this.pool = pool;
	}

	public function postMessage(msg:Dynamic, transfer:Array<Dynamic>):Promise<Dynamic> {
		return new Promise((resolve) -> {
			var workerId = this._getIdleWorker();
			if (workerId != -1) {
				this._initWorker(workerId);
				this.workerStatus |= 1 << workerId;
				this.workersResolve[workerId] = resolve;
				this.workers[workerId].postMessage(msg, transfer);
			} else {
				this.queue.push({resolve: resolve, msg: msg, transfer: transfer});
			}
		});
	}

	public function dispose():Void {
		for (worker in this.workers) worker.terminate();
		this.workersResolve.length = 0;
		this.workers.length = 0;
		this.queue.length = 0;
		this.workerStatus = 0;
	}
}