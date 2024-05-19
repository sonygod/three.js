package three.js.examples.jsm.libs;

import ecs.QueryManager;
import ecs.EventDispatcher;
import ecs.EntityPool;
import ecs.Component;

class EntityManager {
  public var world:Dynamic;
  public var componentsManager:Dynamic;
  public var _entities:Array<Dynamic>;
  public var _nextEntityId:Int;
  public var _entitiesByNames:Map<String, Dynamic>;
  public var _queryManager:QueryManager;
  public var eventDispatcher:EventDispatcher;
  public var _entityPool:EntityPool;
  public var entitiesWithComponentsToRemove:Array<Dynamic>;
  public var entitiesToRemove:Array<Dynamic>;
  public var deferredRemovalEnabled:Bool;

  public function new(world:Dynamic) {
    this.world = world;
    this.componentsManager = world.componentsManager;

    this._entities = [];
    this._nextEntityId = 0;

    this._entitiesByNames = new Map<String, Dynamic>();

    this._queryManager = new QueryManager(this);
    this.eventDispatcher = new EventDispatcher();
    this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);

    this.entitiesWithComponentsToRemove = [];
    this.entitiesToRemove = [];
    this.deferredRemovalEnabled = true;
  }

  public function getEntityByName(name:String):Dynamic {
    return _entitiesByNames[name];
  }

  /**
   * Create a new entity
   */
  public function createEntity(name:String):Dynamic {
    var entity:Dynamic = _entityPool.acquire();
    entity.alive = true;
    entity.name = name != null ? name : "";
    if (name != null) {
      if (_entitiesByNames.exists(name)) {
        Console.warn("Entity name '$name' already exist");
      } else {
        _entitiesByNames[name] = entity;
      }
    }

    _entities.push(entity);
    eventDispatcher.dispatchEvent(ENTITY_CREATED, entity);
    return entity;
  }

  // COMPONENTS

  /**
   * Add a component to an entity
   * @param entity Entity where the component will be added
   * @param Component Component to be added to the entity
   * @param values Optional values to replace the default attributes
   */
  public function entityAddComponent(entity:Dynamic, Component:Class<Dynamic>, ?values:Dynamic):Void {
    if (Component._typeId == null && !world.componentsManager._ComponentsMap.exists(Component._typeId)) {
      throw new Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
    }

    if (~entity._ComponentTypes.indexOf(Component)) {
      Console.warn("Component type already exists on entity.", entity, Component.getName());
      return;
    }

    entity._ComponentTypes.push(Component);

    if (Component.prototype == SystemStateComponent) {
      entity.numStateComponents++;
    }

    var componentPool:ComponentPool = world.componentsManager.getComponentsPool(Component);

    var component:Dynamic = componentPool != null ? componentPool.acquire() : new Component(values);

    if (componentPool != null && values != null) {
      component.copy(values);
    }

    entity._components[Component._typeId] = component;

    _queryManager.onEntityComponentAdded(entity, Component);
    world.componentsManager.componentAddedToEntity(Component);

    eventDispatcher.dispatchEvent(COMPONENT_ADDED, entity, Component);
  }

  /**
   * Remove a component from an entity
   * @param entity Entity which will get removed the component
   * @param Component Component to remove from the entity
   * @param immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  public function entityRemoveComponent(entity:Dynamic, Component:Class<Dynamic>, immediately:Bool):Void {
    var index:Int = entity._ComponentTypes.indexOf(Component);
    if (index == -1) return;

    eventDispatcher.dispatchEvent(COMPONENT_REMOVE, entity, Component);

    if (immediately) {
      _entityRemoveComponentSync(entity, Component, index);
    } else {
      if (entity._ComponentTypesToRemove.length == 0) {
        entitiesWithComponentsToRemove.push(entity);
      }

      entity._ComponentTypes.splice(index, 1);
      entity._ComponentTypesToRemove.push(Component);

      entity._componentsToRemove[Component._typeId] = entity._components[Component._typeId];
      delete entity._components[Component._typeId];
    }

    _queryManager.onEntityComponentRemoved(entity, Component);

    if (Component.prototype == SystemStateComponent) {
      entity.numStateComponents--;

      if (entity.numStateComponents == 0 && !entity.alive) {
        entity.remove();
      }
    }
  }

  private function _entityRemoveComponentSync(entity:Dynamic, Component:Class<Dynamic>, index:Int):Void {
    entity._ComponentTypes.splice(index, 1);
    var component:Dynamic = entity._components[Component._typeId];
    delete entity._components[Component._typeId];
    component.dispose();
    world.componentsManager.componentRemovedFromEntity(Component);
  }

  /**
   * Remove all the components from an entity
   * @param entity Entity from which the components will be removed
   */
  public function entityRemoveAllComponents(entity:Dynamic, immediately:Bool):Void {
    var Components:Array<Class<Dynamic>> = entity._ComponentTypes;

    for (i in Components.length - 1...0) {
      if (Components[i].prototype != SystemStateComponent) {
        entityRemoveComponent(entity, Components[i], immediately);
      }
    }
  }

  /**
   * Remove the entity from this manager. It will clear also its components
   * @param entity Entity to remove from the manager
   * @param immediately If you want to remove the component immediately instead of deferred (Default is false)
   */
  public function removeEntity(entity:Dynamic, immediately:Bool):Void {
    var index:Int = _entities.indexOf(entity);

    if (index == -1) throw new Error("Tried to remove entity not in list");

    entity.alive = false;
    entityRemoveAllComponents(entity, immediately);

    if (entity.numStateComponents == 0) {
      eventDispatcher.dispatchEvent(ENTITY_REMOVED, entity);
      _queryManager.onEntityRemoved(entity);
      if (immediately) {
        _releaseEntity(entity, index);
      } else {
        entitiesToRemove.push(entity);
      }
    }
  }

  private function _releaseEntity(entity:Dynamic, index:Int):Void {
    _entities.splice(index, 1);

    if (_entitiesByNames.exists(entity.name)) {
      _entitiesByNames.remove(entity.name);
    }
    entity._pool.release(entity);
  }

  /**
   * Remove all entities from this manager
   */
  public function removeAllEntities():Void {
    for (i in _entities.length - 1...0) {
      removeEntity(_entities[i]);
    }
  }

  public function processDeferredRemoval():Void {
    if (!deferredRemovalEnabled) {
      return;
    }

    for (i in entitiesToRemove.length - 1...0) {
      var entity:Dynamic = entitiesToRemove[i];
      var index:Int = _entities.indexOf(entity);
      _releaseEntity(entity, index);
    }
    entitiesToRemove.length = 0;

    for (i in entitiesWithComponentsToRemove.length - 1...0) {
      var entity:Dynamic = entitiesWithComponentsToRemove[i];
      while (entity._ComponentTypesToRemove.length > 0) {
        var Component:Class<Dynamic> = entity._ComponentTypesToRemove.pop();

        var component:Dynamic = entity._componentsToRemove[Component._typeId];
        delete entity._componentsToRemove[Component._typeId];
        component.dispose();
        world.componentsManager.componentRemovedFromEntity(Component);
      }
    }

    entitiesWithComponentsToRemove.length = 0;
  }

  /**
   * Get a query based on a list of components
   * @param Components List of components that will form the query
   */
  public function queryComponents(Components:Array<Class<Dynamic>>):Query {
    return _queryManager.getQuery(Components);
  }

  // EXTRAS

  /**
   * Return number of entities
   */
  public function count():Int {
    return _entities.length;
  }

  /**
   * Return some stats
   */
  public function stats():Dynamic {
    var stats:Dynamic = {
      numEntities: _entities.length,
      numQueries: Lambda.count(_queryManager._queries),
      queries: _queryManager.stats(),
      numComponentPool: Lambda.count(world.componentsManager._componentPool),
      componentPool: {},
      eventDispatcher: eventDispatcher.stats,
    };

    for (ecsyComponentId in world.componentsManager._componentPool.keys()) {
      var pool:ComponentPool = world.componentsManager._componentPool[ecsyComponentId];
      stats.componentPool[pool.T.getName()] = {
        used: pool.totalUsed(),
        size: pool.count,
      };
    }

    return stats;
  }
}