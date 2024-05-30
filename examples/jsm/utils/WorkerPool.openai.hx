package three.js.examples.jsm.utils;

class WorkerPool {
    public var pool:Int;
    public var queue:Array<{resolve:Dynamic, msg:Any, transfer:Any}>;
    public var workers:Array<js.html.Worker>;
    public var workersResolve:Array<Dynamic>;
    public var workerStatus:Int;
    public var workerCreator:Void->js.html.Worker;

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
            worker.addEventListener("message", _onMessage.bind(this, workerId));
            this.workers[workerId] = worker;
        }
    }

    private function _getIdleWorker():Int {
        for (i in 0...this.pool) {
            if ((this.workerStatus & (1 << i)) == 0) return i;
        }
        return -1;
    }

    private function _onMessage(workerId:Int, msg:Any) {
        var resolve = this.workersResolve[workerId];
        if (resolve != null) resolve(msg);

        if (this.queue.length > 0) {
            var { resolve, msg, transfer } = this.queue.shift();
            this.workersResolve[workerId] = resolve;
            this.workers[workerId].postMessage(msg, transfer);
        } else {
            this.workerStatus ^= 1 << workerId;
        }
    }

    public function setWorkerCreator(workerCreator:Void->js.html.Worker) {
        this.workerCreator = workerCreator;
    }

    public function setWorkerLimit(pool:Int) {
        this.pool = pool;
    }

    public function postMessage(msg:Any, transfer:Any):Promise<Any> {
        return new Promise((resolve) => {
            var workerId = _getIdleWorker();
            if (workerId != -1) {
                _initWorker(workerId);
                this.workerStatus |= 1 << workerId;
                this.workersResolve[workerId] = resolve;
                this.workers[workerId].postMessage(msg, transfer);
            } else {
                this.queue.push({ resolve: resolve, msg: msg, transfer: transfer });
            }
        });
    }

    public function dispose() {
        for (worker in this.workers) {
            worker.terminate();
        }
        this.workersResolve = [];
        this.workers = [];
        this.queue = [];
        this.workerStatus = 0;
    }
}