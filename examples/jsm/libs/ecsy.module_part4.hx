package three.js.examples.jsm.libs;

import haxe.ds.ArraySort;
import ecs.Entity;

class Query {
  public var Components:Array<ComponentClass>;
  public var NotComponents:Array<ComponentClass>;
  public var entities:Array<Entity>;
  public var eventDispatcher:EventDispatcher;

  public function new(Components:Array<ComponentClass>, manager:EntityManager) {
    this.Components = [];
    this.NotComponents = [];

    for (component in Components) {
      if (Std.isOfType(component, ComponentClass)) {
        this.NotComponents.push(cast component);
      } else {
        this.Components.push(component);
      }
    }

    if (this.Components.length == 0) {
      throw new Error("Can't create a query without components");
    }

    this.entities = new Array();

    this.eventDispatcher = new EventDispatcher();

    // This query is being used by a reactive system
    this.reactive = false;

    this.key = queryKey(Components);

    // Fill the query with the existing entities
    for (entity in manager.entities) {
      if (this.match(entity)) {
        // @todo ??? this.addEntity(entity); => preventing the event to be generated
        entity.queries.push(this);
        this.entities.push(entity);
      }
    }
  }

  public function addEntity(entity:Entity) {
    entity.queries.push(this);
    this.entities.push(entity);

    this.eventDispatcher.dispatchEvent(ENTITY_ADDED, entity);
  }

  public function removeEntity(entity:Entity) {
    var index = Lambda.indexOf(this.entities, entity);
    if (index != -1) {
      this.entities.splice(index, 1);

      index = Lambda.indexOf(entity.queries, this);
      entity.queries.splice(index, 1);

      this.eventDispatcher.dispatchEvent(ENTITY_REMOVED, entity);
    }
  }

  public function match(entity:Entity) {
    return entity.hasAllComponents(this.Components) && !entity.hasAnyComponents(this.NotComponents);
  }

  public function toJSON() {
    return {
      key: this.key,
      reactive: this.reactive,
      components: {
        included: [for (C in this.Components) C.name],
        not: [for (C in this.NotComponents) C.name],
      },
      numEntities: this.entities.length,
    };
  }

  public function stats() {
    return {
      numComponents: this.Components.length,
      numEntities: this.entities.length,
    };
  }

  static public var ENTITY_ADDED:String = "entityAdded";
  static public var ENTITY_REMOVED:String = "entityRemoved";
}