/**
 * @author Deepkolos / https://github.com/deepkolos
 */

class WorkerPool {
    private var pool:Int;
    private var queue:Array<{ resolve:Dynamic, msg:Dynamic, transfer:Dynamic }>;
    private var workers:Array<Dynamic>;
    private var workersResolve:Array<Dynamic>;
    private var workerStatus:Int;

    public function new(pool:Int = 4) {
        this.pool = pool;
        this.queue = [];
        this.workers = [];
        this.workersResolve = [];
        this.workerStatus = 0;
    }

    private function _initWorker(workerId:Int) {
        if (this.workers[workerId] == null) {
            var worker = this.workerCreator();
            worker.addEventListener('message', this._onMessage.bind(this, workerId));
            this.workers[workerId] = worker;
        }
    }

    private function _getIdleWorker():Int {
        for (i in 0...this.pool) {
            if ((this.workerStatus & (1 << i)) == 0) {
                return i;
            }
        }
        return -1;
    }

    private function _onMessage(workerId:Int, msg:Dynamic) {
        var resolve = this.workersResolve[workerId];
        if (resolve != null) {
            resolve(msg);
        }

        if (this.queue.length > 0) {
            var item = this.queue.shift();
            this.workersResolve[workerId] = item.resolve;
            this.workers[workerId].postMessage(item.msg, item.transfer);
        } else {
            this.workerStatus ^= 1 << workerId;
        }
    }

    public function setWorkerCreator(workerCreator:Dynamic) {
        this.workerCreator = workerCreator;
    }

    public function setWorkerLimit(pool:Int) {
        this.pool = pool;
    }

    public function postMessage(msg:Dynamic, transfer:Dynamic):Dynamic {
        return new Promise(function(resolve) {
            var workerId = _getIdleWorker();
            if (workerId != -1) {
                _initWorker(workerId);
                workerStatus |= 1 << workerId;
                workersResolve[workerId] = resolve;
                workers[workerId].postMessage(msg, transfer);
            } else {
                queue.push({ resolve: resolve, msg: msg, transfer: transfer });
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