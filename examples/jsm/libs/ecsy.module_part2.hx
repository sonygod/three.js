package three.js.examples.jsm.libs;

class ObjectPool<T> {
  public var freeList:Array<T> = [];
  public var count:Int = 0;
  public var T:Class<T>;
  public var isObjectPool:Bool = true;

  public function new(T:Class<T>, initialSize:Int = 0) {
    this.T = T;
    if (initialSize != 0) {
      expand(initialSize);
    }
  }

  public function acquire():T {
    if (freeList.length <= 0) {
      expand(Math.round(count * 0.2) + 1);
    }
    return freeList.pop();
  }

  public function release(item:T):Void {
    item.reset();
    freeList.push(item);
  }

  public function expand(count:Int):Void {
    for (i in 0...count) {
      var clone:T = Type.createInstance(T, []);
      clone._pool = this;
      freeList.push(clone);
    }
    this.count += count;
  }

  public function totalSize():Int {
    return count;
  }

  public function totalFree():Int {
    return freeList.length;
  }

  public function totalUsed():Int {
    return count - freeList.length;
  }
}