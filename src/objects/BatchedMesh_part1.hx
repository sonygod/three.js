package three.js.src.objects;

class MultiDrawRenderList {
    public var index:Int;
    public var pool:Array<Dynamic>;
    public var list:Array<Dynamic>;

    public function new() {
        index = 0;
        pool = new Array<Dynamic>();
        list = new Array<Dynamic>();
    }

    public function push(drawRange:Dynamic, z:Float) {
        var pool = this.pool;
        var list = this.list;
        if (this.index >= pool.length) {
            pool.push({
                start: -1,
                count: -1,
                z: -1
            });
        }

        var item = pool[this.index];
        list.push(item);
        this.index++;

        item.start = drawRange.start;
        item.count = drawRange.count;
        item.z = z;
    }

    public function reset() {
        list.splice(0, list.length);
        this.index = 0;
    }
}