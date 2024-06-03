import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import js.Browser;
import js.html.Window;
import js.lib.Array;
import js.lib.Date;
import js.lib.Math;
import js.lib.Object;
import js.lib.Performance;
import js.lib.String;
import js.lib.TypeError;
import js.lib.WeakMap;

/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */
/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>):String {
  var ids:Array<String> = new Array();
  for (var n:Int = 0; n < Components.length; n++) {
    var T:Dynamic = Components[n];
    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }
    if (typeof T == "object") {
      var operator:String = T.operator == "not" ? "!" : T.operator;
      ids.push(operator + T.Component._typeId);
    } else {
      ids.push(T._typeId);
    }
  }
  return ids.sort().join("-");
}

// Detector for browser's "window"
const hasWindow = typeof Browser.window != "undefined";

// performance.now() "polyfill"
const now = hasWindow && typeof Window.performance != "undefined" ? Performance.now.bind(Performance) : Date.now.bind(Date);

function componentRegistered(T:Dynamic):Bool {
  return (typeof T == "object" && T.Component._typeId != null) || (T.isComponent && T._typeId != null);
}

class SystemManager {
  _systems:Array<System>;
  _executeSystems:Array<System>;
  world:World;
  lastExecutedSystem:System;
  constructor(world:World) {
    this._systems = new Array();
    this._executeSystems = new Array();
    this.world = world;
    this.lastExecutedSystem = null;
  }
  registerSystem(SystemClass:Dynamic, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }
    if (this.getSystem(SystemClass) != null) {
      console.warn("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }
    var system:System = new SystemClass(this.world, attributes);
    if (system.init) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }
  unregisterSystem(SystemClass:Dynamic):SystemManager {
    var system:System = this.getSystem(SystemClass);
    if (system == null) {
      console.warn("Can unregister system '" + SystemClass.getName() + "'. It doesn't exist.");
      return this;
    }
    this._systems.splice(this._systems.indexOf(system), 1);
    if (system.execute) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }
    // @todo Add system.unregister() call to free resources
    return this;
  }
  sortSystems():Void {
    this._executeSystems.sort((a:System, b:System) => {
      return a.priority - b.priority || a.order - b.order;
    });
  }
  getSystem(SystemClass:Dynamic):System {
    return this._systems.find((s:System) => s instanceof SystemClass);
  }
  getSystems():Array<System> {
    return this._systems;
  }
  removeSystem(SystemClass:Dynamic):Void {
    var index:Int = this._systems.indexOf(SystemClass);
    if (index < 0) return;
    this._systems.splice(index, 1);
  }
  executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }
  stop():Void {
    this._executeSystems.forEach((system:System) => system.stop());
  }
  execute(delta:Float, time:Float, forcePlay:Bool = false):Void {
    this._executeSystems.forEach((system:System) => (forcePlay || system.enabled) && this.executeSystem(system, delta, time));
  }
  stats():Dynamic {
    var stats:Dynamic = {
      numSystems: this._systems.length,
      systems: new StringMap()
    };
    for (var i:Int = 0; i < this._systems.length; i++) {
      var system:System = this._systems[i];
      var systemStats:Dynamic = stats.systems.set(system.getName(), {
        queries: new StringMap(),
        executeTime: system.executeTime
      });
      for (var name:String in system.ctx) {
        systemStats.queries.set(name, system.ctx[name].stats());
      }
    }
    return stats;
  }
}

class ObjectPool<T> {
  freeList:Array<T>;
  count:Int;
  T:Dynamic;
  isObjectPool:Bool;
  constructor(T:Dynamic, initialSize:Int = 0) {
    this.freeList = new Array();
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }
    var item:T = this.freeList.pop();
    return item;
  }
  release(item:T):Void {
    item.reset();
    this.freeList.push(item);
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:T = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
  totalSize():Int {
    return this.count;
  }
  totalFree():Int {
    return this.freeList.length;
  }
  totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  _listeners:StringMap<Array<Dynamic>>;
  stats:Dynamic;
  constructor() {
    this._listeners = new StringMap();
    this.stats = {
      fired: 0,
      handled: 0
    };
  }
  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  addEventListener(eventName:String, listener:Dynamic):Void {
    var listeners:StringMap<Array<Dynamic>> = this._listeners;
    if (listeners.exists(eventName)) {
      listeners.get(eventName).push(listener);
    } else {
      listeners.set(eventName, [listener]);
    }
  }
  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.exists(eventName) && this._listeners.get(eventName).indexOf(listener) != -1;
  }
  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  removeEventListener(eventName:String, listener:Dynamic):Void {
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var index:Int = listenerArray.indexOf(listener);
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
  dispatchEvent(eventName:String, entity:Entity = null, component:Dynamic = null):Void {
    this.stats.fired++;
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var array:Array<Dynamic> = listenerArray.slice(0);
      for (var i:Int = 0; i < array.length; i++) {
        array[i].call(this, entity, component);
      }
    }
  }
  /**
   * Reset stats counters
   */
  resetCounters():Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  Components:Array<Dynamic>;
  NotComponents:Array<Dynamic>;
  entities:Array<Entity>;
  eventDispatcher:EventDispatcher;
  reactive:Bool;
  key:String;
  constructor(Components:Array<Dynamic>, manager:QueryManager) {
    this.Components = new Array();
    this.NotComponents = new Array();
    Components.forEach((component:Dynamic) => {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });
    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }
    this.entities = new Array();
    this.eventDispatcher = new EventDispatcher();
    // This query is being used by a reactive system
    this.reactive = false;
    this.key = queryKey(Components);
    // Fill the query with the existing entities
    for (var i:Int = 0; i < manager._entities.length; i++) {
      var entity:Entity = manager._entities[i];
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
  addEntity(entity:Entity):Void {
    entity.queries.push(this);
    this.entities.push(entity);
    this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
  }
  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  removeEntity(entity:Entity):Void {
    var index:Int = this.entities.indexOf(entity);
    if (index >= 0) {
      this.entities.splice(index, 1);
      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);
      this.eventDispatcher.dispatchEvent(Query.ENTITY_REMOVED, entity);
    }
  }
  match(entity:Entity):Bool {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }
  toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C:Dynamic) => C.name),
        not: this.NotComponents.map((C:Dynamic) => C.name)
      },
      numEntities: this.entities.length
    };
  }
  /**
   * Return stats for this query
   */
  stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length
    };
  }
}

Query.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

/**
 * @private
 * @class QueryManager
 */
class QueryManager {
  _world:World;
  _queries:StringMap<Query>;
  constructor(world:World) {
    this._world = world;
    // Queries indexed by a unique identifier for the components it has
    this._queries = new StringMap();
  }
  onEntityRemoved(entity:Entity):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
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
  onEntityComponentAdded(entity:Entity, Component:Dynamic):Void {
    // @todo Use bitmask for checking components?
    // Check each indexed query to see if we need to add this entity to the list
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0) {
        query.removeEntity(entity);
        continue;
      }
      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (query.Components.indexOf(Component) < 0 || !query.match(entity) || query.entities.indexOf(entity) >= 0) continue;
      query.addEntity(entity);
    }
  }
  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  onEntityComponentRemoved(entity:Entity, Component:Dynamic):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) < 0 && query.match(entity)) {
        query.addEntity(entity);
        continue;
      }
      if (query.Components.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0 && !query.match(entity)) {
        query.removeEntity(entity);
        continue;
      }
    }
  }
  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  getQuery(Components:Array<Dynamic>):Query {
    var key:String = queryKey(Components);
    var query:Query = this._queries.get(key);
    if (query == null) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }
  /**
   * Return some stats from this class
   */
  stats():Dynamic {
    var stats:Dynamic = new StringMap();
    for (var queryName:String in this._queries) {
      stats.set(queryName, this._queries.get(queryName).stats());
    }
    return stats;
  }
}

class Component {
  _pool:ObjectPool<Component>;
  constructor(props:Dynamic = null) {
    if (props != false) {
      var schema:StringMap<Dynamic> = this.constructor.schema;
      for (var key:String in schema) {
        if (props && Object.prototype.hasOwnProperty.call(props, key)) {
          this[key] = props[key];
        } else {
          var schemaProp:Dynamic = schema[key];
          if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type:Dynamic = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }
      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
    this._pool = null;
  }
  copy(source:Dynamic):Component {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var prop:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }
    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }
    return this;
  }
  clone():Component {
    return new this.constructor().copy(this);
  }
  reset():Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var schemaProp:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        var type:Dynamic = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }
  dispose():Void {
    if (this._pool) {
      this._pool.release(this);
    }
  }
  getName():String {
    return this.constructor.getName();
  }
  checkUndefinedAttributes(src:Dynamic):Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    // Check that the attributes defined in source are also defined in the schema
    Object.keys(src).forEach((srcKey:String) => {
      if (!Object.prototype.hasOwnProperty.call(schema, srcKey)) {
        console.warn("Trying to set attribute '" + srcKey + "' not defined in the '" + this.constructor.name + "' schema. Please fix the schema, the attribute value won't be set");
      }
    });
  }
}

Component.schema = new StringMap();
Component.isComponent = true;
Component.getName = function():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool extends ObjectPool<Entity> {
  entityManager:EntityManager;
  constructor(entityManager:EntityManager, entityClass:Dynamic, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:Entity = new this.T(this.entityManager);
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
}

/**
 * @private
 * @class EntityManager
 */
class EntityManager {
  world:World;
  componentsManager:ComponentManager;
  _entities:Array<Entity>;
  _nextEntityId:Int;
  _entitiesByNames:StringMap<Entity>;
  _queryManager:QueryManager;
  eventDispatcher:EventDispatcher;
  _entityPool:EntityPool;
  entitiesWithComponentsToRemove:Array<Entity>;
  entitiesToRemove:Array<Entity>;
  deferredRemovalEnabled:Bool;
  constructor(world:World) {
    this.world = world;
    this.componentsManager = world.componentsManager;
    // All the entities in this instance
    this._entities = new Array();
    this._nextEntityId = 0;
    this._entitiesByNames = new StringMap();
    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);
    // Deferred deletion
    this.entitiesWithComponentsToRemove = new Array();
    this.entitiesToRemove = new Array();
    this.deferredRemovalEnabled = true;
  }
  getEntityByName(name:String):Entity {
    return this._entitiesByNames.get(name);
  }
  /**
   * Create a new entity
   */
  createEntity(name:String = null):Entity {
    var entity:Entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name || "";
    if (name) {
      if (this._entitiesByNames.exists(name)) {
        console.warn("Entity name '" + name + "' already exist");
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }
    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_CREATED, entity);
    return entity;
  }
  // COMPONENTS
  /**
   * Add a component to an entity
   * @param {Entity} entity Entity where the component will be added
   * @param {Component} Component Component to be added to the entity
   * @param {Object} values Optional values to replace the default attributes
   */
  entityAddComponent(entity:Entity, Component:Dynamic, values:Dynamic = null):Void {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }
    if (entity._ComponentTypes.indexOf(Component) >= 0) {
      {
        console.warn("Component type already exists on entity.", entity, Component.getName());
      }
      return;
    }
    entity._ComponentTypes.push(Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents++;
    }
    var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(Component);
    var component:Component = componentPool ? componentPool.acquire() : new Component(values);
    if (componentPool && values) {
      component.copy(values);
    }
    entity._components.set(Component._typeId, component);
    this._queryManager.onEntityComponentAdded(entity, Component);
    this.world.componentsManager.componentAddedToEntity(Component);
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_ADDED, entity, Component);
  }
  /**
   * Remove a component from an entity
   * @param {Entity} entity Entity which will get removed the component
   * @param {*} Component Component to remove from the entity
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  entityRemoveComponent(entity:Entity, Component:Dynamic, immediately:Bool = false):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index < 0) return;
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_REMOVE, entity, Component);
    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) this.entitiesWithComponentsToRemove.push(entity);
      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);
      entity._componentsToRemove.set(Component._typeId, entity._components.get(Component._typeId));
      entity._components.remove(Component._typeId);
    }
    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents--;
      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }
  _entityRemoveComponentSync(entity:Entity, Component:Dynamic, index:Int):Void {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component:Component = entity._components.get(Component._typeId);
    entity._components.remove(Component._typeId);
    component.dispose();
    this.world.componentsManager.componentRemovedFromEntity(Component);
  }
  /**
   * Remove all the components from an entity
   * @param {Entity} entity Entity from which the components will be removed
   */
  entityRemoveAllComponents(entity:Entity, immediately:Bool = false):Void {
    var Components:Array<Dynamic> = entity._ComponentTypes;
    for (var j:Int = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ != SystemStateComponent) this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }
  /**
   * Remove the entity from this manager. It will clear also its components
   * @param {Entity} entity Entity to remove from the manager
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  removeEntity(entity:Entity, immediately:Bool = false):Void {
    var index:Int = this._entities.indexOf(entity);
    if (index < 0) throw new Error("Tried to remove entity not in list");
    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);
    if (entity.numStateComponents == 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately == true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }
  _releaseEntity(entity:Entity, index:Int):Void {
    this._entities.splice(index, 1);
    if (this._entitiesByNames.exists(entity.name)) {
      this._entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }
  /**
   * Remove all entities from this manager
   */
  removeAllEntities():Void {
    for (var i:Int = this._entities.length - 1; i >= 0; i--) {
      this.removeEntity(this._entities[i]);
    }
  }
  processDeferredRemoval():Void {
    if (!this.deferredRemovalEnabled) {
      return;
    }
    for (var i:Int = 0; i < this.entitiesToRemove.length; i++) {
      var entity:Entity = this.entitiesToRemove[i];
      var index:Int = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;
    for (var i:Int = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      var entity:Entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Dynamic = entity._ComponentTypesToRemove.pop();
        var component:Component = entity._componentsToRemove.get(Component._typeId);
        entity._componentsToRemove.remove(Component._typeId);
        component.dispose();
        this.world.componentsManager.componentRemovedFromEntity(Component);
        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }
    this.entitiesWithComponentsToRemove.length = 0;
  }
  /**
   * Get a query based on a list of components
   * @param {Array(Component)} Components List of components that will form the query
   */
  queryComponents(Components:Array<Dynamic>):Query {
    return this._queryManager.getQuery(Components);
  }
  // EXTRAS
  /**
   * Return number of entities
   */
  count():Int {
    return this._entities.length;
  }
  /**
   * Return some stats
   */
  stats():Dynamic {
    var stats:Dynamic = {
      numEntities: this._entities.length,
      numQueries: Object.keys(this._queryManager._queries).length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: new StringMap(),
      eventDispatcher: this.eventDispatcher.stats
    };
    for (var ecsyComponentId:String in this.componentsManager._componentPool) {
      var pool:ObjectPool<Component> = this.componentsManager._componentPool.get(ecsyComponentId);
      stats.componentPool.set(pool.T.getName(), {
        used: pool.totalUsed(),
        size: pool.count
      });
    }
    return stats;
  }
}

EntityManager.ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
EntityManager.ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
EntityManager.COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
EntityManager.COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";

class ComponentManager {
  Components:Array<Dynamic>;
  _ComponentsMap:StringMap<Dynamic>;
  _componentPool:StringMap<ObjectPool<Component>>;
  numComponents:StringMap<Int>;
  nextComponentId:Int;
  constructor() {
    this.Components = new Array();
    this._ComponentsMap = new StringMap();
    this._componentPool = new StringMap();
    this.numComponents = new StringMap();
    this.nextComponentId = 0;
  }
  hasComponent(Component:Dynamic):Bool {
    return this.Components.indexOf(Component) != -1;
  }
  registerComponent(Component:Dynamic, objectPool:ObjectPool<Component> = null):Void {
    if (this.Components.indexOf(Component) != -1) {
      console.warn("Component type: '" + Component.getName() + "' already registered.");
      return;
    }
    var schema:StringMap<Dynamic> = Component.schema;
    if (schema == null) {
      throw new Error("Component \"" + Component.getName() + "\" has no schema property.");
    }
    for (var propName:String in schema) {
      var prop:Dynamic = schema[propName];
      if (prop.type == null) {
        throw new Error("Invalid schema for component \"" + Component.getName() + "\". Missing type for \"" + propName + "\" property.");
      }
    }
    Component._typeId = this.nextComponentId++;
    this.Components.push(Component);
    this._ComponentsMap.set(Component._typeId, Component);
    this.numComponents.set(Component._typeId, 0);
    if (objectPool == null) {
      objectPool = new ObjectPool(Component);
    } else if (objectPool == false) {
      objectPool = null;
    }
    this._componentPool.set(Component._typeId, objectPool);
  }
  componentAddedToEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) + 1);
  }
  componentRemovedFromEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) - 1);
  }
  getComponentsPool(Component:Dynamic):ObjectPool<Component> {
    return this._componentPool.get(Component._typeId);
  }
}

const Version = "0.3.1";

const proxyMap = new WeakMap();

const proxyHandler:Dynamic = {
  set(target:Dynamic, prop:String, value:Dynamic):Bool {
    throw new Error("Tried to write to \"" + target.constructor.getName() + "#" + String(prop) + "\" on immutable component. Use .getMutableComponent() to modify a component.");
  }
};

function wrapImmutableComponent(T:Dynamic, component:Dynamic):Dynamic {
  if (component == null) {
    return null;
  }
  var wrappedComponent:Dynamic = proxyMap.get(component);
  if (wrappedComponent == null) {
    wrappedComponent = new Proxy(component, proxyHandler);
    proxyMap.set(component, wrappedComponent);
  }
  return wrappedComponent;
}

class Entity {
  _entityManager:EntityManager;
  id:Int;
  _ComponentTypes:Array<Dynamic>;
  _components:StringMap<Component>;
  _componentsToRemove:StringMap<Component>;
  queries:Array<Query>;
  _ComponentTypesToRemove:Array<Dynamic>;
  alive:Bool;
  name:String;
  numStateComponents:Int;
  constructor(entityManager:EntityManager = null) {
    this._entityManager = entityManager || null;
    // Unique ID for this entity
    this.id = entityManager._nextEntityId++;
    // List of components types the entity has
    this._ComponentTypes = new Array();
    //
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import js.Browser;
import js.html.Window;
import js.lib.Array;
import js.lib.Date;
import js.lib.Math;
import js.lib.Object;
import js.lib.Performance;
import js.lib.String;
import js.lib.TypeError;
import js.lib.WeakMap;

/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */
/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>):String {
  var ids:Array<String> = new Array();
  for (var n:Int = 0; n < Components.length; n++) {
    var T:Dynamic = Components[n];
    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }
    if (typeof T == "object") {
      var operator:String = T.operator == "not" ? "!" : T.operator;
      ids.push(operator + T.Component._typeId);
    } else {
      ids.push(T._typeId);
    }
  }
  return ids.sort().join("-");
}

// Detector for browser's "window"
const hasWindow = typeof Browser.window != "undefined";

// performance.now() "polyfill"
const now = hasWindow && typeof Window.performance != "undefined" ? Performance.now.bind(Performance) : Date.now.bind(Date);

function componentRegistered(T:Dynamic):Bool {
  return (typeof T == "object" && T.Component._typeId != null) || (T.isComponent && T._typeId != null);
}

class SystemManager {
  _systems:Array<System>;
  _executeSystems:Array<System>;
  world:World;
  lastExecutedSystem:System;
  constructor(world:World) {
    this._systems = new Array();
    this._executeSystems = new Array();
    this.world = world;
    this.lastExecutedSystem = null;
  }
  registerSystem(SystemClass:Dynamic, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }
    if (this.getSystem(SystemClass) != null) {
      console.warn("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }
    var system:System = new SystemClass(this.world, attributes);
    if (system.init) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }
  unregisterSystem(SystemClass:Dynamic):SystemManager {
    var system:System = this.getSystem(SystemClass);
    if (system == null) {
      console.warn("Can unregister system '" + SystemClass.getName() + "'. It doesn't exist.");
      return this;
    }
    this._systems.splice(this._systems.indexOf(system), 1);
    if (system.execute) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }
    // @todo Add system.unregister() call to free resources
    return this;
  }
  sortSystems():Void {
    this._executeSystems.sort((a:System, b:System) => {
      return a.priority - b.priority || a.order - b.order;
    });
  }
  getSystem(SystemClass:Dynamic):System {
    return this._systems.find((s:System) => s instanceof SystemClass);
  }
  getSystems():Array<System> {
    return this._systems;
  }
  removeSystem(SystemClass:Dynamic):Void {
    var index:Int = this._systems.indexOf(SystemClass);
    if (index < 0) return;
    this._systems.splice(index, 1);
  }
  executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }
  stop():Void {
    this._executeSystems.forEach((system:System) => system.stop());
  }
  execute(delta:Float, time:Float, forcePlay:Bool = false):Void {
    this._executeSystems.forEach((system:System) => (forcePlay || system.enabled) && this.executeSystem(system, delta, time));
  }
  stats():Dynamic {
    var stats:Dynamic = {
      numSystems: this._systems.length,
      systems: new StringMap()
    };
    for (var i:Int = 0; i < this._systems.length; i++) {
      var system:System = this._systems[i];
      var systemStats:Dynamic = stats.systems.set(system.getName(), {
        queries: new StringMap(),
        executeTime: system.executeTime
      });
      for (var name:String in system.ctx) {
        systemStats.queries.set(name, system.ctx[name].stats());
      }
    }
    return stats;
  }
}

class ObjectPool<T> {
  freeList:Array<T>;
  count:Int;
  T:Dynamic;
  isObjectPool:Bool;
  constructor(T:Dynamic, initialSize:Int = 0) {
    this.freeList = new Array();
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }
    var item:T = this.freeList.pop();
    return item;
  }
  release(item:T):Void {
    item.reset();
    this.freeList.push(item);
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:T = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
  totalSize():Int {
    return this.count;
  }
  totalFree():Int {
    return this.freeList.length;
  }
  totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  _listeners:StringMap<Array<Dynamic>>;
  stats:Dynamic;
  constructor() {
    this._listeners = new StringMap();
    this.stats = {
      fired: 0,
      handled: 0
    };
  }
  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  addEventListener(eventName:String, listener:Dynamic):Void {
    var listeners:StringMap<Array<Dynamic>> = this._listeners;
    if (listeners.exists(eventName)) {
      listeners.get(eventName).push(listener);
    } else {
      listeners.set(eventName, [listener]);
    }
  }
  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.exists(eventName) && this._listeners.get(eventName).indexOf(listener) != -1;
  }
  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  removeEventListener(eventName:String, listener:Dynamic):Void {
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var index:Int = listenerArray.indexOf(listener);
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
  dispatchEvent(eventName:String, entity:Entity = null, component:Dynamic = null):Void {
    this.stats.fired++;
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var array:Array<Dynamic> = listenerArray.slice(0);
      for (var i:Int = 0; i < array.length; i++) {
        array[i].call(this, entity, component);
      }
    }
  }
  /**
   * Reset stats counters
   */
  resetCounters():Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  Components:Array<Dynamic>;
  NotComponents:Array<Dynamic>;
  entities:Array<Entity>;
  eventDispatcher:EventDispatcher;
  reactive:Bool;
  key:String;
  constructor(Components:Array<Dynamic>, manager:QueryManager) {
    this.Components = new Array();
    this.NotComponents = new Array();
    Components.forEach((component:Dynamic) => {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });
    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }
    this.entities = new Array();
    this.eventDispatcher = new EventDispatcher();
    // This query is being used by a reactive system
    this.reactive = false;
    this.key = queryKey(Components);
    // Fill the query with the existing entities
    for (var i:Int = 0; i < manager._entities.length; i++) {
      var entity:Entity = manager._entities[i];
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
  addEntity(entity:Entity):Void {
    entity.queries.push(this);
    this.entities.push(entity);
    this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
  }
  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  removeEntity(entity:Entity):Void {
    var index:Int = this.entities.indexOf(entity);
    if (index >= 0) {
      this.entities.splice(index, 1);
      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);
      this.eventDispatcher.dispatchEvent(Query.ENTITY_REMOVED, entity);
    }
  }
  match(entity:Entity):Bool {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }
  toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C:Dynamic) => C.name),
        not: this.NotComponents.map((C:Dynamic) => C.name)
      },
      numEntities: this.entities.length
    };
  }
  /**
   * Return stats for this query
   */
  stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length
    };
  }
}

Query.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

/**
 * @private
 * @class QueryManager
 */
class QueryManager {
  _world:World;
  _queries:StringMap<Query>;
  constructor(world:World) {
    this._world = world;
    // Queries indexed by a unique identifier for the components it has
    this._queries = new StringMap();
  }
  onEntityRemoved(entity:Entity):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
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
  onEntityComponentAdded(entity:Entity, Component:Dynamic):Void {
    // @todo Use bitmask for checking components?
    // Check each indexed query to see if we need to add this entity to the list
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0) {
        query.removeEntity(entity);
        continue;
      }
      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (query.Components.indexOf(Component) < 0 || !query.match(entity) || query.entities.indexOf(entity) >= 0) continue;
      query.addEntity(entity);
    }
  }
  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  onEntityComponentRemoved(entity:Entity, Component:Dynamic):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) < 0 && query.match(entity)) {
        query.addEntity(entity);
        continue;
      }
      if (query.Components.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0 && !query.match(entity)) {
        query.removeEntity(entity);
        continue;
      }
    }
  }
  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  getQuery(Components:Array<Dynamic>):Query {
    var key:String = queryKey(Components);
    var query:Query = this._queries.get(key);
    if (query == null) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }
  /**
   * Return some stats from this class
   */
  stats():Dynamic {
    var stats:Dynamic = new StringMap();
    for (var queryName:String in this._queries) {
      stats.set(queryName, this._queries.get(queryName).stats());
    }
    return stats;
  }
}

class Component {
  _pool:ObjectPool<Component>;
  constructor(props:Dynamic = null) {
    if (props != false) {
      var schema:StringMap<Dynamic> = this.constructor.schema;
      for (var key:String in schema) {
        if (props && Object.prototype.hasOwnProperty.call(props, key)) {
          this[key] = props[key];
        } else {
          var schemaProp:Dynamic = schema[key];
          if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type:Dynamic = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }
      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
    this._pool = null;
  }
  copy(source:Dynamic):Component {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var prop:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }
    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }
    return this;
  }
  clone():Component {
    return new this.constructor().copy(this);
  }
  reset():Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var schemaProp:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        var type:Dynamic = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }
  dispose():Void {
    if (this._pool) {
      this._pool.release(this);
    }
  }
  getName():String {
    return this.constructor.getName();
  }
  checkUndefinedAttributes(src:Dynamic):Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    // Check that the attributes defined in source are also defined in the schema
    Object.keys(src).forEach((srcKey:String) => {
      if (!Object.prototype.hasOwnProperty.call(schema, srcKey)) {
        console.warn("Trying to set attribute '" + srcKey + "' not defined in the '" + this.constructor.name + "' schema. Please fix the schema, the attribute value won't be set");
      }
    });
  }
}

Component.schema = new StringMap();
Component.isComponent = true;
Component.getName = function():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool extends ObjectPool<Entity> {
  entityManager:EntityManager;
  constructor(entityManager:EntityManager, entityClass:Dynamic, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:Entity = new this.T(this.entityManager);
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
}

/**
 * @private
 * @class EntityManager
 */
class EntityManager {
  world:World;
  componentsManager:ComponentManager;
  _entities:Array<Entity>;
  _nextEntityId:Int;
  _entitiesByNames:StringMap<Entity>;
  _queryManager:QueryManager;
  eventDispatcher:EventDispatcher;
  _entityPool:EntityPool;
  entitiesWithComponentsToRemove:Array<Entity>;
  entitiesToRemove:Array<Entity>;
  deferredRemovalEnabled:Bool;
  constructor(world:World) {
    this.world = world;
    this.componentsManager = world.componentsManager;
    // All the entities in this instance
    this._entities = new Array();
    this._nextEntityId = 0;
    this._entitiesByNames = new StringMap();
    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);
    // Deferred deletion
    this.entitiesWithComponentsToRemove = new Array();
    this.entitiesToRemove = new Array();
    this.deferredRemovalEnabled = true;
  }
  getEntityByName(name:String):Entity {
    return this._entitiesByNames.get(name);
  }
  /**
   * Create a new entity
   */
  createEntity(name:String = null):Entity {
    var entity:Entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name || "";
    if (name) {
      if (this._entitiesByNames.exists(name)) {
        console.warn("Entity name '" + name + "' already exist");
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }
    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_CREATED, entity);
    return entity;
  }
  // COMPONENTS
  /**
   * Add a component to an entity
   * @param {Entity} entity Entity where the component will be added
   * @param {Component} Component Component to be added to the entity
   * @param {Object} values Optional values to replace the default attributes
   */
  entityAddComponent(entity:Entity, Component:Dynamic, values:Dynamic = null):Void {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }
    if (entity._ComponentTypes.indexOf(Component) >= 0) {
      {
        console.warn("Component type already exists on entity.", entity, Component.getName());
      }
      return;
    }
    entity._ComponentTypes.push(Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents++;
    }
    var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(Component);
    var component:Component = componentPool ? componentPool.acquire() : new Component(values);
    if (componentPool && values) {
      component.copy(values);
    }
    entity._components.set(Component._typeId, component);
    this._queryManager.onEntityComponentAdded(entity, Component);
    this.world.componentsManager.componentAddedToEntity(Component);
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_ADDED, entity, Component);
  }
  /**
   * Remove a component from an entity
   * @param {Entity} entity Entity which will get removed the component
   * @param {*} Component Component to remove from the entity
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  entityRemoveComponent(entity:Entity, Component:Dynamic, immediately:Bool = false):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index < 0) return;
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_REMOVE, entity, Component);
    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) this.entitiesWithComponentsToRemove.push(entity);
      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);
      entity._componentsToRemove.set(Component._typeId, entity._components.get(Component._typeId));
      entity._components.remove(Component._typeId);
    }
    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents--;
      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }
  _entityRemoveComponentSync(entity:Entity, Component:Dynamic, index:Int):Void {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component:Component = entity._components.get(Component._typeId);
    entity._components.remove(Component._typeId);
    component.dispose();
    this.world.componentsManager.componentRemovedFromEntity(Component);
  }
  /**
   * Remove all the components from an entity
   * @param {Entity} entity Entity from which the components will be removed
   */
  entityRemoveAllComponents(entity:Entity, immediately:Bool = false):Void {
    var Components:Array<Dynamic> = entity._ComponentTypes;
    for (var j:Int = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ != SystemStateComponent) this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }
  /**
   * Remove the entity from this manager. It will clear also its components
   * @param {Entity} entity Entity to remove from the manager
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  removeEntity(entity:Entity, immediately:Bool = false):Void {
    var index:Int = this._entities.indexOf(entity);
    if (index < 0) throw new Error("Tried to remove entity not in list");
    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);
    if (entity.numStateComponents == 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately == true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }
  _releaseEntity(entity:Entity, index:Int):Void {
    this._entities.splice(index, 1);
    if (this._entitiesByNames.exists(entity.name)) {
      this._entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }
  /**
   * Remove all entities from this manager
   */
  removeAllEntities():Void {
    for (var i:Int = this._entities.length - 1; i >= 0; i--) {
      this.removeEntity(this._entities[i]);
    }
  }
  processDeferredRemoval():Void {
    if (!this.deferredRemovalEnabled) {
      return;
    }
    for (var i:Int = 0; i < this.entitiesToRemove.length; i++) {
      var entity:Entity = this.entitiesToRemove[i];
      var index:Int = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;
    for (var i:Int = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      var entity:Entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Dynamic = entity._ComponentTypesToRemove.pop();
        var component:Component = entity._componentsToRemove.get(Component._typeId);
        entity._componentsToRemove.remove(Component._typeId);
        component.dispose();
        this.world.componentsManager.componentRemovedFromEntity(Component);
        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }
    this.entitiesWithComponentsToRemove.length = 0;
  }
  /**
   * Get a query based on a list of components
   * @param {Array(Component)} Components List of components that will form the query
   */
  queryComponents(Components:Array<Dynamic>):Query {
    return this._queryManager.getQuery(Components);
  }
  // EXTRAS
  /**
   * Return number of entities
   */
  count():Int {
    return this._entities.length;
  }
  /**
   * Return some stats
   */
  stats():Dynamic {
    var stats:Dynamic = {
      numEntities: this._entities.length,
      numQueries: Object.keys(this._queryManager._queries).length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: new StringMap(),
      eventDispatcher: this.eventDispatcher.stats
    };
    for (var ecsyComponentId:String in this.componentsManager._componentPool) {
      var pool:ObjectPool<Component> = this.componentsManager._componentPool.get(ecsyComponentId);
      stats.componentPool.set(pool.T.getName(), {
        used: pool.totalUsed(),
        size: pool.count
      });
    }
    return stats;
  }
}

EntityManager.ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
EntityManager.ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
EntityManager.COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
EntityManager.COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";

class ComponentManager {
  Components:Array<Dynamic>;
  _ComponentsMap:StringMap<Dynamic>;
  _componentPool:StringMap<ObjectPool<Component>>;
  numComponents:StringMap<Int>;
  nextComponentId:Int;
  constructor() {
    this.Components = new Array();
    this._ComponentsMap = new StringMap();
    this._componentPool = new StringMap();
    this.numComponents = new StringMap();
    this.nextComponentId = 0;
  }
  hasComponent(Component:Dynamic):Bool {
    return this.Components.indexOf(Component) != -1;
  }
  registerComponent(Component:Dynamic, objectPool:ObjectPool<Component> = null):Void {
    if (this.Components.indexOf(Component) != -1) {
      console.warn("Component type: '" + Component.getName() + "' already registered.");
      return;
    }
    var schema:StringMap<Dynamic> = Component.schema;
    if (schema == null) {
      throw new Error("Component \"" + Component.getName() + "\" has no schema property.");
    }
    for (var propName:String in schema) {
      var prop:Dynamic = schema[propName];
      if (prop.type == null) {
        throw new Error("Invalid schema for component \"" + Component.getName() + "\". Missing type for \"" + propName + "\" property.");
      }
    }
    Component._typeId = this.nextComponentId++;
    this.Components.push(Component);
    this._ComponentsMap.set(Component._typeId, Component);
    this.numComponents.set(Component._typeId, 0);
    if (objectPool == null) {
      objectPool = new ObjectPool(Component);
    } else if (objectPool == false) {
      objectPool = null;
    }
    this._componentPool.set(Component._typeId, objectPool);
  }
  componentAddedToEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) + 1);
  }
  componentRemovedFromEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) - 1);
  }
  getComponentsPool(Component:Dynamic):ObjectPool<Component> {
    return this._componentPool.get(Component._typeId);
  }
}

const Version = "0.3.1";

const proxyMap = new WeakMap();

const proxyHandler:Dynamic = {
  set(target:Dynamic, prop:String, value:Dynamic):Bool {
    throw new Error("Tried to write to \"" + target.constructor.getName() + "#" + String(prop) + "\" on immutable component. Use .getMutableComponent() to modify a component.");
  }
};

function wrapImmutableComponent(T:Dynamic, component:Dynamic):Dynamic {
  if (component == null) {
    return null;
  }
  var wrappedComponent:Dynamic = proxyMap.get(component);
  if (wrappedComponent == null) {
    wrappedComponent = new Proxy(component, proxyHandler);
    proxyMap.set(component, wrappedComponent);
  }
  return wrappedComponent;
}

class Entity {
  _entityManager:EntityManager;
  id:Int;
  _ComponentTypes:Array<Dynamic>;
  _components:StringMap<Component>;
  _componentsToRemove:StringMap<Component>;
  queries:Array<Query>;
  _ComponentTypesToRemove:Array<Dynamic>;
  alive:Bool;
  name:String;
  numStateComponents:Int;
  constructor(entityManager:EntityManager = null) {
    this._entityManager = entityManager || null;
    // Unique ID for this entity
    this.id = entityManager._nextEntityId++;
    // List of components types the entity has
    this._ComponentTypes = new Array();
    //
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import js.Browser;
import js.html.Window;
import js.lib.Array;
import js.lib.Date;
import js.lib.Math;
import js.lib.Object;
import js.lib.Performance;
import js.lib.String;
import js.lib.TypeError;
import js.lib.WeakMap;

/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */
/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>):String {
  var ids:Array<String> = new Array();
  for (var n:Int = 0; n < Components.length; n++) {
    var T:Dynamic = Components[n];
    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }
    if (typeof T == "object") {
      var operator:String = T.operator == "not" ? "!" : T.operator;
      ids.push(operator + T.Component._typeId);
    } else {
      ids.push(T._typeId);
    }
  }
  return ids.sort().join("-");
}

// Detector for browser's "window"
const hasWindow = typeof Browser.window != "undefined";

// performance.now() "polyfill"
const now = hasWindow && typeof Window.performance != "undefined" ? Performance.now.bind(Performance) : Date.now.bind(Date);

function componentRegistered(T:Dynamic):Bool {
  return (typeof T == "object" && T.Component._typeId != null) || (T.isComponent && T._typeId != null);
}

class SystemManager {
  _systems:Array<System>;
  _executeSystems:Array<System>;
  world:World;
  lastExecutedSystem:System;
  constructor(world:World) {
    this._systems = new Array();
    this._executeSystems = new Array();
    this.world = world;
    this.lastExecutedSystem = null;
  }
  registerSystem(SystemClass:Dynamic, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }
    if (this.getSystem(SystemClass) != null) {
      console.warn("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }
    var system:System = new SystemClass(this.world, attributes);
    if (system.init) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }
  unregisterSystem(SystemClass:Dynamic):SystemManager {
    var system:System = this.getSystem(SystemClass);
    if (system == null) {
      console.warn("Can unregister system '" + SystemClass.getName() + "'. It doesn't exist.");
      return this;
    }
    this._systems.splice(this._systems.indexOf(system), 1);
    if (system.execute) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }
    // @todo Add system.unregister() call to free resources
    return this;
  }
  sortSystems():Void {
    this._executeSystems.sort((a:System, b:System) => {
      return a.priority - b.priority || a.order - b.order;
    });
  }
  getSystem(SystemClass:Dynamic):System {
    return this._systems.find((s:System) => s instanceof SystemClass);
  }
  getSystems():Array<System> {
    return this._systems;
  }
  removeSystem(SystemClass:Dynamic):Void {
    var index:Int = this._systems.indexOf(SystemClass);
    if (index < 0) return;
    this._systems.splice(index, 1);
  }
  executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }
  stop():Void {
    this._executeSystems.forEach((system:System) => system.stop());
  }
  execute(delta:Float, time:Float, forcePlay:Bool = false):Void {
    this._executeSystems.forEach((system:System) => (forcePlay || system.enabled) && this.executeSystem(system, delta, time));
  }
  stats():Dynamic {
    var stats:Dynamic = {
      numSystems: this._systems.length,
      systems: new StringMap()
    };
    for (var i:Int = 0; i < this._systems.length; i++) {
      var system:System = this._systems[i];
      var systemStats:Dynamic = stats.systems.set(system.getName(), {
        queries: new StringMap(),
        executeTime: system.executeTime
      });
      for (var name:String in system.ctx) {
        systemStats.queries.set(name, system.ctx[name].stats());
      }
    }
    return stats;
  }
}

class ObjectPool<T> {
  freeList:Array<T>;
  count:Int;
  T:Dynamic;
  isObjectPool:Bool;
  constructor(T:Dynamic, initialSize:Int = 0) {
    this.freeList = new Array();
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }
    var item:T = this.freeList.pop();
    return item;
  }
  release(item:T):Void {
    item.reset();
    this.freeList.push(item);
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:T = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
  totalSize():Int {
    return this.count;
  }
  totalFree():Int {
    return this.freeList.length;
  }
  totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  _listeners:StringMap<Array<Dynamic>>;
  stats:Dynamic;
  constructor() {
    this._listeners = new StringMap();
    this.stats = {
      fired: 0,
      handled: 0
    };
  }
  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  addEventListener(eventName:String, listener:Dynamic):Void {
    var listeners:StringMap<Array<Dynamic>> = this._listeners;
    if (listeners.exists(eventName)) {
      listeners.get(eventName).push(listener);
    } else {
      listeners.set(eventName, [listener]);
    }
  }
  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.exists(eventName) && this._listeners.get(eventName).indexOf(listener) != -1;
  }
  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  removeEventListener(eventName:String, listener:Dynamic):Void {
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var index:Int = listenerArray.indexOf(listener);
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
  dispatchEvent(eventName:String, entity:Entity = null, component:Dynamic = null):Void {
    this.stats.fired++;
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var array:Array<Dynamic> = listenerArray.slice(0);
      for (var i:Int = 0; i < array.length; i++) {
        array[i].call(this, entity, component);
      }
    }
  }
  /**
   * Reset stats counters
   */
  resetCounters():Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  Components:Array<Dynamic>;
  NotComponents:Array<Dynamic>;
  entities:Array<Entity>;
  eventDispatcher:EventDispatcher;
  reactive:Bool;
  key:String;
  constructor(Components:Array<Dynamic>, manager:QueryManager) {
    this.Components = new Array();
    this.NotComponents = new Array();
    Components.forEach((component:Dynamic) => {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });
    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }
    this.entities = new Array();
    this.eventDispatcher = new EventDispatcher();
    // This query is being used by a reactive system
    this.reactive = false;
    this.key = queryKey(Components);
    // Fill the query with the existing entities
    for (var i:Int = 0; i < manager._entities.length; i++) {
      var entity:Entity = manager._entities[i];
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
  addEntity(entity:Entity):Void {
    entity.queries.push(this);
    this.entities.push(entity);
    this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
  }
  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  removeEntity(entity:Entity):Void {
    var index:Int = this.entities.indexOf(entity);
    if (index >= 0) {
      this.entities.splice(index, 1);
      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);
      this.eventDispatcher.dispatchEvent(Query.ENTITY_REMOVED, entity);
    }
  }
  match(entity:Entity):Bool {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }
  toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C:Dynamic) => C.name),
        not: this.NotComponents.map((C:Dynamic) => C.name)
      },
      numEntities: this.entities.length
    };
  }
  /**
   * Return stats for this query
   */
  stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length
    };
  }
}

Query.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

/**
 * @private
 * @class QueryManager
 */
class QueryManager {
  _world:World;
  _queries:StringMap<Query>;
  constructor(world:World) {
    this._world = world;
    // Queries indexed by a unique identifier for the components it has
    this._queries = new StringMap();
  }
  onEntityRemoved(entity:Entity):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
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
  onEntityComponentAdded(entity:Entity, Component:Dynamic):Void {
    // @todo Use bitmask for checking components?
    // Check each indexed query to see if we need to add this entity to the list
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0) {
        query.removeEntity(entity);
        continue;
      }
      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (query.Components.indexOf(Component) < 0 || !query.match(entity) || query.entities.indexOf(entity) >= 0) continue;
      query.addEntity(entity);
    }
  }
  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  onEntityComponentRemoved(entity:Entity, Component:Dynamic):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) < 0 && query.match(entity)) {
        query.addEntity(entity);
        continue;
      }
      if (query.Components.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0 && !query.match(entity)) {
        query.removeEntity(entity);
        continue;
      }
    }
  }
  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  getQuery(Components:Array<Dynamic>):Query {
    var key:String = queryKey(Components);
    var query:Query = this._queries.get(key);
    if (query == null) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }
  /**
   * Return some stats from this class
   */
  stats():Dynamic {
    var stats:Dynamic = new StringMap();
    for (var queryName:String in this._queries) {
      stats.set(queryName, this._queries.get(queryName).stats());
    }
    return stats;
  }
}

class Component {
  _pool:ObjectPool<Component>;
  constructor(props:Dynamic = null) {
    if (props != false) {
      var schema:StringMap<Dynamic> = this.constructor.schema;
      for (var key:String in schema) {
        if (props && Object.prototype.hasOwnProperty.call(props, key)) {
          this[key] = props[key];
        } else {
          var schemaProp:Dynamic = schema[key];
          if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type:Dynamic = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }
      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
    this._pool = null;
  }
  copy(source:Dynamic):Component {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var prop:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }
    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }
    return this;
  }
  clone():Component {
    return new this.constructor().copy(this);
  }
  reset():Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var schemaProp:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        var type:Dynamic = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }
  dispose():Void {
    if (this._pool) {
      this._pool.release(this);
    }
  }
  getName():String {
    return this.constructor.getName();
  }
  checkUndefinedAttributes(src:Dynamic):Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    // Check that the attributes defined in source are also defined in the schema
    Object.keys(src).forEach((srcKey:String) => {
      if (!Object.prototype.hasOwnProperty.call(schema, srcKey)) {
        console.warn("Trying to set attribute '" + srcKey + "' not defined in the '" + this.constructor.name + "' schema. Please fix the schema, the attribute value won't be set");
      }
    });
  }
}

Component.schema = new StringMap();
Component.isComponent = true;
Component.getName = function():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool extends ObjectPool<Entity> {
  entityManager:EntityManager;
  constructor(entityManager:EntityManager, entityClass:Dynamic, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:Entity = new this.T(this.entityManager);
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
}

/**
 * @private
 * @class EntityManager
 */
class EntityManager {
  world:World;
  componentsManager:ComponentManager;
  _entities:Array<Entity>;
  _nextEntityId:Int;
  _entitiesByNames:StringMap<Entity>;
  _queryManager:QueryManager;
  eventDispatcher:EventDispatcher;
  _entityPool:EntityPool;
  entitiesWithComponentsToRemove:Array<Entity>;
  entitiesToRemove:Array<Entity>;
  deferredRemovalEnabled:Bool;
  constructor(world:World) {
    this.world = world;
    this.componentsManager = world.componentsManager;
    // All the entities in this instance
    this._entities = new Array();
    this._nextEntityId = 0;
    this._entitiesByNames = new StringMap();
    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);
    // Deferred deletion
    this.entitiesWithComponentsToRemove = new Array();
    this.entitiesToRemove = new Array();
    this.deferredRemovalEnabled = true;
  }
  getEntityByName(name:String):Entity {
    return this._entitiesByNames.get(name);
  }
  /**
   * Create a new entity
   */
  createEntity(name:String = null):Entity {
    var entity:Entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name || "";
    if (name) {
      if (this._entitiesByNames.exists(name)) {
        console.warn("Entity name '" + name + "' already exist");
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }
    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_CREATED, entity);
    return entity;
  }
  // COMPONENTS
  /**
   * Add a component to an entity
   * @param {Entity} entity Entity where the component will be added
   * @param {Component} Component Component to be added to the entity
   * @param {Object} values Optional values to replace the default attributes
   */
  entityAddComponent(entity:Entity, Component:Dynamic, values:Dynamic = null):Void {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }
    if (entity._ComponentTypes.indexOf(Component) >= 0) {
      {
        console.warn("Component type already exists on entity.", entity, Component.getName());
      }
      return;
    }
    entity._ComponentTypes.push(Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents++;
    }
    var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(Component);
    var component:Component = componentPool ? componentPool.acquire() : new Component(values);
    if (componentPool && values) {
      component.copy(values);
    }
    entity._components.set(Component._typeId, component);
    this._queryManager.onEntityComponentAdded(entity, Component);
    this.world.componentsManager.componentAddedToEntity(Component);
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_ADDED, entity, Component);
  }
  /**
   * Remove a component from an entity
   * @param {Entity} entity Entity which will get removed the component
   * @param {*} Component Component to remove from the entity
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  entityRemoveComponent(entity:Entity, Component:Dynamic, immediately:Bool = false):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index < 0) return;
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_REMOVE, entity, Component);
    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) this.entitiesWithComponentsToRemove.push(entity);
      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);
      entity._componentsToRemove.set(Component._typeId, entity._components.get(Component._typeId));
      entity._components.remove(Component._typeId);
    }
    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents--;
      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }
  _entityRemoveComponentSync(entity:Entity, Component:Dynamic, index:Int):Void {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component:Component = entity._components.get(Component._typeId);
    entity._components.remove(Component._typeId);
    component.dispose();
    this.world.componentsManager.componentRemovedFromEntity(Component);
  }
  /**
   * Remove all the components from an entity
   * @param {Entity} entity Entity from which the components will be removed
   */
  entityRemoveAllComponents(entity:Entity, immediately:Bool = false):Void {
    var Components:Array<Dynamic> = entity._ComponentTypes;
    for (var j:Int = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ != SystemStateComponent) this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }
  /**
   * Remove the entity from this manager. It will clear also its components
   * @param {Entity} entity Entity to remove from the manager
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  removeEntity(entity:Entity, immediately:Bool = false):Void {
    var index:Int = this._entities.indexOf(entity);
    if (index < 0) throw new Error("Tried to remove entity not in list");
    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);
    if (entity.numStateComponents == 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately == true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }
  _releaseEntity(entity:Entity, index:Int):Void {
    this._entities.splice(index, 1);
    if (this._entitiesByNames.exists(entity.name)) {
      this._entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }
  /**
   * Remove all entities from this manager
   */
  removeAllEntities():Void {
    for (var i:Int = this._entities.length - 1; i >= 0; i--) {
      this.removeEntity(this._entities[i]);
    }
  }
  processDeferredRemoval():Void {
    if (!this.deferredRemovalEnabled) {
      return;
    }
    for (var i:Int = 0; i < this.entitiesToRemove.length; i++) {
      var entity:Entity = this.entitiesToRemove[i];
      var index:Int = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;
    for (var i:Int = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      var entity:Entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Dynamic = entity._ComponentTypesToRemove.pop();
        var component:Component = entity._componentsToRemove.get(Component._typeId);
        entity._componentsToRemove.remove(Component._typeId);
        component.dispose();
        this.world.componentsManager.componentRemovedFromEntity(Component);
        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }
    this.entitiesWithComponentsToRemove.length = 0;
  }
  /**
   * Get a query based on a list of components
   * @param {Array(Component)} Components List of components that will form the query
   */
  queryComponents(Components:Array<Dynamic>):Query {
    return this._queryManager.getQuery(Components);
  }
  // EXTRAS
  /**
   * Return number of entities
   */
  count():Int {
    return this._entities.length;
  }
  /**
   * Return some stats
   */
  stats():Dynamic {
    var stats:Dynamic = {
      numEntities: this._entities.length,
      numQueries: Object.keys(this._queryManager._queries).length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: new StringMap(),
      eventDispatcher: this.eventDispatcher.stats
    };
    for (var ecsyComponentId:String in this.componentsManager._componentPool) {
      var pool:ObjectPool<Component> = this.componentsManager._componentPool.get(ecsyComponentId);
      stats.componentPool.set(pool.T.getName(), {
        used: pool.totalUsed(),
        size: pool.count
      });
    }
    return stats;
  }
}

EntityManager.ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
EntityManager.ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
EntityManager.COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
EntityManager.COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";

class ComponentManager {
  Components:Array<Dynamic>;
  _ComponentsMap:StringMap<Dynamic>;
  _componentPool:StringMap<ObjectPool<Component>>;
  numComponents:StringMap<Int>;
  nextComponentId:Int;
  constructor() {
    this.Components = new Array();
    this._ComponentsMap = new StringMap();
    this._componentPool = new StringMap();
    this.numComponents = new StringMap();
    this.nextComponentId = 0;
  }
  hasComponent(Component:Dynamic):Bool {
    return this.Components.indexOf(Component) != -1;
  }
  registerComponent(Component:Dynamic, objectPool:ObjectPool<Component> = null):Void {
    if (this.Components.indexOf(Component) != -1) {
      console.warn("Component type: '" + Component.getName() + "' already registered.");
      return;
    }
    var schema:StringMap<Dynamic> = Component.schema;
    if (schema == null) {
      throw new Error("Component \"" + Component.getName() + "\" has no schema property.");
    }
    for (var propName:String in schema) {
      var prop:Dynamic = schema[propName];
      if (prop.type == null) {
        throw new Error("Invalid schema for component \"" + Component.getName() + "\". Missing type for \"" + propName + "\" property.");
      }
    }
    Component._typeId = this.nextComponentId++;
    this.Components.push(Component);
    this._ComponentsMap.set(Component._typeId, Component);
    this.numComponents.set(Component._typeId, 0);
    if (objectPool == null) {
      objectPool = new ObjectPool(Component);
    } else if (objectPool == false) {
      objectPool = null;
    }
    this._componentPool.set(Component._typeId, objectPool);
  }
  componentAddedToEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) + 1);
  }
  componentRemovedFromEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) - 1);
  }
  getComponentsPool(Component:Dynamic):ObjectPool<Component> {
    return this._componentPool.get(Component._typeId);
  }
}

const Version = "0.3.1";

const proxyMap = new WeakMap();

const proxyHandler:Dynamic = {
  set(target:Dynamic, prop:String, value:Dynamic):Bool {
    throw new Error("Tried to write to \"" + target.constructor.getName() + "#" + String(prop) + "\" on immutable component. Use .getMutableComponent() to modify a component.");
  }
};

function wrapImmutableComponent(T:Dynamic, component:Dynamic):Dynamic {
  if (component == null) {
    return null;
  }
  var wrappedComponent:Dynamic = proxyMap.get(component);
  if (wrappedComponent == null) {
    wrappedComponent = new Proxy(component, proxyHandler);
    proxyMap.set(component, wrappedComponent);
  }
  return wrappedComponent;
}

class Entity {
  _entityManager:EntityManager;
  id:Int;
  _ComponentTypes:Array<Dynamic>;
  _components:StringMap<Component>;
  _componentsToRemove:StringMap<Component>;
  queries:Array<Query>;
  _ComponentTypesToRemove:Array<Dynamic>;
  alive:Bool;
  name:String;
  numStateComponents:Int;
  constructor(entityManager:EntityManager = null) {
    this._entityManager = entityManager || null;
    // Unique ID for this entity
    this.id = entityManager._nextEntityId++;
    // List of components types the entity has
    this._ComponentTypes = new Array();
    //
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import js.Browser;
import js.html.Window;
import js.lib.Array;
import js.lib.Date;
import js.lib.Math;
import js.lib.Object;
import js.lib.Performance;
import js.lib.String;
import js.lib.TypeError;
import js.lib.WeakMap;

/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */
/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>):String {
  var ids:Array<String> = new Array();
  for (var n:Int = 0; n < Components.length; n++) {
    var T:Dynamic = Components[n];
    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }
    if (typeof T == "object") {
      var operator:String = T.operator == "not" ? "!" : T.operator;
      ids.push(operator + T.Component._typeId);
    } else {
      ids.push(T._typeId);
    }
  }
  return ids.sort().join("-");
}

// Detector for browser's "window"
const hasWindow = typeof Browser.window != "undefined";

// performance.now() "polyfill"
const now = hasWindow && typeof Window.performance != "undefined" ? Performance.now.bind(Performance) : Date.now.bind(Date);

function componentRegistered(T:Dynamic):Bool {
  return (typeof T == "object" && T.Component._typeId != null) || (T.isComponent && T._typeId != null);
}

class SystemManager {
  _systems:Array<System>;
  _executeSystems:Array<System>;
  world:World;
  lastExecutedSystem:System;
  constructor(world:World) {
    this._systems = new Array();
    this._executeSystems = new Array();
    this.world = world;
    this.lastExecutedSystem = null;
  }
  registerSystem(SystemClass:Dynamic, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }
    if (this.getSystem(SystemClass) != null) {
      console.warn("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }
    var system:System = new SystemClass(this.world, attributes);
    if (system.init) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }
  unregisterSystem(SystemClass:Dynamic):SystemManager {
    var system:System = this.getSystem(SystemClass);
    if (system == null) {
      console.warn("Can unregister system '" + SystemClass.getName() + "'. It doesn't exist.");
      return this;
    }
    this._systems.splice(this._systems.indexOf(system), 1);
    if (system.execute) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }
    // @todo Add system.unregister() call to free resources
    return this;
  }
  sortSystems():Void {
    this._executeSystems.sort((a:System, b:System) => {
      return a.priority - b.priority || a.order - b.order;
    });
  }
  getSystem(SystemClass:Dynamic):System {
    return this._systems.find((s:System) => s instanceof SystemClass);
  }
  getSystems():Array<System> {
    return this._systems;
  }
  removeSystem(SystemClass:Dynamic):Void {
    var index:Int = this._systems.indexOf(SystemClass);
    if (index < 0) return;
    this._systems.splice(index, 1);
  }
  executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }
  stop():Void {
    this._executeSystems.forEach((system:System) => system.stop());
  }
  execute(delta:Float, time:Float, forcePlay:Bool = false):Void {
    this._executeSystems.forEach((system:System) => (forcePlay || system.enabled) && this.executeSystem(system, delta, time));
  }
  stats():Dynamic {
    var stats:Dynamic = {
      numSystems: this._systems.length,
      systems: new StringMap()
    };
    for (var i:Int = 0; i < this._systems.length; i++) {
      var system:System = this._systems[i];
      var systemStats:Dynamic = stats.systems.set(system.getName(), {
        queries: new StringMap(),
        executeTime: system.executeTime
      });
      for (var name:String in system.ctx) {
        systemStats.queries.set(name, system.ctx[name].stats());
      }
    }
    return stats;
  }
}

class ObjectPool<T> {
  freeList:Array<T>;
  count:Int;
  T:Dynamic;
  isObjectPool:Bool;
  constructor(T:Dynamic, initialSize:Int = 0) {
    this.freeList = new Array();
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }
    var item:T = this.freeList.pop();
    return item;
  }
  release(item:T):Void {
    item.reset();
    this.freeList.push(item);
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:T = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
  totalSize():Int {
    return this.count;
  }
  totalFree():Int {
    return this.freeList.length;
  }
  totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  _listeners:StringMap<Array<Dynamic>>;
  stats:Dynamic;
  constructor() {
    this._listeners = new StringMap();
    this.stats = {
      fired: 0,
      handled: 0
    };
  }
  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  addEventListener(eventName:String, listener:Dynamic):Void {
    var listeners:StringMap<Array<Dynamic>> = this._listeners;
    if (listeners.exists(eventName)) {
      listeners.get(eventName).push(listener);
    } else {
      listeners.set(eventName, [listener]);
    }
  }
  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.exists(eventName) && this._listeners.get(eventName).indexOf(listener) != -1;
  }
  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  removeEventListener(eventName:String, listener:Dynamic):Void {
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var index:Int = listenerArray.indexOf(listener);
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
  dispatchEvent(eventName:String, entity:Entity = null, component:Dynamic = null):Void {
    this.stats.fired++;
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var array:Array<Dynamic> = listenerArray.slice(0);
      for (var i:Int = 0; i < array.length; i++) {
        array[i].call(this, entity, component);
      }
    }
  }
  /**
   * Reset stats counters
   */
  resetCounters():Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  Components:Array<Dynamic>;
  NotComponents:Array<Dynamic>;
  entities:Array<Entity>;
  eventDispatcher:EventDispatcher;
  reactive:Bool;
  key:String;
  constructor(Components:Array<Dynamic>, manager:QueryManager) {
    this.Components = new Array();
    this.NotComponents = new Array();
    Components.forEach((component:Dynamic) => {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });
    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }
    this.entities = new Array();
    this.eventDispatcher = new EventDispatcher();
    // This query is being used by a reactive system
    this.reactive = false;
    this.key = queryKey(Components);
    // Fill the query with the existing entities
    for (var i:Int = 0; i < manager._entities.length; i++) {
      var entity:Entity = manager._entities[i];
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
  addEntity(entity:Entity):Void {
    entity.queries.push(this);
    this.entities.push(entity);
    this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
  }
  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  removeEntity(entity:Entity):Void {
    var index:Int = this.entities.indexOf(entity);
    if (index >= 0) {
      this.entities.splice(index, 1);
      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);
      this.eventDispatcher.dispatchEvent(Query.ENTITY_REMOVED, entity);
    }
  }
  match(entity:Entity):Bool {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }
  toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C:Dynamic) => C.name),
        not: this.NotComponents.map((C:Dynamic) => C.name)
      },
      numEntities: this.entities.length
    };
  }
  /**
   * Return stats for this query
   */
  stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length
    };
  }
}

Query.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

/**
 * @private
 * @class QueryManager
 */
class QueryManager {
  _world:World;
  _queries:StringMap<Query>;
  constructor(world:World) {
    this._world = world;
    // Queries indexed by a unique identifier for the components it has
    this._queries = new StringMap();
  }
  onEntityRemoved(entity:Entity):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
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
  onEntityComponentAdded(entity:Entity, Component:Dynamic):Void {
    // @todo Use bitmask for checking components?
    // Check each indexed query to see if we need to add this entity to the list
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0) {
        query.removeEntity(entity);
        continue;
      }
      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (query.Components.indexOf(Component) < 0 || !query.match(entity) || query.entities.indexOf(entity) >= 0) continue;
      query.addEntity(entity);
    }
  }
  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  onEntityComponentRemoved(entity:Entity, Component:Dynamic):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) < 0 && query.match(entity)) {
        query.addEntity(entity);
        continue;
      }
      if (query.Components.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0 && !query.match(entity)) {
        query.removeEntity(entity);
        continue;
      }
    }
  }
  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  getQuery(Components:Array<Dynamic>):Query {
    var key:String = queryKey(Components);
    var query:Query = this._queries.get(key);
    if (query == null) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }
  /**
   * Return some stats from this class
   */
  stats():Dynamic {
    var stats:Dynamic = new StringMap();
    for (var queryName:String in this._queries) {
      stats.set(queryName, this._queries.get(queryName).stats());
    }
    return stats;
  }
}

class Component {
  _pool:ObjectPool<Component>;
  constructor(props:Dynamic = null) {
    if (props != false) {
      var schema:StringMap<Dynamic> = this.constructor.schema;
      for (var key:String in schema) {
        if (props && Object.prototype.hasOwnProperty.call(props, key)) {
          this[key] = props[key];
        } else {
          var schemaProp:Dynamic = schema[key];
          if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type:Dynamic = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }
      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
    this._pool = null;
  }
  copy(source:Dynamic):Component {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var prop:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }
    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }
    return this;
  }
  clone():Component {
    return new this.constructor().copy(this);
  }
  reset():Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var schemaProp:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        var type:Dynamic = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }
  dispose():Void {
    if (this._pool) {
      this._pool.release(this);
    }
  }
  getName():String {
    return this.constructor.getName();
  }
  checkUndefinedAttributes(src:Dynamic):Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    // Check that the attributes defined in source are also defined in the schema
    Object.keys(src).forEach((srcKey:String) => {
      if (!Object.prototype.hasOwnProperty.call(schema, srcKey)) {
        console.warn("Trying to set attribute '" + srcKey + "' not defined in the '" + this.constructor.name + "' schema. Please fix the schema, the attribute value won't be set");
      }
    });
  }
}

Component.schema = new StringMap();
Component.isComponent = true;
Component.getName = function():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool extends ObjectPool<Entity> {
  entityManager:EntityManager;
  constructor(entityManager:EntityManager, entityClass:Dynamic, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:Entity = new this.T(this.entityManager);
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
}

/**
 * @private
 * @class EntityManager
 */
class EntityManager {
  world:World;
  componentsManager:ComponentManager;
  _entities:Array<Entity>;
  _nextEntityId:Int;
  _entitiesByNames:StringMap<Entity>;
  _queryManager:QueryManager;
  eventDispatcher:EventDispatcher;
  _entityPool:EntityPool;
  entitiesWithComponentsToRemove:Array<Entity>;
  entitiesToRemove:Array<Entity>;
  deferredRemovalEnabled:Bool;
  constructor(world:World) {
    this.world = world;
    this.componentsManager = world.componentsManager;
    // All the entities in this instance
    this._entities = new Array();
    this._nextEntityId = 0;
    this._entitiesByNames = new StringMap();
    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);
    // Deferred deletion
    this.entitiesWithComponentsToRemove = new Array();
    this.entitiesToRemove = new Array();
    this.deferredRemovalEnabled = true;
  }
  getEntityByName(name:String):Entity {
    return this._entitiesByNames.get(name);
  }
  /**
   * Create a new entity
   */
  createEntity(name:String = null):Entity {
    var entity:Entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name || "";
    if (name) {
      if (this._entitiesByNames.exists(name)) {
        console.warn("Entity name '" + name + "' already exist");
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }
    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_CREATED, entity);
    return entity;
  }
  // COMPONENTS
  /**
   * Add a component to an entity
   * @param {Entity} entity Entity where the component will be added
   * @param {Component} Component Component to be added to the entity
   * @param {Object} values Optional values to replace the default attributes
   */
  entityAddComponent(entity:Entity, Component:Dynamic, values:Dynamic = null):Void {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }
    if (entity._ComponentTypes.indexOf(Component) >= 0) {
      {
        console.warn("Component type already exists on entity.", entity, Component.getName());
      }
      return;
    }
    entity._ComponentTypes.push(Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents++;
    }
    var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(Component);
    var component:Component = componentPool ? componentPool.acquire() : new Component(values);
    if (componentPool && values) {
      component.copy(values);
    }
    entity._components.set(Component._typeId, component);
    this._queryManager.onEntityComponentAdded(entity, Component);
    this.world.componentsManager.componentAddedToEntity(Component);
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_ADDED, entity, Component);
  }
  /**
   * Remove a component from an entity
   * @param {Entity} entity Entity which will get removed the component
   * @param {*} Component Component to remove from the entity
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  entityRemoveComponent(entity:Entity, Component:Dynamic, immediately:Bool = false):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index < 0) return;
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_REMOVE, entity, Component);
    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) this.entitiesWithComponentsToRemove.push(entity);
      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);
      entity._componentsToRemove.set(Component._typeId, entity._components.get(Component._typeId));
      entity._components.remove(Component._typeId);
    }
    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents--;
      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }
  _entityRemoveComponentSync(entity:Entity, Component:Dynamic, index:Int):Void {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component:Component = entity._components.get(Component._typeId);
    entity._components.remove(Component._typeId);
    component.dispose();
    this.world.componentsManager.componentRemovedFromEntity(Component);
  }
  /**
   * Remove all the components from an entity
   * @param {Entity} entity Entity from which the components will be removed
   */
  entityRemoveAllComponents(entity:Entity, immediately:Bool = false):Void {
    var Components:Array<Dynamic> = entity._ComponentTypes;
    for (var j:Int = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ != SystemStateComponent) this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }
  /**
   * Remove the entity from this manager. It will clear also its components
   * @param {Entity} entity Entity to remove from the manager
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  removeEntity(entity:Entity, immediately:Bool = false):Void {
    var index:Int = this._entities.indexOf(entity);
    if (index < 0) throw new Error("Tried to remove entity not in list");
    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);
    if (entity.numStateComponents == 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately == true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }
  _releaseEntity(entity:Entity, index:Int):Void {
    this._entities.splice(index, 1);
    if (this._entitiesByNames.exists(entity.name)) {
      this._entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }
  /**
   * Remove all entities from this manager
   */
  removeAllEntities():Void {
    for (var i:Int = this._entities.length - 1; i >= 0; i--) {
      this.removeEntity(this._entities[i]);
    }
  }
  processDeferredRemoval():Void {
    if (!this.deferredRemovalEnabled) {
      return;
    }
    for (var i:Int = 0; i < this.entitiesToRemove.length; i++) {
      var entity:Entity = this.entitiesToRemove[i];
      var index:Int = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;
    for (var i:Int = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      var entity:Entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Dynamic = entity._ComponentTypesToRemove.pop();
        var component:Component = entity._componentsToRemove.get(Component._typeId);
        entity._componentsToRemove.remove(Component._typeId);
        component.dispose();
        this.world.componentsManager.componentRemovedFromEntity(Component);
        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }
    this.entitiesWithComponentsToRemove.length = 0;
  }
  /**
   * Get a query based on a list of components
   * @param {Array(Component)} Components List of components that will form the query
   */
  queryComponents(Components:Array<Dynamic>):Query {
    return this._queryManager.getQuery(Components);
  }
  // EXTRAS
  /**
   * Return number of entities
   */
  count():Int {
    return this._entities.length;
  }
  /**
   * Return some stats
   */
  stats():Dynamic {
    var stats:Dynamic = {
      numEntities: this._entities.length,
      numQueries: Object.keys(this._queryManager._queries).length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: new StringMap(),
      eventDispatcher: this.eventDispatcher.stats
    };
    for (var ecsyComponentId:String in this.componentsManager._componentPool) {
      var pool:ObjectPool<Component> = this.componentsManager._componentPool.get(ecsyComponentId);
      stats.componentPool.set(pool.T.getName(), {
        used: pool.totalUsed(),
        size: pool.count
      });
    }
    return stats;
  }
}

EntityManager.ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
EntityManager.ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
EntityManager.COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
EntityManager.COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";

class ComponentManager {
  Components:Array<Dynamic>;
  _ComponentsMap:StringMap<Dynamic>;
  _componentPool:StringMap<ObjectPool<Component>>;
  numComponents:StringMap<Int>;
  nextComponentId:Int;
  constructor() {
    this.Components = new Array();
    this._ComponentsMap = new StringMap();
    this._componentPool = new StringMap();
    this.numComponents = new StringMap();
    this.nextComponentId = 0;
  }
  hasComponent(Component:Dynamic):Bool {
    return this.Components.indexOf(Component) != -1;
  }
  registerComponent(Component:Dynamic, objectPool:ObjectPool<Component> = null):Void {
    if (this.Components.indexOf(Component) != -1) {
      console.warn("Component type: '" + Component.getName() + "' already registered.");
      return;
    }
    var schema:StringMap<Dynamic> = Component.schema;
    if (schema == null) {
      throw new Error("Component \"" + Component.getName() + "\" has no schema property.");
    }
    for (var propName:String in schema) {
      var prop:Dynamic = schema[propName];
      if (prop.type == null) {
        throw new Error("Invalid schema for component \"" + Component.getName() + "\". Missing type for \"" + propName + "\" property.");
      }
    }
    Component._typeId = this.nextComponentId++;
    this.Components.push(Component);
    this._ComponentsMap.set(Component._typeId, Component);
    this.numComponents.set(Component._typeId, 0);
    if (objectPool == null) {
      objectPool = new ObjectPool(Component);
    } else if (objectPool == false) {
      objectPool = null;
    }
    this._componentPool.set(Component._typeId, objectPool);
  }
  componentAddedToEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) + 1);
  }
  componentRemovedFromEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) - 1);
  }
  getComponentsPool(Component:Dynamic):ObjectPool<Component> {
    return this._componentPool.get(Component._typeId);
  }
}

const Version = "0.3.1";

const proxyMap = new WeakMap();

const proxyHandler:Dynamic = {
  set(target:Dynamic, prop:String, value:Dynamic):Bool {
    throw new Error("Tried to write to \"" + target.constructor.getName() + "#" + String(prop) + "\" on immutable component. Use .getMutableComponent() to modify a component.");
  }
};

function wrapImmutableComponent(T:Dynamic, component:Dynamic):Dynamic {
  if (component == null) {
    return null;
  }
  var wrappedComponent:Dynamic = proxyMap.get(component);
  if (wrappedComponent == null) {
    wrappedComponent = new Proxy(component, proxyHandler);
    proxyMap.set(component, wrappedComponent);
  }
  return wrappedComponent;
}

class Entity {
  _entityManager:EntityManager;
  id:Int;
  _ComponentTypes:Array<Dynamic>;
  _components:StringMap<Component>;
  _componentsToRemove:StringMap<Component>;
  queries:Array<Query>;
  _ComponentTypesToRemove:Array<Dynamic>;
  alive:Bool;
  name:String;
  numStateComponents:Int;
  constructor(entityManager:EntityManager = null) {
    this._entityManager = entityManager || null;
    // Unique ID for this entity
    this.id = entityManager._nextEntityId++;
    // List of components types the entity has
    this._ComponentTypes = new Array();
    //
import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import js.Browser;
import js.html.Window;
import js.lib.Array;
import js.lib.Date;
import js.lib.Math;
import js.lib.Object;
import js.lib.Performance;
import js.lib.String;
import js.lib.TypeError;
import js.lib.WeakMap;

/**
 * Return the name of a component
 * @param {Component} Component
 * @private
 */
/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
function queryKey(Components:Array<Dynamic>):String {
  var ids:Array<String> = new Array();
  for (var n:Int = 0; n < Components.length; n++) {
    var T:Dynamic = Components[n];
    if (!componentRegistered(T)) {
      throw new Error("Tried to create a query with an unregistered component");
    }
    if (typeof T == "object") {
      var operator:String = T.operator == "not" ? "!" : T.operator;
      ids.push(operator + T.Component._typeId);
    } else {
      ids.push(T._typeId);
    }
  }
  return ids.sort().join("-");
}

// Detector for browser's "window"
const hasWindow = typeof Browser.window != "undefined";

// performance.now() "polyfill"
const now = hasWindow && typeof Window.performance != "undefined" ? Performance.now.bind(Performance) : Date.now.bind(Date);

function componentRegistered(T:Dynamic):Bool {
  return (typeof T == "object" && T.Component._typeId != null) || (T.isComponent && T._typeId != null);
}

class SystemManager {
  _systems:Array<System>;
  _executeSystems:Array<System>;
  world:World;
  lastExecutedSystem:System;
  constructor(world:World) {
    this._systems = new Array();
    this._executeSystems = new Array();
    this.world = world;
    this.lastExecutedSystem = null;
  }
  registerSystem(SystemClass:Dynamic, attributes:Dynamic):SystemManager {
    if (!SystemClass.isSystem) {
      throw new Error("System '" + SystemClass.name + "' does not extend 'System' class");
    }
    if (this.getSystem(SystemClass) != null) {
      console.warn("System '" + SystemClass.getName() + "' already registered.");
      return this;
    }
    var system:System = new SystemClass(this.world, attributes);
    if (system.init) system.init(attributes);
    system.order = this._systems.length;
    this._systems.push(system);
    if (system.execute) {
      this._executeSystems.push(system);
      this.sortSystems();
    }
    return this;
  }
  unregisterSystem(SystemClass:Dynamic):SystemManager {
    var system:System = this.getSystem(SystemClass);
    if (system == null) {
      console.warn("Can unregister system '" + SystemClass.getName() + "'. It doesn't exist.");
      return this;
    }
    this._systems.splice(this._systems.indexOf(system), 1);
    if (system.execute) {
      this._executeSystems.splice(this._executeSystems.indexOf(system), 1);
    }
    // @todo Add system.unregister() call to free resources
    return this;
  }
  sortSystems():Void {
    this._executeSystems.sort((a:System, b:System) => {
      return a.priority - b.priority || a.order - b.order;
    });
  }
  getSystem(SystemClass:Dynamic):System {
    return this._systems.find((s:System) => s instanceof SystemClass);
  }
  getSystems():Array<System> {
    return this._systems;
  }
  removeSystem(SystemClass:Dynamic):Void {
    var index:Int = this._systems.indexOf(SystemClass);
    if (index < 0) return;
    this._systems.splice(index, 1);
  }
  executeSystem(system:System, delta:Float, time:Float):Void {
    if (system.initialized) {
      if (system.canExecute()) {
        var startTime:Float = now();
        system.execute(delta, time);
        system.executeTime = now() - startTime;
        this.lastExecutedSystem = system;
        system.clearEvents();
      }
    }
  }
  stop():Void {
    this._executeSystems.forEach((system:System) => system.stop());
  }
  execute(delta:Float, time:Float, forcePlay:Bool = false):Void {
    this._executeSystems.forEach((system:System) => (forcePlay || system.enabled) && this.executeSystem(system, delta, time));
  }
  stats():Dynamic {
    var stats:Dynamic = {
      numSystems: this._systems.length,
      systems: new StringMap()
    };
    for (var i:Int = 0; i < this._systems.length; i++) {
      var system:System = this._systems[i];
      var systemStats:Dynamic = stats.systems.set(system.getName(), {
        queries: new StringMap(),
        executeTime: system.executeTime
      });
      for (var name:String in system.ctx) {
        systemStats.queries.set(name, system.ctx[name].stats());
      }
    }
    return stats;
  }
}

class ObjectPool<T> {
  freeList:Array<T>;
  count:Int;
  T:Dynamic;
  isObjectPool:Bool;
  constructor(T:Dynamic, initialSize:Int = 0) {
    this.freeList = new Array();
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }
    var item:T = this.freeList.pop();
    return item;
  }
  release(item:T):Void {
    item.reset();
    this.freeList.push(item);
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:T = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
  totalSize():Int {
    return this.count;
  }
  totalFree():Int {
    return this.freeList.length;
  }
  totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

/**
 * @private
 * @class EventDispatcher
 */
class EventDispatcher {
  _listeners:StringMap<Array<Dynamic>>;
  stats:Dynamic;
  constructor() {
    this._listeners = new StringMap();
    this.stats = {
      fired: 0,
      handled: 0
    };
  }
  /**
   * Add an event listener
   * @param {String} eventName Name of the event to listen
   * @param {Function} listener Callback to trigger when the event is fired
   */
  addEventListener(eventName:String, listener:Dynamic):Void {
    var listeners:StringMap<Array<Dynamic>> = this._listeners;
    if (listeners.exists(eventName)) {
      listeners.get(eventName).push(listener);
    } else {
      listeners.set(eventName, [listener]);
    }
  }
  /**
   * Check if an event listener is already added to the list of listeners
   * @param {String} eventName Name of the event to check
   * @param {Function} listener Callback for the specified event
   */
  hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.exists(eventName) && this._listeners.get(eventName).indexOf(listener) != -1;
  }
  /**
   * Remove an event listener
   * @param {String} eventName Name of the event to remove
   * @param {Function} listener Callback for the specified event
   */
  removeEventListener(eventName:String, listener:Dynamic):Void {
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var index:Int = listenerArray.indexOf(listener);
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
  dispatchEvent(eventName:String, entity:Entity = null, component:Dynamic = null):Void {
    this.stats.fired++;
    var listenerArray:Array<Dynamic> = this._listeners.get(eventName);
    if (listenerArray != null) {
      var array:Array<Dynamic> = listenerArray.slice(0);
      for (var i:Int = 0; i < array.length; i++) {
        array[i].call(this, entity, component);
      }
    }
  }
  /**
   * Reset stats counters
   */
  resetCounters():Void {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  Components:Array<Dynamic>;
  NotComponents:Array<Dynamic>;
  entities:Array<Entity>;
  eventDispatcher:EventDispatcher;
  reactive:Bool;
  key:String;
  constructor(Components:Array<Dynamic>, manager:QueryManager) {
    this.Components = new Array();
    this.NotComponents = new Array();
    Components.forEach((component:Dynamic) => {
      if (typeof component == "object") {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });
    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }
    this.entities = new Array();
    this.eventDispatcher = new EventDispatcher();
    // This query is being used by a reactive system
    this.reactive = false;
    this.key = queryKey(Components);
    // Fill the query with the existing entities
    for (var i:Int = 0; i < manager._entities.length; i++) {
      var entity:Entity = manager._entities[i];
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
  addEntity(entity:Entity):Void {
    entity.queries.push(this);
    this.entities.push(entity);
    this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
  }
  /**
   * Remove entity from this query
   * @param {Entity} entity
   */
  removeEntity(entity:Entity):Void {
    var index:Int = this.entities.indexOf(entity);
    if (index >= 0) {
      this.entities.splice(index, 1);
      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);
      this.eventDispatcher.dispatchEvent(Query.ENTITY_REMOVED, entity);
    }
  }
  match(entity:Entity):Bool {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }
  toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C:Dynamic) => C.name),
        not: this.NotComponents.map((C:Dynamic) => C.name)
      },
      numEntities: this.entities.length
    };
  }
  /**
   * Return stats for this query
   */
  stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length
    };
  }
}

Query.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

/**
 * @private
 * @class QueryManager
 */
class QueryManager {
  _world:World;
  _queries:StringMap<Query>;
  constructor(world:World) {
    this._world = world;
    // Queries indexed by a unique identifier for the components it has
    this._queries = new StringMap();
  }
  onEntityRemoved(entity:Entity):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
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
  onEntityComponentAdded(entity:Entity, Component:Dynamic):Void {
    // @todo Use bitmask for checking components?
    // Check each indexed query to see if we need to add this entity to the list
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0) {
        query.removeEntity(entity);
        continue;
      }
      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (query.Components.indexOf(Component) < 0 || !query.match(entity) || query.entities.indexOf(entity) >= 0) continue;
      query.addEntity(entity);
    }
  }
  /**
   * Callback when a component is removed from an entity
   * @param {Entity} entity Entity to remove the component from
   * @param {Component} Component Component to remove from the entity
   */
  onEntityComponentRemoved(entity:Entity, Component:Dynamic):Void {
    for (var queryName:String in this._queries) {
      var query:Query = this._queries.get(queryName);
      if (query.NotComponents.indexOf(Component) >= 0 && query.entities.indexOf(entity) < 0 && query.match(entity)) {
        query.addEntity(entity);
        continue;
      }
      if (query.Components.indexOf(Component) >= 0 && query.entities.indexOf(entity) >= 0 && !query.match(entity)) {
        query.removeEntity(entity);
        continue;
      }
    }
  }
  /**
   * Get a query for the specified components
   * @param {Component} Components Components that the query should have
   */
  getQuery(Components:Array<Dynamic>):Query {
    var key:String = queryKey(Components);
    var query:Query = this._queries.get(key);
    if (query == null) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }
  /**
   * Return some stats from this class
   */
  stats():Dynamic {
    var stats:Dynamic = new StringMap();
    for (var queryName:String in this._queries) {
      stats.set(queryName, this._queries.get(queryName).stats());
    }
    return stats;
  }
}

class Component {
  _pool:ObjectPool<Component>;
  constructor(props:Dynamic = null) {
    if (props != false) {
      var schema:StringMap<Dynamic> = this.constructor.schema;
      for (var key:String in schema) {
        if (props && Object.prototype.hasOwnProperty.call(props, key)) {
          this[key] = props[key];
        } else {
          var schemaProp:Dynamic = schema[key];
          if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type:Dynamic = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }
      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }
    this._pool = null;
  }
  copy(source:Dynamic):Component {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var prop:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        this[key] = prop.type.copy(source[key], this[key]);
      }
    }
    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }
    return this;
  }
  clone():Component {
    return new this.constructor().copy(this);
  }
  reset():Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    for (var key:String in schema) {
      var schemaProp:Dynamic = schema[key];
      if (Object.prototype.hasOwnProperty.call(schemaProp, "default")) {
        this[key] = schemaProp.type.copy(schemaProp.default, this[key]);
      } else {
        var type:Dynamic = schemaProp.type;
        this[key] = type.copy(type.default, this[key]);
      }
    }
  }
  dispose():Void {
    if (this._pool) {
      this._pool.release(this);
    }
  }
  getName():String {
    return this.constructor.getName();
  }
  checkUndefinedAttributes(src:Dynamic):Void {
    var schema:StringMap<Dynamic> = this.constructor.schema;
    // Check that the attributes defined in source are also defined in the schema
    Object.keys(src).forEach((srcKey:String) => {
      if (!Object.prototype.hasOwnProperty.call(schema, srcKey)) {
        console.warn("Trying to set attribute '" + srcKey + "' not defined in the '" + this.constructor.name + "' schema. Please fix the schema, the attribute value won't be set");
      }
    });
  }
}

Component.schema = new StringMap();
Component.isComponent = true;
Component.getName = function():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool extends ObjectPool<Entity> {
  entityManager:EntityManager;
  constructor(entityManager:EntityManager, entityClass:Dynamic, initialSize:Int = 0) {
    super(entityClass, null);
    this.entityManager = entityManager;
    if (initialSize != null) {
      this.expand(initialSize);
    }
  }
  expand(count:Int):Void {
    for (var n:Int = 0; n < count; n++) {
      var clone:Entity = new this.T(this.entityManager);
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }
}

/**
 * @private
 * @class EntityManager
 */
class EntityManager {
  world:World;
  componentsManager:ComponentManager;
  _entities:Array<Entity>;
  _nextEntityId:Int;
  _entitiesByNames:StringMap<Entity>;
  _queryManager:QueryManager;
  eventDispatcher:EventDispatcher;
  _entityPool:EntityPool;
  entitiesWithComponentsToRemove:Array<Entity>;
  entitiesToRemove:Array<Entity>;
  deferredRemovalEnabled:Bool;
  constructor(world:World) {
    this.world = world;
    this.componentsManager = world.componentsManager;
    // All the entities in this instance
    this._entities = new Array();
    this._nextEntityId = 0;
    this._entitiesByNames = new StringMap();
    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);
    // Deferred deletion
    this.entitiesWithComponentsToRemove = new Array();
    this.entitiesToRemove = new Array();
    this.deferredRemovalEnabled = true;
  }
  getEntityByName(name:String):Entity {
    return this._entitiesByNames.get(name);
  }
  /**
   * Create a new entity
   */
  createEntity(name:String = null):Entity {
    var entity:Entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name || "";
    if (name) {
      if (this._entitiesByNames.exists(name)) {
        console.warn("Entity name '" + name + "' already exist");
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }
    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_CREATED, entity);
    return entity;
  }
  // COMPONENTS
  /**
   * Add a component to an entity
   * @param {Entity} entity Entity where the component will be added
   * @param {Component} Component Component to be added to the entity
   * @param {Object} values Optional values to replace the default attributes
   */
  entityAddComponent(entity:Entity, Component:Dynamic, values:Dynamic = null):Void {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }
    if (entity._ComponentTypes.indexOf(Component) >= 0) {
      {
        console.warn("Component type already exists on entity.", entity, Component.getName());
      }
      return;
    }
    entity._ComponentTypes.push(Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents++;
    }
    var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(Component);
    var component:Component = componentPool ? componentPool.acquire() : new Component(values);
    if (componentPool && values) {
      component.copy(values);
    }
    entity._components.set(Component._typeId, component);
    this._queryManager.onEntityComponentAdded(entity, Component);
    this.world.componentsManager.componentAddedToEntity(Component);
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_ADDED, entity, Component);
  }
  /**
   * Remove a component from an entity
   * @param {Entity} entity Entity which will get removed the component
   * @param {*} Component Component to remove from the entity
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  entityRemoveComponent(entity:Entity, Component:Dynamic, immediately:Bool = false):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index < 0) return;
    this.eventDispatcher.dispatchEvent(EntityManager.COMPONENT_REMOVE, entity, Component);
    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) this.entitiesWithComponentsToRemove.push(entity);
      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);
      entity._componentsToRemove.set(Component._typeId, entity._components.get(Component._typeId));
      entity._components.remove(Component._typeId);
    }
    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);
    if (Component.__proto__ == SystemStateComponent) {
      entity.numStateComponents--;
      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }
  _entityRemoveComponentSync(entity:Entity, Component:Dynamic, index:Int):Void {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component:Component = entity._components.get(Component._typeId);
    entity._components.remove(Component._typeId);
    component.dispose();
    this.world.componentsManager.componentRemovedFromEntity(Component);
  }
  /**
   * Remove all the components from an entity
   * @param {Entity} entity Entity from which the components will be removed
   */
  entityRemoveAllComponents(entity:Entity, immediately:Bool = false):Void {
    var Components:Array<Dynamic> = entity._ComponentTypes;
    for (var j:Int = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ != SystemStateComponent) this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }
  /**
   * Remove the entity from this manager. It will clear also its components
   * @param {Entity} entity Entity to remove from the manager
   * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  removeEntity(entity:Entity, immediately:Bool = false):Void {
    var index:Int = this._entities.indexOf(entity);
    if (index < 0) throw new Error("Tried to remove entity not in list");
    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);
    if (entity.numStateComponents == 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(EntityManager.ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately == true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }
  _releaseEntity(entity:Entity, index:Int):Void {
    this._entities.splice(index, 1);
    if (this._entitiesByNames.exists(entity.name)) {
      this._entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }
  /**
   * Remove all entities from this manager
   */
  removeAllEntities():Void {
    for (var i:Int = this._entities.length - 1; i >= 0; i--) {
      this.removeEntity(this._entities[i]);
    }
  }
  processDeferredRemoval():Void {
    if (!this.deferredRemovalEnabled) {
      return;
    }
    for (var i:Int = 0; i < this.entitiesToRemove.length; i++) {
      var entity:Entity = this.entitiesToRemove[i];
      var index:Int = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;
    for (var i:Int = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      var entity:Entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Dynamic = entity._ComponentTypesToRemove.pop();
        var component:Component = entity._componentsToRemove.get(Component._typeId);
        entity._componentsToRemove.remove(Component._typeId);
        component.dispose();
        this.world.componentsManager.componentRemovedFromEntity(Component);
        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }
    this.entitiesWithComponentsToRemove.length = 0;
  }
  /**
   * Get a query based on a list of components
   * @param {Array(Component)} Components List of components that will form the query
   */
  queryComponents(Components:Array<Dynamic>):Query {
    return this._queryManager.getQuery(Components);
  }
  // EXTRAS
  /**
   * Return number of entities
   */
  count():Int {
    return this._entities.length;
  }
  /**
   * Return some stats
   */
  stats():Dynamic {
    var stats:Dynamic = {
      numEntities: this._entities.length,
      numQueries: Object.keys(this._queryManager._queries).length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: new StringMap(),
      eventDispatcher: this.eventDispatcher.stats
    };
    for (var ecsyComponentId:String in this.componentsManager._componentPool) {
      var pool:ObjectPool<Component> = this.componentsManager._componentPool.get(ecsyComponentId);
      stats.componentPool.set(pool.T.getName(), {
        used: pool.totalUsed(),
        size: pool.count
      });
    }
    return stats;
  }
}

EntityManager.ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
EntityManager.ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
EntityManager.COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
EntityManager.COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";

class ComponentManager {
  Components:Array<Dynamic>;
  _ComponentsMap:StringMap<Dynamic>;
  _componentPool:StringMap<ObjectPool<Component>>;
  numComponents:StringMap<Int>;
  nextComponentId:Int;
  constructor() {
    this.Components = new Array();
    this._ComponentsMap = new StringMap();
    this._componentPool = new StringMap();
    this.numComponents = new StringMap();
    this.nextComponentId = 0;
  }
  hasComponent(Component:Dynamic):Bool {
    return this.Components.indexOf(Component) != -1;
  }
  registerComponent(Component:Dynamic, objectPool:ObjectPool<Component> = null):Void {
    if (this.Components.indexOf(Component) != -1) {
      console.warn("Component type: '" + Component.getName() + "' already registered.");
      return;
    }
    var schema:StringMap<Dynamic> = Component.schema;
    if (schema == null) {
      throw new Error("Component \"" + Component.getName() + "\" has no schema property.");
    }
    for (var propName:String in schema) {
      var prop:Dynamic = schema[propName];
      if (prop.type == null) {
        throw new Error("Invalid schema for component \"" + Component.getName() + "\". Missing type for \"" + propName + "\" property.");
      }
    }
    Component._typeId = this.nextComponentId++;
    this.Components.push(Component);
    this._ComponentsMap.set(Component._typeId, Component);
    this.numComponents.set(Component._typeId, 0);
    if (objectPool == null) {
      objectPool = new ObjectPool(Component);
    } else if (objectPool == false) {
      objectPool = null;
    }
    this._componentPool.set(Component._typeId, objectPool);
  }
  componentAddedToEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) + 1);
  }
  componentRemovedFromEntity(Component:Dynamic):Void {
    this.numComponents.set(Component._typeId, this.numComponents.get(Component._typeId) - 1);
  }
  getComponentsPool(Component:Dynamic):ObjectPool<Component> {
    return this._componentPool.get(Component._typeId);
  }
}

const Version = "0.3.1";

const proxyMap = new WeakMap();

const proxyHandler:Dynamic = {
  set(target:Dynamic, prop:String, value:Dynamic):Bool {
    throw new Error("Tried to write to \"" + target.constructor.getName() + "#" + String(prop) + "\" on immutable component. Use .getMutableComponent() to modify a component.");
  }
};

function wrapImmutableComponent(T:Dynamic, component:Dynamic):Dynamic {
  if (component == null) {
    return null;
  }
  var wrappedComponent:Dynamic = proxyMap.get(component);
  if (wrappedComponent == null) {
    wrappedComponent = new Proxy(component, proxyHandler);
    proxyMap.set(component, wrappedComponent);
  }
  return wrappedComponent;
}

class Entity {
  _entityManager:EntityManager;
  id:Int;
  _ComponentTypes:Array<Dynamic>;
  _components:StringMap<Component>;
  _componentsToRemove:StringMap<Component>;
  queries:Array<Query>;
  _ComponentTypesToRemove:Array<Dynamic>;
  alive:Bool;
  name:String;
  numStateComponents:Int;
  constructor(entityManager:EntityManager = null) {
    this._entityManager = entityManager || null;
    // Unique ID for this entity
    this.id = entityManager._nextEntityId++;
    // List of components types the entity has
    this._ComponentTypes = new Array();
    //