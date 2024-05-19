package three.js.examples.jmx.libs;

class SystemManager {
  private var _systems:Array<System>;
  private var _executeSystems:Array<System>;
  public var world:World;
  public var lastExecutedSystem:System;

  public function new(world:World) {
    _systems = [];
    _executeSystems = [];
    this.world = world;
    lastExecutedSystem = null;
  }

  public function registerSystem(SystemClass:SystemClass, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error('System \'${SystemClass.name}\' does not extend \'System\' class');
    }

    if (getSystem(SystemClass) != null) {
      trace('System \'${SystemClass.name}\' already registered.');
      return this;
    }

    var system:System = new SystemClass(world, attributes);
    if (system.init != null) system.init(attributes);
    system.order = _systems.length;
    _systems.push(system);
    if (system.execute != null) {
      _executeSystems.push(system);
      sortSystems();
    }
    return this;
  }

  public function unregisterSystem(SystemClass:SystemClass):SystemManager {
    var system:System = getSystem(SystemClass);
    if (system == null) {
      trace('Can unregister system \'${SystemClass.name}\'. It doesn\'t exist.');
      return this;
    }

    _systems.splice(_systems.indexOf(system), 1);

    if (system.execute != null) {
      _executeSystems.splice(_executeSystems.indexOf(system), 1);
    }

    // @todo Add system.unregister() call to free resources
    return this;
  }

  private function sortSystems():Void {
    _executeSystems.sort((a:System, b:System) -> a.priority - b.priority || a.order - b.order);
  }

  public function getSystem(SystemClass:SystemClass):System {
    return _systems.find((s:System) -> Std.is(s, SystemClass));
  }

  public function getSystems():Array<System> {
    return _systems;
  }

  public function removeSystem(SystemClass:SystemClass):Void {
    var index:Int = _systems.indexOf(Type.createInstance(SystemClass));
    if (index != -1) {
      _systems.splice(index, 1);
    }
  }

  public function executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }

  public function stop():Void {
    for (system in _executeSystems) {
      system.stop();
    }
  }

  public function execute(delta:Float, time:Float, forcePlay:Bool):Void {
    for (system in _executeSystems) {
      if (forcePlay || system.enabled) {
        executeSystem(system, delta, time);
      }
    }
  }

  public function stats():Dynamic {
    var stats:Dynamic = {
      numSystems: _systems.length,
      systems: {}
    };

    for (i in 0..._systems.length) {
      var system:System = _systems[i];
      var systemStats:Dynamic = (stats.systems[system.getName()] = {
        queries: {},
        executeTime: system.executeTime
      });
      for (name in Reflect.fields(system.ctx)) {
        systemStats.queries[name] = system.ctx[name].stats();
      }
    }

    return stats;
  }
}