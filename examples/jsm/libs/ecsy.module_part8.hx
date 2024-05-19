Here is the converted Haxe code:
```
package three.js.examples.jsm.libs;

import haxe.ds.GenericStack;

class EntityPool extends ObjectPool<Entity> {
  var entityManager:EntityManager;
  var freeList:GenericStack<Entity>;
  var count:Int;

  public function new(entityManager:EntityManager, entityClass:Class<Entity>, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    this.freeList = new GenericStack<Entity>();

    if (initialSize != 0) {
      expand(initialSize);
    }
  }

  public function expand(count:Int) {
    for (n in 0...count) {
      var clone:Entity = Type.createInstance(entityClass, [entityManager]);
      clone._pool = this;
      freeList.add(clone);
    }
    count += count;
  }
}
```
Note:

* In Haxe, we need to specify the type parameters for the `ObjectPool` class, so I added `<Entity>` to indicate that it's a pool of `Entity` objects.
* I replaced `typeof initialSize !== "undefined"` with `initialSize != 0`, since in Haxe, `initialSize` will be `0` if it's not provided as an argument.
* I replaced `this.T` with `entityClass`, since `entityClass` is the type parameter that represents the class of the objects in the pool.
* I replaced `push` with `add`, since `GenericStack` uses `add` to add elements to the stack.
* I replaced `this.count += count` with `count += count`, since `count` is a local variable in the `expand` method.