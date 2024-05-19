package three.js.examples.jsm.libs;

class Entity {
    public var _entityManager:EntityManager;
    public var id:Int;
    public var _ComponentTypes:Array<Class<Dynamic>>;
    public var _components:Map<String, Dynamic>;
    public var _componentsToRemove:Map<String, Dynamic>;
    public var queries:Array<Query>;
    public var _ComponentTypesToRemove:Array<Class<Dynamic>>;
    public var alive:Bool;
    public var numStateComponents:Int;

    public function new(entityManager:EntityManager) {
        _entityManager = entityManager;
        id = _entityManager._nextEntityId++;
        _ComponentTypes = new Array();
        _components = new Map();
        _componentsToRemove = new Map();
        queries = new Array();
        _ComponentTypesToRemove = new Array();
        alive = false;
        numStateComponents = 0;
    }

    // COMPONENTS

    public function getComponent(Component:Class<Dynamic>, includeRemoved:Bool = false):Dynamic {
        var component:Dynamic = _components.get(Type.getClassName(Component));
        if (!component && includeRemoved) {
            component = _componentsToRemove.get(Type.getClassName(Component));
        }
        return wrapImmutableComponent(Component, component);
    }

    public function getRemovedComponent(Component:Class<Dynamic>):Dynamic {
        var component:Dynamic = _componentsToRemove.get(Type.getClassName(Component));
        return wrapImmutableComponent(Component, component);
    }

    public function getComponents():Map<String, Dynamic> {
        return _components;
    }

    public function getComponentsToRemove():Map<String, Dynamic> {
        return _componentsToRemove;
    }

    public function getComponentTypes():Array<Class<Dynamic>> {
        return _ComponentTypes;
    }

    public function getMutableComponent(Component:Class<Dynamic>):Dynamic {
        var component:Dynamic = _components.get(Type.getClassName(Component));
        if (component == null) return null;
        for (query in queries) {
            if (query.reactive && Lambda.has(query.Components, Component)) {
                query.eventDispatcher.dispatchEvent(Query.COMPONENT_CHANGED, this, component);
            }
        }
        return component;
    }

    public function addComponent(Component:Class<Dynamic>, values:Dynamic):Entity {
        _entityManager.entityAddComponent(this, Component, values);
        return this;
    }

    public function removeComponent(Component:Class<Dynamic>, forceImmediate:Bool = false):Entity {
        _entityManager.entityRemoveComponent(this, Component, forceImmediate);
        return this;
    }

    public function hasComponent(Component:Class<Dynamic>, includeRemoved:Bool = false):Bool {
        return (_ComponentTypes.indexOf(Component) != -1) || (includeRemoved && hasRemovedComponent(Component));
    }

    public function hasRemovedComponent(Component:Class<Dynamic>):Bool {
        return _ComponentTypesToRemove.indexOf(Component) != -1;
    }

    public function hasAllComponents(Components:Array<Class<Dynamic>>):Bool {
        for (Component in Components) {
            if (!hasComponent(Component)) return false;
        }
        return true;
    }

    public function hasAnyComponents(Components:Array<Class<Dynamic>>):Bool {
        for (Component in Components) {
            if (hasComponent(Component)) return true;
        }
        return false;
    }

    public function removeAllComponents(forceImmediate:Bool = false):Entity {
        return _entityManager.entityRemoveAllComponents(this, forceImmediate);
    }

    public function copy(src:Entity):Entity {
        for (ecsyComponentId in src._components.keys()) {
            var srcComponent:Dynamic = src._components.get(ecsyComponentId);
            addComponent(Type.getClass(srcComponent));
            var component:Dynamic = getComponent(Type.getClass(srcComponent));
            component.copy(srcComponent);
        }
        return this;
    }

    public function clone():Entity {
        return new Entity(_entityManager).copy(this);
    }

    public function reset():Void {
        id = _entityManager._nextEntityId++;
        _ComponentTypes.splice(0, _ComponentTypes.length);
        queries.splice(0, queries.length);
        for (ecsyComponentId in _components.keys()) {
            _components.remove(ecsyComponentId);
        }
    }

    public function remove(forceImmediate:Bool = false):Entity {
        return _entityManager.removeEntity(this, forceImmediate);
    }
}