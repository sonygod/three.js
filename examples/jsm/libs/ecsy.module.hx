class Component {
  public var _pool:ObjectPool<Dynamic>;
  public var _typeId:Int;

  public function new(props:Dynamic = false) {
    if (props !== false) {
      var schema = this.constructor.schema;

      for (key in schema) {
        if (props.hasOwnProperty(key)) {
          this[key] = schema[key].type.clone(props[key]);
        } else {
          var schemaProp = schema[key];
          if (schemaProp.hasOwnProperty("default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }

      if (props !== undefined) {
        this.checkUndefinedAttributes(props);
      }
    }

    this._pool = null;
  }

  public function copy(source:Dynamic) {
    var schema = this.constructor.schema;

    for (key in schema) {
      var schemaProp = schema[key];

      if (source.hasOwnProperty(key)) {
        this[key] = schemaProp.type.clone(source[key], this[key]);
      }
    }

    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }

    return this;
  }

  public function clone():Dynamic {
    return new this.constructor().copy(this);
  }

  public function reset() {
    var schema = this.constructor.schema;

    for (key in schema) {
      var schemaProp = schema[key];

      if (schemaProp.hasOwnProperty("default")) {
        this[key] = schemaProp.type.clone(schemaProp.default, this[key]);
      } else {
        var type = schemaProp.type;
        this[key] = type.clone(type.default, this[key]);
      }
    }
  }

  public function dispose() {
    if (this._pool) {
      this._pool.release(this);
    }
  }

  public function getName():String {
    return this.constructor.getName();
  }

  public function checkUndefinedAttributes(src:Dynamic) {
    var schema = this.constructor.schema;

    // Check that the attributes defined in source are also defined in the schema
    for (srcKey in src) {
      if (!schema.hasOwnProperty(srcKey)) {
        throw new Error(
          `Trying to set attribute '${srcKey}' not defined in the '${this.constructor.name}' schema. Please fix the schema, the attribute value won't be set`
        );
      }
    }
  }
}

Component.schema = {};
Component.isComponent = true;
Component.getName = function ():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
  public var numStateComponents:Int;

  public function new() {
    super();
    this.numStateComponents = 0;
  }
}

SystemStateComponent.isSystemStateComponent = true;

class ObjectPool<T> {
  public var freeList:Array<T>;
  public var count:Int;
  public var T:Class<T>;
  public var isObjectPool:Bool;

  public function new(T:Class<T>, initialSize:Int = 0) {
    this.freeList = [];
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;

    if (initialSize > 0) {
      this.expand(initialSize);
    }
  }

  public function acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }

    var item = this.freeList.pop();

    return item;
  }

  public function release(item:T) {
    item.reset();
    this.freeList.push(item);
  }

  public function expand(count:Int) {
    for (n in 0...count) {
      var clone = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }

  public function totalSize():Int {
    return this.count;
  }

  public function totalFree():Int {
    return this.freeList.length;
  }

  public function totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

class EventDispatcher {
  public var _listeners:Map<String, Array<Dynamic>>;
  public var stats: { fired:Int, handled:Int };

  public function new() {
    this._listeners = new Map<String, Array<Dynamic>>();
    this.stats = { fired: 0, handled: 0 };
  }

  public function addEventListener(eventName:String, listener:Dynamic) {
    if (this._listeners.hasKey(eventName)) {
      this._listeners.get(eventName).push(listener);
    } else {
      this._listeners.set(eventName, [listener]);
    }
  }

  public function hasEventListener(eventName:String, listener:Dynamic):Bool {
    return this._listeners.hasKey(eventName) && this._listeners.get(eventName).indexOf(listener) !== -1;
  }

  public function removeEventListener(eventName:String, listener:Dynamic) {
    if (this._listeners.hasKey(eventName)) {
      var array = this._listeners.get(eventName);
      var index = array.indexOf(listener);
      if (index !== -1) {
        array.splice(index, 1);
      }
    }
  }

  public function dispatchEvent(eventName:String, entity:Dynamic = null, component:Dynamic = null) {
    this.stats.fired++;

    if (this._listeners.hasKey(eventName)) {
      var array = this._listeners.get(eventName);

      for (listener in array) {
        listener(entity, component);
      }
    }
  }

  public function resetCounters() {
    this.stats.fired = this.stats.handled = 0;
  }
}

class Query {
  public var Components:Array<Class<Dynamic>>;
  public var NotComponents:Array<Class<Dynamic>>;
  public var entities:Array<Dynamic>;
  public var eventDispatcher:EventDispatcher;
  public var reactive:Bool;
  public var key:String;

  public function new(Components:Array<Class<Dynamic>>, manager:World) {
    this.Components = [];
    this.NotComponents = [];

    Components.forEach((component) => {
      if (typeof component === Dynamic) {
        this.NotComponents.push(component.Component);
      } else {
        this.Components.push(component);
      }
    });

    if (this.Components.length === 0) {
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

  public function addEntity(entity:Dynamic) {
    entity.queries.push(this);
    this.entities.push(entity);

    this.eventDispatcher.dispatchEvent(Query.prototype.ENTITY_ADDED, entity);
  }

  public function removeEntity(entity:Dynamic) {
    let index = this.entities.indexOf(entity);
    if (index !== -1) {
      this.entities.splice(index, 1);

      index = entity.queries.indexOf(this);
      entity.queries.splice(index, 1);

      this.eventDispatcher.dispatchEvent(
        Query.prototype.ENTITY_REMOVED,
        entity
      );
    }
  }

  public function match(entity:Dynamic):Bool {
    return (
      entity.hasAllComponents(this.Components) &&
      !entity.hasAnyComponents(this.NotComponents)
    );
  }

  public function toJSON():Dynamic {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: this.Components.map((C) => C.name),
        not: this.NotComponents.map((C) => C.name),
      },
      numEntities: this.entities.length,
    };
  }

  public function stats():Dynamic {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length,
    };
  }
}

Query.prototype.ENTITY_ADDED = "Query#ENTITY_ADDED";
Query.prototype.ENTITY_REMOVED = "Query#ENTITY_REMOVED";
Query.prototype.COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";

class QueryManager {
  public var _world:World;
  public var _queries:Map<String, Query>;

  public function new(world:World) {
    this._world = world;

    // Queries indexed by a unique identifier for the components it has
    this._queries = new Map<String, Query>();
  }

  public function onEntityRemoved(entity:Dynamic) {
    for (queryName in this._queries) {
      var query = this._queries.get(queryName);
      if (entity.queries.indexOf(query) !== -1) {
        query.removeEntity(entity);
      }
    }
  }

  public function onEntityComponentAdded(entity:Dynamic, Component:Class<Dynamic>) {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (
      typeof Component._typeId === "undefined" &&
      !this._world.componentsManager._ComponentsMap.hasKey(Component._typeId)
    ) {
      throw new Error(
        `Attempted to add unregistered component "${Component.getName()}"`
      );
    }

    if (~entity._ComponentTypes.indexOf(Component)) {
      {
        console.warn(
          "Component type already exists on entity.",
          entity,
          Component.getName()
        );
      }
      return;
    }

    entity._ComponentTypes.push(Component);

    if (Component.__proto__ === SystemStateComponent) {
      entity.numStateComponents++;
    }

    var componentPool = this._world.componentsManager.getComponentsPool(Component);

    var component = componentPool
      ? componentPool.acquire()
      : new Component();

    if (componentPool && props) {
      component.copy(props);
    }

    entity._components[Component._typeId] = component;

    this._queryManager.onEntityComponentAdded(entity, Component);
    this._world.componentsManager.componentAddedToEntity(Component);

    this.eventDispatcher.dispatchEvent(COMPONENT_ADDED, entity, Component);
  }

  public function onEntityComponentRemoved(entity:Dynamic, Component:Class<Dynamic>) {
    for (queryName in this._queries) {
      var query = this._queries.get(queryName);

      if (
        !!~query.NotComponents.indexOf(Component) &&
        ~query.entities.indexOf(entity)
      ) {
        query.removeEntity(entity);
        continue;
      }

      // Add the entity only if:
      // Component is in the query
      // and Entity has ALL the components of the query
      // and Entity is not already in the query
      if (
        !~query.Components.indexOf(Component) ||
        !query.match(entity) ||
        ~query.entities.indexOf(entity)
      )
        continue;

      query.addEntity(entity);
    }
  }

  public function getQuery(Components:Array<Class<Dynamic>>):Query {
    var key = queryKey(Components);
    var query = this._queries.get(key);
    if (!query) {
      this._queries.set(key, query = new Query(Components, this._world));
    }
    return query;
  }

  public function stats():Dynamic {
    var stats = {};
    for (queryName in this._queries) {
      stats[queryName] = this._queries.get(queryName).stats();
    }
    return stats;
  }
}

class Component {
  public var _pool:ObjectPool<Dynamic>;
  public var _typeId:Int;

  public function new(props:Dynamic = false) {
    if (props !== false) {
      var schema = this.constructor.schema;

      for (key in schema) {
        if (props.hasOwnProperty(key)) {
          this[key] = schema[key].type.clone(props[key]);
        } else {
          var schemaProp = schema[key];
          if (schemaProp.hasOwnProperty("default")) {
            this[key] = schemaProp.type.clone(schemaProp.default);
          } else {
            var type = schemaProp.type;
            this[key] = type.clone(type.default);
          }
        }
      }

      if (props !== undefined) {
        this.checkUndefinedAttributes(props);
      }
    }

    this._pool = null;
  }

  public function copy(source:Dynamic) {
    var schema = this.constructor.schema;

    for (key in schema) {
      var schemaProp = schema[key];

      if (source.hasOwnProperty(key)) {
        this[key] = schemaProp.type.clone(source[key], this[key]);
      }
    }

    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }

    return this;
  }

  public function clone():Dynamic {
    return new this.constructor().copy(this);
  }

  public function reset() {
    var schema = this.constructor.schema;

    for (key in schema) {
      var schemaProp = schema[key];

      if (schemaProp.hasOwnProperty("default")) {
        this[key] = schemaProp.type.clone(schemaProp.default, this[key]);
      } else {
        var type = schemaProp.type;
        this[key] = type.clone(type.default, this[key]);
      }
    }
  }

  public function dispose() {
    if (this._pool) {
      this._pool.release(this);
    }
  }

  public function getName():String {
    return this.constructor.getName();
  }

  public function checkUndefinedAttributes(src:Dynamic) {
    var schema = this.constructor.schema;

    // Check that the attributes defined in source are also defined in the schema
    for (srcKey in src) {
      if (!schema.hasOwnProperty(srcKey)) {
        throw new Error(
          `Trying to set attribute '${srcKey}' not defined in the '${this.constructor.name}' schema. Please fix the schema, the attribute value won't be set`
        );
      }
    }
  }
}

Component.schema = {};
Component.isComponent = true;
Component.getName = function ():String {
  return this.displayName || this.name;
};

class SystemStateComponent extends Component {
  public var numStateComponents:Int;

  public function new() {
    super();
    this.numStateComponents = 0;
  }
}

SystemStateComponent.isSystemStateComponent = true;

class EntityPool<T> {
  public var freeList:Array<T>;
  public var count:Int;
  public var T:Class<T>;
  public var isObjectPool:Bool;

  public function new(T:Class<T>, initialSize:Int = 0) {
    this.freeList = [];
    this.count = 0;
    this.T = T;
    this.isObjectPool = true;

    if (initialSize > 0) {
      this.expand(initialSize);
    }
  }

  public function acquire():T {
    // Grow the list by 20%ish if we're out
    if (this.freeList.length <= 0) {
      this.expand(Math.round(this.count * 0.2) + 1);
    }

    var item = this.freeList.pop();

    return item;
  }

  public function release(item:T) {
    item.reset();
    this.freeList.push(item);
  }

  public function expand(count:Int) {
    for (n in 0...count) {
      var clone = new this.T();
      clone._pool = this;
      this.freeList.push(clone);
    }
    this.count += count;
  }

  public function totalSize():Int {
    return this.count;
  }

  public function totalFree():Int {
    return this.freeList.length;
  }

  public function totalUsed():Int {
    return this.count - this.freeList.length;
  }
}

class EntityManager {
  public var _world:World;
  public var _entities:Array<Dynamic>;
  public var _nextEntityId:Int;
  public var _entitiesByNames:Map<String, Dynamic>;
  public var _queryManager:QueryManager;
  public var eventDispatcher:EventDispatcher;
  public var _entityPool:EntityPool<Dynamic>;

  public function new(world:World) {
    this._world = world;
    this._entities = [];
    this._nextEntityId = 0;
    this._entitiesByNames = new Map<String, Dynamic>();
    this._queryManager = new QueryManager(world);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool<Dynamic>(world.options.entityClass, world.options.entityPoolSize);

    // Deferred deletion
    this.entitiesWithComponentsToRemove = [];
    this.entitiesToRemove = [];
    this.deferredRemovalEnabled = true;
  }

  public function getEntityByName(name:String):Dynamic {
    return this._entitiesByNames.get(name);
  }

  public function createEntity(name:String = ""):Dynamic {
    var entity = this._entityPool.acquire();
    entity.alive = true;
    entity.name = name;
    if (name) {
      if (this._entitiesByNames.hasKey(name)) {
        console.warn(`Entity name '${name}' already exist`);
      } else {
        this._entitiesByNames.set(name, entity);
      }
    }

    this._entities.push(entity);
    this.eventDispatcher.dispatchEvent(ENTITY_CREATED, entity);
    return entity;
  }

  // COMPONENTS

  public function entityAddComponent(entity:Dynamic, Component:Class<Dynamic>, props:Dynamic = false) {
    // @todo Probably define Component._typeId with a default value and avoid using typeof
    if (
      typeof Component._typeId === "undefined" &&
      !this._world.componentsManager._ComponentsMap.hasKey(Component._typeId)
    ) {
      throw new Error(
        `Attempted to add unregistered component "${Component.getName()}"`
      );
    }

    if (~entity._ComponentTypes.indexOf(Component)) {
      {
        console.warn(
          "Component type already exists on entity.",
          entity,
          Component.getName()
        );
      }
      return;
    }

    entity._ComponentTypes.push(Component);

    if (Component.__proto__ === SystemStateComponent) {
      entity.numStateComponents++;
    }

    var componentPool = this._world.componentsManager.getComponentsPool(Component);

    var component = componentPool
      ? componentPool.acquire()
      : new Component();

    if (componentPool && props) {
      component.copy(props);
    }

    entity._components[Component._typeId] = component;

    this._queryManager.onEntityComponentAdded(entity, Component);
    this._world.componentsManager.componentAddedToEntity(Component);

    this.eventDispatcher.dispatchEvent(COMPONENT_ADDED, entity, Component);
  }

  public function entityRemoveComponent(entity:Dynamic, Component:Class<Dynamic>, immediately:Bool = false) {
    var index = entity._ComponentTypes.indexOf(Component);
    if (index === -1) return;

    this.eventDispatcher.dispatchEvent(COMPONENT_REMOVE, entity, Component);

    if (immediately) {
      this._entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length === 0)
        this.entitiesWithComponentsToRemove.push(entity);

      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);

      entity._componentsToRemove[Component._typeId] =
        entity._components[Component._typeId];
      delete entity._components[Component._typeId];
    }

    // Check each indexed query to see if we need to remove it
    this._queryManager.onEntityComponentRemoved(entity, Component);

    if (Component.__proto__ === SystemStateComponent) {
      entity.numStateComponents--;

      // Check if the entity was a ghost waiting for the last system state component to be removed
      if (entity.numStateComponents === 0 && !entity.alive) {
        entity.remove();
      }
    }
  }

  public function _entityRemoveComponentSync(entity:Dynamic, Component:Class<Dynamic>, index:Int) {
    // Remove T listing on entity and property ref, then free the component.
    entity._ComponentTypes.splice(index, 1);
    var component = entity._components[Component._typeId];
    delete entity._components[Component._typeId];
    component.dispose();
    this._world.componentsManager.componentRemovedFromEntity(Component);
  }

  public function entityRemoveAllComponents(entity:Dynamic, immediately:Bool = false) {
    let Components = entity._ComponentTypes;

    for (let j = Components.length - 1; j >= 0; j--) {
      if (Components[j].__proto__ !== SystemStateComponent)
        this.entityRemoveComponent(entity, Components[j], immediately);
    }
  }

  public function removeEntity(entity:Dynamic, immediately:Bool = false) {
    var index = this._entities.indexOf(entity);

    if (index === -1) throw new Error("Tried to remove entity not in list");

    entity.alive = false;
    this.entityRemoveAllComponents(entity, immediately);

    if (entity.numStateComponents === 0) {
      // Remove from entity list
      this.eventDispatcher.dispatchEvent(ENTITY_REMOVED, entity);
      this._queryManager.onEntityRemoved(entity);
      if (immediately === true) {
        this._releaseEntity(entity, index);
      } else {
        this.entitiesToRemove.push(entity);
      }
    }
  }

  public function _releaseEntity(entity:Dynamic, index:Int) {
    this._entities.splice(index, 1);

    if (this._entitiesByNames.hasKey(entity.name)) {
      delete this._entitiesByNames[entity.name];
    }
    entity._pool.release(entity);
  }

  public function processDeferredRemoval() {
    if (!this.deferredRemovalEnabled) {
      return;
    }

    for (let i = 0; i < this.entitiesToRemove.length; i++) {
      let entity = this.entitiesToRemove[i];
      let index = this._entities.indexOf(entity);
      this._releaseEntity(entity, index);
    }
    this.entitiesToRemove.length = 0;

    for (let i = 0; i < this.entitiesWithComponentsToRemove.length; i++) {
      let entity = this.entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        let Component = entity._ComponentTypesToRemove.pop();

        var component = entity._componentsToRemove[Component._typeId];
        delete entity._componentsToRemove[Component._typeId];
        component.dispose();
        this._world.componentsManager.componentRemovedFromEntity(Component);

        //this._entityRemoveComponentSync(entity, Component, index);
      }
    }

    this.entitiesWithComponentsToRemove.length = 0;
  }

  public function queryComponents(Components:Array<Class<Dynamic>>):Query {
    return this._queryManager.getQuery(Components);
  }

  // EXTRAS

  public function count():Int {
    return this._entities.length;
  }

  public function stats():Dynamic {
    var stats = {
      numEntities: this._entities.length,
      numQueries: this._queryManager._queries.length,
      queries: this._queryManager.stats(),
      numComponentPool: Object.keys(this.componentsManager._componentPool).length,
      componentPool: {},
      eventDispatcher: this.eventDispatcher.stats,
    };

    for (ecsyComponentId in this.componentsManager._componentPool) {
      var pool = this.componentsManager._componentPool[ecsyComponentId];
      stats.componentPool[pool.T.getName()] = {
        used: pool.totalUsed(),
        size: pool.count,
      };
    }

    return stats;
  }
}

const ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
const ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
const COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
const COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";