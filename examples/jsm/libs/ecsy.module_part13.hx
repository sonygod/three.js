package three.js.examples.jsm.libs;

class System {
  private var _mandatoryQueries:Array<Query>;
  private var queries:Map<String, { results:Array<Entity>, added:Array<Entity>, removed:Array<Entity>, changed:Map<String, Array<Entity>> }>;
  private var world:World;
  public var enabled:Bool;
  public var priority:Int;
  public var executeTime:Float;
  public var initialized:Bool;

  public function new(world:World, attributes:Dynamic) {
    this.world = world;
    this.enabled = true;
    this.priority = 0;
    this.executeTime = 0;
    this.initialized = true;

    _mandatoryQueries = [];
    queries = new Map<String, { results:Array<Entity>, added:Array<Entity>, removed:Array<Entity>, changed:Map<String, Array<Entity>> }>();

    if (attributes != null && attributes.priority != null) {
      this.priority = attributes.priority;
    }

    if (this.constructor.queries != null) {
      for (queryName in this.constructor.queries) {
        var queryConfig = this.constructor.queries[queryName];
        var Components:Array<Class<Component>> = queryConfig.components;
        if (Components == null || Components.length == 0) {
          throw new Error("'components' attribute can't be empty in a query");
        }

        var unregisteredComponents:Array<Class<Component>> = Components.filter(componentRegistered.bind(Component));
        if (unregisteredComponents.length > 0) {
          throw new Error('Tried to create a query \'' + this.constructor.getName() + '.' + queryName + '\' with unregistered components: [' + unregisteredComponents.map(c -> c.getName()).join(", ") + ']');
        }

        var query = world.entityManager.queryComponents(Components);
        _queries.set(queryName, query);
        if (queryConfig.mandatory == true) {
          _mandatoryQueries.push(query);
        }
        queries.set(queryName, { results: query.entities, added: [], removed: [], changed: [] });

        if (queryConfig.listen != null) {
          var validEvents:Array<String> = ["added", "removed", "changed"];

          for (eventName in validEvents) {
            if (queryConfig.listen[eventName] != null) {
              var event = queryConfig.listen[eventName];
              if (eventName == "changed") {
                query.reactive = true;
                if (event == true) {
                  var eventList:Array<Entity> = queries.get(queryName).changed;
                  query.eventDispatcher.addEventListener(Query.COMPONENT_CHANGED, function(entity:Entity) {
                    if (eventList.indexOf(entity) == -1) {
                      eventList.push(entity);
                    }
                  });
                } else if (Std.isOfType(event, Array)) {
                  var eventList:Array<Entity> = queries.get(queryName).changed;
                  query.eventDispatcher.addEventListener(Query.COMPONENT_CHANGED, function(entity:Entity, changedComponent:Component) {
                    if (event.indexOf(changedComponent.constructor) != -1 && eventList.indexOf(entity) == -1) {
                      eventList.push(entity);
                    }
                  });
                }
              } else {
                var eventList:Array<Entity> = queries.get(queryName)[eventName];
                query.eventDispatcher.addEventListener(eventMapping(eventName), function(entity:Entity) {
                  if (eventList.indexOf(entity) == -1) {
                    eventList.push(entity);
                  }
                });
              }
            }
          }
        }
      }
    }
  }

  public function canExecute():Bool {
    return _mandatoryQueries.length == 0 || _mandatoryQueries.every(query -> query.entities.length > 0);
  }

  public function getName():String {
    return Type.getClassName(Type.getClass(this));
  }

  public function stop():Void {
    executeTime = 0;
    enabled = false;
  }

  public function play():Void {
    enabled = true;
  }

  public function clearEvents():Void {
    for (queryName in queries.keys()) {
      var query = queries.get(queryName);
      if (query.added != null) {
        query.added = [];
      }
      if (query.removed != null) {
        query.removed = [];
      }
      if (query.changed != null) {
        if (Std.isOfType(query.changed, Array)) {
          query.changed = [];
        } else {
          for (name in query.changed.keys()) {
            query.changed.set(name, []);
          }
        }
      }
    }
  }

  public function toJSON():Dynamic {
    var json = {
      name: getName(),
      enabled: enabled,
      executeTime: executeTime,
      priority: priority,
      queries: {},
    };

    if (this.constructor.queries != null) {
      for (queryName in this.constructor.queries.keys()) {
        var query = queries.get(queryName);
        var queryDefinition = this.constructor.queries.get(queryName);
        var jsonQuery = json.queries.get(queryName) = {
          key: _queries.get(queryName).key,
        };

        jsonQuery.mandatory = queryDefinition.mandatory == true;
        jsonQuery.reactive = queryDefinition.listen != null && (
          queryDefinition.listen.added == true ||
          queryDefinition.listen.removed == true ||
          queryDefinition.listen.changed == true ||
          Std.isOfType(queryDefinition.listen.changed, Array)
        );

        if (jsonQuery.reactive) {
          jsonQuery.listen = {};

          var methods:Array<String> = ["added", "removed", "changed"];
          for (method in methods) {
            if (query[method] != null) {
              jsonQuery.listen.set(method, { entities: query[method].length });
            }
          }
        }
      }
    }

    return json;
  }
}