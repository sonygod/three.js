package three.js.examples.jm.libs;

import haxe.Timer;
import js.html.CustomEvent;
import js.html.Window;

class World {
  public var options:Dynamic;
  public var componentsManager:ComponentManager;
  public var entityManager:EntityManager;
  public var systemManager:SystemManager;
  public var enabled:Bool;
  public var eventQueues:Dynamic;
  public var lastTime:Float;

  public function new(?options:Dynamic) {
    this.options = merge(DEFAULT_OPTIONS, options);

    this.componentsManager = new ComponentManager(this);
    this.entityManager = new EntityManager(this);
    this.systemManager = new SystemManager(this);

    this.enabled = true;

    this.eventQueues = {};

    if (hasWindow && typeof CustomEvent != "undefined") {
      var event = new CustomEvent("ecsy-world-created", { detail: { world: this, version: Version } });
      untyped window.dispatchEvent(event);
    }

    this.lastTime = Timer.stamp();
  }

  public function registerComponent(Component:Dynamic, objectPool:Dynamic):World {
    this.componentsManager.registerComponent(Component, objectPool);
    return this;
  }

  public function registerSystem(System:Dynamic, attributes:Dynamic):World {
    this.systemManager.registerSystem(System, attributes);
    return this;
  }

  public function hasRegisteredComponent(Component:Dynamic):Bool {
    return this.componentsManager.hasComponent(Component);
  }

  public function unregisterSystem(System:Dynamic):World {
    this.systemManager.unregisterSystem(System);
    return this;
  }

  public function getSystem(SystemClass:Dynamic):Dynamic {
    return this.systemManager.getSystem(SystemClass);
  }

  public function getSystems():Array<Dynamic> {
    return this.systemManager.getSystems();
  }

  public function execute(?delta:Float, time:Float):Void {
    if (delta == null) {
      time = Timer.stamp();
      delta = time - this.lastTime;
      this.lastTime = time;
    }

    if (this.enabled) {
      this.systemManager.execute(delta, time);
      this.entityManager.processDeferredRemoval();
    }
  }

  public function stop():Void {
    this.enabled = false;
  }

  public function play():Void {
    this.enabled = true;
  }

  public function createEntity(name:String):Dynamic {
    return this.entityManager.createEntity(name);
  }

  public function stats():Dynamic {
    var stats = {
      entities: this.entityManager.stats(),
      system: this.systemManager.stats(),
    };

    return stats;
  }
}