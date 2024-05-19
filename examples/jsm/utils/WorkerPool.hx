package three.js.examples.jvm.utils;

import js.html.WebWorker;
import js.lib.Promise;

class WorkerPool {

    public var pool(default, null):Int;
    public var queue(default, null):Array_queues;
    public var workers(default, null):Array<WebWorker>;
    public var workersResolve(default, null):Array<Dynamic>;
    public var workerStatus(default, null):Int;
    public var workerCreator(default, null):Void->WebWorker;

    public function new(pool:Int = 4) {
        this.pool = pool;
        this.queue = [];
        this.workers = [];
        this.workersResolve = [];
        this.workerStatus = 0;
    }

    private function _initWorker(workerId:Int) {
        if (this.workers[workerId] == null) {
            var worker:WebWorker = this.workerCreator();
            worker.addEventListener('message', function(e) { _onMessage(workerId, e); });
            this.workers[workerId] = worker;
        }
    }

    private function _getIdleWorker():Int {
        for (i in 0...this.pool) {
            if ((this.workerStatus & (1 << i)) == 0) return i;
        }
        return -1;
    }

    private function _onMessage(workerId:Int, msg:Dynamic) {
        var resolve:Dynamic = this.workersResolve[workerId];
        if (resolve != null) resolve(msg);
        if (this.queue.length > 0) {
            var queueItem = this.queue.shift();
            this.workersResolve[workerId] = queueItem.resolve;
            this.workers[workerId].postMessage(queueItem.msg, queueItem.transfer);
        } else {
            this.workerStatus ^= 1 << workerId;
        }
    }

    public function setWorkerCreator(workerCreator:Void->WebWorker) {
        this.workerCreator = workerCreator;
    }

    public function setWorkerLimit(pool:Int) {
        this.pool = pool;
    }

    public function postMessage(msg:Dynamic, transfer:Array<Dynamic>):Promise<Dynamic> {
        return new Promise(function(resolve) {
            var workerId:Int = _getIdleWorker();
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