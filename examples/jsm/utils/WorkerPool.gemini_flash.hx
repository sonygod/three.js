import js.html.Worker;
import js.html.MessageEvent;

class WorkerPool {

	public var pool:Int;
	public var queue:Array<{resolve:Dynamic->Void; msg:Dynamic; transfer:Array<Dynamic>}> = [];
	public var workers:Array<Worker> = [];
	public var workersResolve:Array<Dynamic->Void> = [];
	public var workerStatus:Int = 0;
	public var workerCreator:() -> Worker;

	public function new(pool:Int = 4) {
		this.pool = pool;
	}

	private function _initWorker(workerId:Int) {
		if (workers.length <= workerId) {
			var worker = workerCreator();
			worker.addEventListener('message', _onMessage.bind(this, workerId));
			workers[workerId] = worker;
		}
	}

	private function _getIdleWorker():Int {
		for (i in 0...pool) {
			if ((workerStatus & (1 << i)) == 0) {
				return i;
			}
		}
		return -1;
	}

	private function _onMessage(workerId:Int, msg:MessageEvent) {
		var resolve = workersResolve[workerId];
		if (resolve != null) {
			resolve(msg.data);
		}
		if (queue.length > 0) {
			var {resolve, msg, transfer} = queue.shift();
			workersResolve[workerId] = resolve;
			workers[workerId].postMessage(msg, transfer);
		} else {
			workerStatus ^= 1 << workerId;
		}
	}

	public function setWorkerCreator(workerCreator:() -> Worker) {
		this.workerCreator = workerCreator;
	}

	public function setWorkerLimit(pool:Int) {
		this.pool = pool;
	}

	public function postMessage(msg:Dynamic, transfer:Array<Dynamic> = []):Dynamic {
		return new Promise((resolve) -> {
			var workerId = _getIdleWorker();
			if (workerId != -1) {
				_initWorker(workerId);
				workerStatus |= 1 << workerId;
				workersResolve[workerId] = resolve;
				workers[workerId].postMessage(msg, transfer);
			} else {
				queue.push({resolve:resolve, msg:msg, transfer:transfer});
			}
		});
	}

	public function dispose() {
		for (worker in workers) {
			worker.terminate();
		}
		workersResolve.length = 0;
		workers.length = 0;
		queue.length = 0;
		workerStatus = 0;
	}
}


**Explanation of Changes:**

* **Classes and Types:** Haxe uses classes instead of `export class`. We define the `WorkerPool` class directly. Haxe also has a strong type system, so we use `Int`, `Array`, `Dynamic`, and `Promise` instead of their JavaScript equivalents.
* **`Promise`:** Haxe's `Promise` class is used for asynchronous operations, replacing the `new Promise` syntax.
* **`addEventListener`:** The `addEventListener` syntax remains similar, but we use `bind` to properly bind the `_onMessage` callback within the scope of the `WorkerPool` instance.
* **`postMessage`:** The `postMessage` method uses the `transfer` array to transfer data efficiently between workers.
* **`workerCreator`:** This function is now defined as a property of the `WorkerPool` class to provide a way to create workers dynamically.
* **`dispose`:** The `dispose` method terminates all workers and clears the internal structures to release resources.

**Example Usage:**


class Main {
	static function main() {
		var pool = new WorkerPool(2);
		pool.setWorkerCreator(() -> {
			return new Worker("my_worker.js"); // Replace with your worker script
		});

		// Send a message to the worker pool
		pool.postMessage("Hello from Haxe!").then((msg) => {
			trace("Worker replied: " + msg);
		});

		// Later, dispose the worker pool
		pool.dispose();
	}
}