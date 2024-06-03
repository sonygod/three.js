import js.html.HTMLDivElement;

class Component {
    public var _pool:ObjectPool;

    public function new(props:Dynamic = null) {
        if (props !== false) {
            var schema = this.getClass().schema;

            for (key in schema) {
                if (props && props.hasOwnProperty(key)) {
                    Reflect.setField(this, key, Reflect.field(props, key));
                } else {
                    var schemaProp = Reflect.field(schema, key);
                    if (schemaProp.hasOwnProperty("default")) {
                        Reflect.setField(this, key, schemaProp.type.clone(schemaProp.default));
                    } else {
                        var type = schemaProp.type;
                        Reflect.setField(this, key, type.clone(type.default));
                    }
                }
            }

            if (props !== null) {
                this.checkUndefinedAttributes(props);
            }
        }

        this._pool = null;
    }

    public function copy(source:Component):Component {
        var schema = this.getClass().schema;

        for (key in schema) {
            var prop = Reflect.field(schema, key);

            if (source.hasOwnProperty(key)) {
                Reflect.setField(this, key, prop.type.copy(Reflect.field(source, key), Reflect.field(this, key)));
            }
        }

        // @DEBUG
        {
            this.checkUndefinedAttributes(source);
        }

        return this;
    }

    public function clone():Component {
        return new this.getClass().constructor().copy(this);
    }

    public function reset():Void {
        var schema = this.getClass().schema;

        for (key in schema) {
            var schemaProp = Reflect.field(schema, key);

            if (schemaProp.hasOwnProperty("default")) {
                Reflect.setField(this, key, schemaProp.type.copy(schemaProp.default, Reflect.field(this, key)));
            } else {
                var type = schemaProp.type;
                Reflect.setField(this, key, type.copy(type.default, Reflect.field(this, key)));
            }
        }
    }

    public function dispose():Void {
        if (this._pool != null) {
            this._pool.release(this);
        }
    }

    public function getName():String {
        return this.getClass().getName();
    }

    public function checkUndefinedAttributes(src:Dynamic):Void {
        var schema = this.getClass().schema;

        // Check that the attributes defined in source are also defined in the schema
        for (srcKey in src) {
            if (!schema.hasOwnProperty(srcKey)) {
                trace("Trying to set attribute '" + srcKey + "' not defined in the '" + this.getClass().name + "' schema. Please fix the schema, the attribute value won't be set");
            }
        }
    }
}

class SystemStateComponent extends Component {
    public static var isSystemStateComponent:Bool = true;
}

class ObjectPool {
    public var freeList:Array<Dynamic>;
    public var count:Int;
    public var T:Class<Dynamic>;
    public var isObjectPool:Bool;

    public function new(T:Class<Dynamic>, initialSize:Int) {
        this.freeList = [];
        this.count = 0;
        this.T = T;
        this.isObjectPool = true;

        if (initialSize != null) {
            this.expand(initialSize);
        }
    }

    public function acquire():Dynamic {
        // Grow the list by 20%ish if we're out
        if (this.freeList.length <= 0) {
            this.expand(Math.round(this.count * 0.2) + 1);
        }

        var item = this.freeList.pop();

        return item;
    }

    public function release(item:Dynamic):Void {
        item.reset();
        this.freeList.push(item);
    }

    public function expand(count:Int):Void {
        for (var n:Int = 0; n < count; n++) {
            var clone = Type.createInstance(this.T, []);
            Reflect.setField(clone, "_pool", this);
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

class EntityPool extends ObjectPool {
    public var entityManager:EntityManager;

    public function new(entityManager:EntityManager, entityClass:Class<Dynamic>, initialSize:Int) {
        super(entityClass, null);
        this.entityManager = entityManager;

        if (initialSize != null) {
            this.expand(initialSize);
        }
    }

    @override
    public function expand(count:Int):Void {
        for (var n:Int = 0; n < count; n++) {
            var clone = Type.createInstance(this.T, [this.entityManager]);
            Reflect.setField(clone, "_pool", this);
            this.freeList.push(clone);
        }
        this.count += count;
    }
}

class EntityManager {
    public var world:World;
    public var componentsManager:ComponentManager;
    public var _entities:Array<Entity>;
    public var _nextEntityId:Int;
    public var _entitiesByNames:haxe.ds.StringMap<Entity>;
    public var _queryManager:QueryManager;
    public var eventDispatcher:EventDispatcher;
    public var _entityPool:EntityPool;
    public var entitiesWithComponentsToRemove:Array<Entity>;
    public var entitiesToRemove:Array<Entity>;
    public var deferredRemovalEnabled:Bool;

    public function new(world:World) {
        this.world = world;
        this.componentsManager = world.componentsManager;

        // All the entities in this instance
        this._entities = [];
        this._nextEntityId = 0;

        this._entitiesByNames = new haxe.ds.StringMap();

        this._queryManager = new QueryManager(this);
        this.eventDispatcher = new EventDispatcher();
        this._entityPool = new EntityPool(this, world.options.entityClass, world.options.entityPoolSize);

        // Deferred deletion
        this.entitiesWithComponentsToRemove = [];
        this.entitiesToRemove = [];
        this.deferredRemovalEnabled = true;
    }

    public function getEntityByName(name:String):Entity {
        return this._entitiesByNames.get(name);
    }

    public function createEntity(name:String = null):Entity {
        var entity = this._entityPool.acquire();
        entity.alive = true;
        entity.name = name != null ? name : "";
        if (name != null) {
            if (this._entitiesByNames.exists(name)) {
                trace("Entity name '" + name + "' already exist");
            } else {
                this._entitiesByNames.set(name, entity);
            }
        }

        this._entities.push(entity);
        this.eventDispatcher.dispatchEvent(ENTITY_CREATED, entity);
        return entity;
    }

    // COMPONENTS

    public function entityAddComponent(entity:Entity, Component:Class<Dynamic>, values:Dynamic):Void {
        // @todo Probably define Component._typeId with a default value and avoid using typeof
        if (Component._typeId == null && !this.world.componentsManager._ComponentsMap.exists(Component._typeId)) {
            throw new js.Error("Attempted to add unregistered component \"" + Component.getName() + "\"");
        }

        if (~entity._ComponentTypes.indexOf(Component)) {
            {
                trace("Component type already exists on entity.", entity, Component.getName());
            }
            return;
        }

        entity._ComponentTypes.push(Component);

        if (Component.isSystemStateComponent) {
            entity.numStateComponents++;
        }

        var componentPool = this.world.componentsManager.getComponentsPool(Component);

        var component = componentPool != null ? componentPool.acquire() : Type.createInstance(Component, [values]);

        if (componentPool != null && values != null) {
            component.copy(values);
        }

        entity._components[Component._typeId] = component;

        this._queryManager.onEntityComponentAdded(entity, Component);
        this.world.componentsManager.componentAddedToEntity(Component);

        this.eventDispatcher.dispatchEvent(COMPONENT_ADDED, entity, Component);
    }

    // Other methods...
}

// Other classes...

class World {
    public var options:Dynamic;
    public var componentsManager:ComponentManager;
    public var entityManager:EntityManager;
    public var systemManager:SystemManager;
    public var enabled:Bool;
    public var eventQueues:haxe.ds.StringMap<Dynamic>;
    public var lastTime:Float;

    public function new(options:Dynamic = null) {
        this.options = js.Boot.dynamicField(options, {});

        this.componentsManager = new ComponentManager();
        this.entityManager = new EntityManager(this);
        this.systemManager = new SystemManager(this);

        this.enabled = true;

        this.eventQueues = new haxe.ds.StringMap();

        if (hasWindow && js.Browser.document != null) {
            var event = new js.html.CustomEvent(new js.html.Event("ecsy-world-created", null, null), { detail: { world: this, version: Version } });
            js.Browser.document.dispatchEvent(event);
        }

        this.lastTime = now() / 1000;
    }

    public function registerComponent(Component:Class<Dynamic>, objectPool:ObjectPool = null):World {
        this.componentsManager.registerComponent(Component, objectPool);
        return this;
    }

    // Other methods...
}

class System {
    public var world:World;
    public var enabled:Bool;
    public var _queries:haxe.ds.StringMap<Query>;
    public var queries:haxe.ds.StringMap<Dynamic>;
    public var priority:Int;
    public var executeTime:Float;
    public var initialized:Bool;
    public var _mandatoryQueries:Array<Query>;

    public function new(world:World, attributes:Dynamic) {
        this.world = world;
        this.enabled = true;

        this._queries = new haxe.ds.StringMap();
        this.queries = new haxe.ds.StringMap();

        this.priority = 0;

        // Used for stats
        this.executeTime = 0;

        if (attributes != null && attributes.hasOwnProperty("priority")) {
            this.priority = attributes.priority;
        }

        this._mandatoryQueries = [];

        this.initialized = true;

        if (this.getClass().queries != null) {
            for (queryName in this.getClass().queries) {
                var queryConfig = Reflect.field(this.getClass().queries, queryName);
                var Components = queryConfig.components;
                if (Components == null || Components.length == 0) {
                    throw new js.Error("'components' attribute can't be empty in a query");
                }

                // Detect if the components have already been registered
                var unregisteredComponents = Components.filter((Component) => !componentRegistered(Component));

                if (unregisteredComponents.length > 0) {
                    throw new js.Error("Tried to create a query '" + this.getClass().name + "." + queryName + "' with unregistered components: [" + unregisteredComponents.map((c) => c.getName()).join(", ") + "]");
                }

                var query = this.world.entityManager.queryComponents(Components);

                this._queries.set(queryName, query);
                if (queryConfig.mandatory == true) {
                    this._mandatoryQueries.push(query);
                }
                this.queries.set(queryName, { results: query.entities });

                // Reactive configuration added/removed/changed
                var validEvents = ["added", "removed", "changed"];

                const eventMapping = {
                    "added": Query.prototype.ENTITY_ADDED,
                    "removed": Query.prototype.ENTITY_REMOVED,
                    "changed": Query.prototype.COMPONENT_CHANGED
                };

                if (queryConfig.listen != null) {
                    validEvents.forEach((eventName) => {
                        if (this.execute == null) {
                            trace("System '" + this.getName() + "' has defined listen events (" + validEvents.join(", ") + ") for query '" + queryName + "' but it does not implement the 'execute' method.");
                        }

                        // Is the event enabled on this system's query?
                        if (queryConfig.listen.hasOwnProperty(eventName)) {
                            var event = Reflect.field(queryConfig.listen, eventName);

                            if (eventName == "changed") {
                                query.reactive = true;
                                if (event == true) {
                                    // Any change on the entity from the components in the query
                                    var eventList = this.queries.get(queryName)[eventName] = [];
                                    query.eventDispatcher.addEventListener(Query.prototype.COMPONENT_CHANGED, (entity) => {
                                        // Avoid duplicates
                                        if (eventList.indexOf(entity) == -1) {
                                            eventList.push(entity);
                                        }
                                    });
                                } else if (js.Boot.isArray(event)) {
                                    var eventList = this.queries.get(queryName)[eventName] = [];
                                    query.eventDispatcher.addEventListener(Query.prototype.COMPONENT_CHANGED, (entity, changedComponent) => {
                                        // Avoid duplicates
                                        if (event.indexOf(changedComponent.getClass()) != -1 && eventList.indexOf(entity) == -1) {
                                            eventList.push(entity);
                                        }
                                    });
                                }
                            } else {
                                var eventList = this.queries.get(queryName)[eventName] = [];

                                query.eventDispatcher.addEventListener(Reflect.field(eventMapping, eventName), (entity) => {
                                    // @fixme overhead?
                                    if (eventList.indexOf(entity) == -1)
                                        eventList.push(entity);
                                });
                            }
                        }
                    });
                }
            }
        }
    }

    // Other methods...
}

// Other functions...