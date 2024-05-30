/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */

/**
 * Get a key from a list of components
 * @param {Array<Dynamic>} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>) : String {
  var ids = [];
  for (n in 0...Components.length) {
    var T = Components[n];

    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }

    if (typeof T == "object") {
      var operator = T.operator == "not" ? "!" : T.operator;
      ids.push("$" + { name : T.Component._typeId });
    } else {
      ids.push("$" + { name : T._typeId });
    }
  }

  return ids.sort().join("-");
}

// Detector for browser's "window"
var hasWindow = typeof window != "undefined";

// performance.now() "polyfill"
var now = if (hasWindow && typeof window.performance != "undefined") {
  performance.now.bind(performance);
} else {
  Date.now.bind(Date);
}

function componentRegistered(T) : Bool {
  return (
    (typeof T == "object" && T.Component._typeId != null) ||
    (T.isComponent && T._typeId != null)
  );
}

class SystemManager {
  private var _systems : Array<Dynamic>;
  private var _executeSystems : Array<Dynamic>; // Systems that have `execute` method
  public var world : Dynamic;
  public var lastExecutedSystem : Dynamic;

  public function new(world : Dynamic) {
    this._systems = [];
    this._executeSystems = []; // Systems that have `execute` method
    this.world = world;
    this.lastExecutedSystem = null;
  }

  public function registerSystem(SystemClass : Dynamic, attributes : Dynamic) : SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }

    if (this.getSystem(SystemClass) != null) {
      trace("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }

    var system = new SystemClass(this.world, attributes);
    if (system.init != null) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute != null) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }

  public function unregisterSystem(SystemClass : Dynamic) : SystemManager {
    var system = this.getSystem(SystemClass);
    if (system == null) {
      trace(
        "Can unregister system '" + SystemClass.getName() + "'. It doesn't exist."
      );
      return this;
    }

    this._systems.splice(this._systems.indexOf(system), 1);

    if (system.execute != null) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }

    // @todo Add system.unregister() call to free resources
    return this;
  }

  public function sortSystems() : Void {
    this._executeSystems.sort(function(a, b) {
      return a.priority - b.priority || a.order - b.order;
    });
  }

  public function getSystem(SystemClass : Dynamic) : Dynamic {
    return this._systems.find(function(s) {
      return s instanceof SystemClass;
    });
  }

  public function getSystems() : Array<Dynamic> {
    return this._systems;
  }

  public function removeSystem(SystemClass : Dynamic) : Void {
    var index = this._systems.indexOf(SystemClass);
    if (index == -1) return;

    this._systems.splice(index, 1);
  }

  public function executeSystem(system : Dynamic, delta : Float, time : Float) : Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }

  public function stop() : Void {
    this._executeSystems.forEach(function(system) {
      system.stop();
    });
  }

  public function execute(delta : Float, time : Float, forcePlay : Bool) : Void {
    this._executeSystems.forEach(function(system) {
      if (forcePlay || system.enabled) {
        this.executeSystem(system, delta, time);
      }
    });
  }

  public function stats() : Dynamic {
    var stats = {
      numSystems : this._systems.length,
      systems : {},
    };

    for (i in 0...this._systems.length) {
      var system = this._systems[i];
      var systemStats = (stats.systems[system.getName()] = {
        queries : {},
        executeTime : system.executeTime,
      });
      for (name in system.ctx) {
        systemStats.queries[name] = system.ctx[name].stats();
      }
    }

    return stats;
  }
}

class ObjectPool {
  // @todo Add initial size
  public var freeList : Array<Dynamic>;
  public var count : Int;
  public var T : Dynamic;
  public var isObjectPool : Bool;

  public function new(T : Dynamic, ?initialSize : Int) {
    this.freeList = [];
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;

    if (initialSize != null) {
      this.expand(initialSize);
    }
  }

  public function acquire() : Dynamic {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Std.int(this.count * 0.2) + 1);
    }

    var item = this.freeList.pop();

    return item;
  }

  public function release(item : Dynamic) : Void {
    item.reset();
    this.freeList.push(item);
  }

  public function expand(count : Int) : Void {
    for (n in 0...count) {
      var clone = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }

  public function totalSize() : Int {
    return this.count;
  }

  public function totalFree() : Int {
    return this.freeList.length;
  }

  public function totalUsed() : Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  public var _listeners : Dynamic;
  public var stats : Dynamic;

  public function new() {
    this._listeners = {};
    this.stats = {
      fired : 0,
      handled : 0,
    };
  }

  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  public function addEventListener(eventName : String, listener : Dynamic) : Void {
    var listeners = this._listeners;
    if (listeners[eventName] == null) {
      listeners[eventName] = [];
    }

    if (listeners[eventName].indexOf(listener) == -1) {
      listeners[eventName].push(listener);
    }
  }

  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  public function hasEventListener(eventName : String, listener : Dynamic) : Bool {
    return (
      this._listeners[eventName] != null &&
      this._listeners[eventName].indexOf(listener) != -1
    );
  }

  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  public function removeEventListener(eventName : String, listener : Dynamic) : Void {
    var listenerArray = this._listeners[eventName];
    if (listenerArray != null) {
      var index = listenerArray.indexOf(listener);
      if (index != -1) {
        listenerArray.splice(index, 1);
      }
    }
  }

  /**
   * Dispatch an event
   * @param {String} eventName Name of the event to dispatch
   * @param {Entity} entity (Optional) Entity to emit
   * @param {Component} component
   */
  public function dispatchEvent(eventName : String, ?entity : Dynamic, ?component : Dynamic) : Void {
    this.stats.fired++;

    var listenerArray = this._listeners[eventName];
    if (listenerArray != null) {
      var array = listenerArray.slice(0);

      for (i in 0...array.length) {
        array[i].call(this, entity, component);
      }
    }
  }

  /**
   * Reset stats counters
   */
  public function resetCounters() : Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  /**
   * @param {Array<Dynamic>} Components List of types of components to query
   */
  public var Components : Array<Dynamic>;
  public var NotComponents : Array<Dynamic>;
  public var entities : Array<Dynamic>;
  public var eventDispatcher : EventDispatcher;
  public var reactive : Bool;
  public var key : String;

  public function new(Components : Array<Dynamic>, manager : Dynamic) {
    this.Components = [];
    this.NotComponents = [];

    Components.forEach(function(component) {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });

    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }

    this.entities = [];

    this.eventDispatcher = new EventDispatcher();

    // This query is being used by a reactive system
    this.reactive = false;

    this.key = queryKey(Components);

    // Fill the query with the existing entities
    for (i in 0...manager._entities.length) {
      var entity = manager._entities[i];
      if (this.match(entity)) {
        // @todo ??? this.addEntity(entity); => preventing the event to be generated
        entity.queries.push(this);
        this.entities.push(entity);
      }
    }
  }

  /**
   * Add entity to this query
   * @param {Entity} entity
   */
  public function addEntity(entity : Dynamic) : Void {
    entity.queries.push(this);
    this.entities.push(entity);

    this.eventDispatcher.dispatchEvent(Query.prototype.ENTITY_ADDED, entity);
  }

  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  public function removeEntity(entity : Dynamic) : Void {
    var index = this.entities.indexOf(entity);
    if (index != -1) {
      this.entities.splice(index, 1);

      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);

      this.eventDispatcher.dispatchEvent(
        Query.prototype.ENTITY_REMOVED,
        entity
      );
    }
  }

  public function match(entity : Dynamic) : Bool {
    return (
      entity.hasAllComponents(this.Components) &&
      !entity.hasAnyComponents(this.NotComponents)
    );
  }

  public function toJSON() : Dynamic {
    return {
      key : this.key,
      reactive : this.reactive,
      components : {
        included : this.Components.map(function(C) {
          return C.name;
        }),
        not : this.NotComponents.map(function(C) {
          return C.name;
        }),
      },
      numEntities : this.entities.length,
    };
  }

  /**
   * Return stats for this query
   */
  public function stats() : Dynamic {
    return {
      numComponents : this.Components.length,
      numEntities : this.entities.length,
    };
  }
}

class QueryManager {
  public var _world : Dynamic;
  public var _queries : Dynamic;

  public function new(world : Dynamic) {
    this._world = world;

    // Queries indexed by a unique identifier for the components it has
    this._queries = {};
  }

  public function onEntityRemoved(entity : Dynamic) : Void {
    for (queryName in this._queries) {
      var query = this._queries[queryName];
      if (entity.queries.indexOf(query) != -1) {
        query.removeEntity(entity);
      }
    }
  }

  /**
   * Callback when a component is added to an entity
   * @param {Entity} entity Entity that just got the new component
   * @param {Component} Component Component added to the entity
   */
  public function onEntityComponentAdded(entity : Dynamic, Component : Dynamic) : Void {
    // @todo Use bitmask for checking components?

    // Check each indexed query to see if we need to add this entity to the list
    for (queryName in this._queries) {
      var query = this._queries[queryName];

      if (
        query.NotComponents.indexOf(Component) != -1 &&
        query.entities.indexOf(entity) != -1
      ) {
        query.removeEntity(entity);
        continue;
      }

      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (
        query.Components.indexOf(Component) == -1 ||
        !query.match(entity) ||
        query.entities.indexOf(entity) != -1
      ) continue;

      query.addEntity(entity);
    }
  }

  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  public function onEntityComponentRemoved(entity : Dynamic, Component : Dynamic) : Void {
    for (queryName in this._queries) {
      var query = this._queries[queryName];

      if (
        query.NotComponents.indexOf(Component) != -1 &&
        query.entities.indexOf(entity) == -1 &&
        query.match(entity)
      ) {
        query.addEntity(entity);
        continue;
      }

      if (
        query.Components.indexOf(Component) != -1 &&
        query.entities.indexOf(entity) != -1 &&
        !query.match(entity)
      ) {
        query.removeEntity(entity);
        continue;
      }
    }
  }

  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  public function getQuery(Components : Dynamic) : Dynamic {
    var key = queryKey(Components);
    var query = this._queries[key];
    if (query == null) {
      this._queries[key] = query = new Query(Components, this._world);
    }
    return query;
  }

  /**
   * Return some stats from this class
   */
  public function stats() : Dynamic {
    var stats = {};
    for (queryName in this._queries) {
      stats[queryName] = this._queries[queryName].stats();
    }
    return stats;
  }
}

class Component {
  public var _pool : Dynamic;

  public function new(?props : Dynamic) {
    if (props != false) {
      const schema = this.constructor.schema;

      for (key in schema) {
        if (props && props.hasOwnProperty(key)) {
          this[key] = props[key];
        } else {
          const schemaProp = schema[key];
          if (schemaProp.hasOwnProperty("default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            const type = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }

      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
  }

  public function copy(source : Dynamic) : Dynamic {
    const schema = this.constructor.schema;

    for (key in schema) {
      const prop = schema[key];

      if (source.hasOwnProperty(key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }

    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }

    return this;
  }

  public function clone() : Dynamic {
    return new this.constructor().copy(this);
  }

  public function reset() : Void {
    const schema = this.constructor.schema;

    for (key in schema) {
      const schemaProp = schema[key];

      if (schemaProp.hasOwnProperty("default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        const type = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }

  public function dispose() : Void {
    if (this._pool != null) {
      this._pool.release(this);
    }
  }

  public function getName() : String {
    return this.constructor.getName();
  }

  public function checkUndefinedAttributes(src : Dynamic) : Void {
    const schema = this.constructor.schema;

    // Check that the attributes defined in source are also defined in the schema
    for (srcKey in src) {
      if