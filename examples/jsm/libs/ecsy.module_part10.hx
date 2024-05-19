package three.js.examples.javascript.modules.ecsy;

import haxe.ds.ObjectMap;

class ComponentManager {
    private var components:Array<Class<Dynamic>>;
    private var componentsMap:ObjectMap<Int, Class<Dynamic>>;
    private var componentPool:ObjectMap<Int, ObjectPool>;
    private var numComponents:ObjectMap<Int, Int>;
    private var nextComponentId:Int;

    public function new() {
        components = [];
        componentsMap = new ObjectMap();
        componentPool = new ObjectMap();
        numComponents = new ObjectMap();
        nextComponentId = 0;
    }

    public function hasComponent(component:Class<Dynamic>):Bool {
        return components.indexOf(component) != -1;
    }

    public function registerComponent(component:Class<Dynamic>, objectPool:ObjectPool = null):Void {
        if (components.indexOf(component) != -1) {
            trace("Component type: '" + component.getName() + "' already registered.");
            return;
        }

        var schema:Dynamic = component.schema;

        if (schema == null) {
            throw new Error("Component \"" + component.getName() + "\" has no schema property.");
        }

        for (fieldName in Reflect.fields(schema)) {
            var prop:Dynamic = Reflect.field(schema, fieldName);

            if (prop.type == null) {
                throw new Error("Invalid schema for component \"" + component.getName() + "\". Missing type for \"" + fieldName + "\" property.");
            }
        }

        component._typeId = nextComponentId++;
        components.push(component);
        componentsMap.set(component._typeId, component);
        numComponents.set(component._typeId, 0);

        if (objectPool == null) {
            objectPool = new ObjectPool(component);
        } else if (objectPool == false) {
            objectPool = null;
        }

        componentPool.set(component._typeId, objectPool);
    }

    public function componentAddedToEntity(component:Class<Dynamic>):Void {
        numComponents.set(component._typeId, numComponents.get(component._typeId) + 1);
    }

    public function componentRemovedFromEntity(component:Class<Dynamic>):Void {
        numComponents.set(component._typeId, numComponents.get(component._typeId) - 1);
    }

    public function getComponentsPool(component:Class<Dynamic>):ObjectPool {
        return componentPool.get(component._typeId);
    }
}