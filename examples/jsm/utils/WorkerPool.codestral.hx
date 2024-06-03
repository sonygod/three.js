import js.html.Worker;
import js.html.MessageEvent;

class WorkerPool {

    private var pool:Int;
    private var queue:Array<Dynamic>;
    private var workers:Array<Worker>;
    private var workersResolve:Array<Dynamic>;
    private var workerStatus:Int;
    private var workerCreator:Dynamic;

    public function new(pool:Int = 4) {
        this.pool = pool;
        this.queue = new Array<Dynamic>();
        this.workers = new Array<Worker>();
        this.workersResolve = new Array<Dynamic>();
        this.workerStatus = 0;
    }

    private function _initWorker(workerId:Int):Void {
        if (this.workers[workerId] == null) {
            var worker = this.workerCreator();
            worker.addEventListener("message", (e:MessageEvent) => this._onMessage(workerId, e));
            this.workers[workerId] = worker;
        }
    }

    private function _getIdleWorker():Int {
        for (var i:Int = 0; i < this.pool; i++) {
            if ((this.workerStatus & (1 << i)) == 0) return i;
        }
        return -1;
    }

    private function _onMessage(workerId:Int, msg:MessageEvent):Void {
        var resolve = this.workersResolve[workerId];
        if (resolve != null) resolve(msg);

        if (this.queue.length > 0) {
            var task = this.queue.shift();
            this.workersResolve[workerId] = task.resolve;
            this.workers[workerId].postMessage(task.msg, task.transfer);
        } else {
            this.workerStatus ^= 1 << workerId;
        }
    }

    public function setWorkerCreator(workerCreator:Dynamic):Void {
        this.workerCreator = workerCreator;
    }

    public function setWorkerLimit(pool:Int):Void {
        this.pool = pool;
    }

    public function postMessage(msg:Dynamic, transfer:Array<Dynamic>):Promise<Dynamic> {
        return new Promise((resolve, reject) => {
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
        for (var worker in this.workers) {
            worker.terminate();
        }
        this.workersResolve = [];
        this.workers = [];
        this.queue = [];
        this.workerStatus = 0;
    }
}