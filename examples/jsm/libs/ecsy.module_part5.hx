package three.js.examples.jm.libs;

class QueryManager {
  private var _world:World;
  private var _queries:Map<String, Query>;

  public function new(world:World) {
    _world = world;
    _queries = new Map<String, Query>();
  }

  public function onEntityRemoved(entity:Entity) {
    for (queryName in _queries.keys()) {
      var query = _queries.get(queryName);
      if (entity.queries.indexOf(query) != -1) {
        query.removeEntity(entity);
      }
    }
  }

  /**
   * Callback when a component is added to an entity
   * @param entity Entity that just got the new component
   * @param component Component added to the entity
   */
  public function onEntityComponentAdded(entity:Entity, component:Component) {
    // @todo Use bitmask for checking components?

    // Check each indexed query to see if we need to add this entity to the list
    for (queryName in _queries.keys()) {
      var query = _queries.get(queryName);

      if (
        query.NotComponents.indexOf(component) != -1 &&
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
        query.Components.indexOf(component) == -1 ||
        !query.match(entity) ||
        query.entities.indexOf(entity) != -1
      )
        continue;

      query.addEntity(entity);
    }
  }

  /**
   * Callback when a component is removed from an entity
   * @param entity Entity to remove the component from
   * @param component Component to remove from the entity
   */
  public function onEntityComponentRemoved(entity:Entity, component:Component) {
    for (queryName in _queries.keys()) {
      var query = _queries.get(queryName);

      if (
        query.NotComponents.indexOf(component) != -1 &&
        query.entities.indexOf(entity) == -1 &&
        query.match(entity)
      ) {
        query.addEntity(entity);
        continue;
      }

      if (
        query.Components.indexOf(component) != -1 &&
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
   * @param components Components that the query should have
   */
  public function getQuery(components:Array<Component>) {
    var key = queryKey(components);
    var query = _queries.get(key);
    if (query == null) {
      _queries.set(key, query = new Query(components, _world));
    }
    return query;
  }

  /**
   * Return some stats from this class
   */
  public function stats() {
    var stats = new Map<String, Dynamic>();
    for (queryName in _queries.keys()) {
      stats.set(queryName, _queries.get(queryName).stats());
    }
    return stats;
  }
}