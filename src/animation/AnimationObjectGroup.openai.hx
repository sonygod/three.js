package three.animation;

import math.MathUtils;
import haxe.ds.ObjectMap;

class AnimationObjectGroup {
    public var isAnimationObjectGroup:Bool = true;
    public var uuid:String = MathUtils.generateUUID();
    private var _objects:Array<Any> = [];
    private var nCachedObjects_:Int = 0;
    private var _indicesByUUID:ObjectMap<Int> = new ObjectMap();
    private var _paths:Array<String> = [];
    private var _parsedPaths:Array<Dynamic> = [];
    private var _bindings:Array<Array<PropertyBinding>> = [];
    private var _bindingsIndicesByPath:ObjectMap<Int> = new ObjectMap();
    public var stats:{ objects:{ total:Int, inUse:Int }, bindingsPerObject:Int };

    public function new(?objects:Array<Any>) {
        stats = {
            objects: {
                total: 0,
                inUse: 0
            },
            bindingsPerObject: 0
        };
        for (obj in objects) {
            _objects.push(obj);
            _indicesByUUID[obj.uuid] = _objects.length - 1;
        }
    }

    public function add(?objects:Array<Any>) {
        var objects:Array<Any> = _objects;
        var indicesByUUID:ObjectMap<Int> = _indicesByUUID;
        var paths:Array<String> = _paths;
        var parsedPaths:Array<Dynamic> = _parsedPaths;
        var bindings:Array<Array<PropertyBinding>> = _bindings;
        var nBindings:Int = bindings.length;
        var knownObject:Any;
        var nObjects:Int = objects.length;
        var nCachedObjects:Int = nCachedObjects_;

        for (obj in objects) {
            var uuid:String = obj.uuid;
            var index:Int = _indicesByUUID.get(uuid);
            if (index == null) {
                index = nObjects++;
                _indicesByUUID[uuid] = index;
                objects.push(obj);

                for (j in 0...nBindings) {
                    bindings[j].push(new PropertyBinding(obj, paths[j], parsedPaths[j]));
                }
            } else if (index < nCachedObjects) {
                knownObject = objects[index];

                var firstActiveIndex:Int = --nCachedObjects;
                var lastCachedObject:Any = objects[firstActiveIndex];

                _indicesByUUID[lastCachedObject.uuid] = index;
                objects[index] = lastCachedObject;

                _indicesByUUID[uuid] = firstActiveIndex;
                objects[firstActiveIndex] = obj;

                for (j in 0...nBindings) {
                    var bindingsForPath:Array<PropertyBinding> = bindings[j];
                    var lastCached:PropertyBinding = bindingsForPath[firstActiveIndex];
                    var binding:PropertyBinding;

                    bindingsForPath[index] = lastCached;

                    if (binding == null) {
                        binding = new PropertyBinding(obj, paths[j], parsedPaths[j]);
                    }

                    bindingsForPath[firstActiveIndex] = binding;
                }
            } else if (objects[index] != knownObject) {
                trace('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
            }
        }
        nCachedObjects_ = nCachedObjects;
    }

    public function remove(?objects:Array[Any>) {
        var objects:Array<Any> = _objects;
        var indicesByUUID:ObjectMap<Int> = _indicesByUUID;
        var bindings:Array<Array<PropertyBinding>> = _bindings;
        var nBindings:Int = bindings.length;
        var nCachedObjects:Int = nCachedObjects_;

        for (obj in objects) {
            var uuid:String = obj.uuid;
            var index:Int = _indicesByUUID.get(uuid);

            if (index != null && index >= nCachedObjects) {
                var lastCachedIndex:Int = nCachedObjects++;
                var firstActiveObject:Any = objects[lastCachedIndex];

                _indicesByUUID[firstActiveObject.uuid] = index;
                objects[index] = firstActiveObject;

                _indicesByUUID[uuid] = lastCachedIndex;
                objects[lastCachedIndex] = obj;

                for (j in 0...nBindings) {
                    var bindingsForPath:Array<PropertyBinding> = bindings[j];
                    var firstActive:PropertyBinding = bindingsForPath[lastCachedIndex];
                    var binding:PropertyBinding = bindingsForPath[index];

                    bindingsForPath[index] = firstActive;
                    bindingsForPath[lastCachedIndex] = binding;
                }
            }
        }
        nCachedObjects_ = nCachedObjects;
    }

    public function uncache(?objects:Array<Any>) {
        var objects:Array<Any> = _objects;
        var indicesByUUID:ObjectMap<Int> = _indicesByUUID;
        var bindings:Array<Array<PropertyBinding>> = _bindings;
        var nBindings:Int = bindings.length;
        var nCachedObjects:Int = nCachedObjects_;
        var nObjects:Int = objects.length;

        for (obj in objects) {
            var uuid:String = obj.uuid;
            var index:Int = _indicesByUUID.get(uuid);

            if (index != null) {
                delete _indicesByUUID[uuid];

                if (index < nCachedObjects) {
                    var firstActiveIndex:Int = --nCachedObjects;
                    var lastCachedObject:Any = objects[firstActiveIndex];
                    var lastIndex:Int = --nObjects;
                    var lastObject:Any = objects[lastIndex];

                    _indicesByUUID[lastCachedObject.uuid] = index;
                    objects[index] = lastCachedObject;

                    _indicesByUUID[lastObject.uuid] = firstActiveIndex;
                    objects[firstActiveIndex] = lastObject;
                    objects.pop();

                    for (j in 0...nBindings) {
                        var bindingsForPath:Array<PropertyBinding> = bindings[j];
                        var lastCached:PropertyBinding = bindingsForPath[firstActiveIndex];
                        var last:PropertyBinding = bindingsForPath[lastIndex];

                        bindingsForPath[index] = lastCached;
                        bindingsForPath[firstActiveIndex] = last;
                        bindingsForPath.pop();
                    }
                } else {
                    var lastIndex:Int = --nObjects;
                    var lastObject:Any = objects[lastIndex];

                    if (lastIndex > 0) {
                        _indicesByUUID[lastObject.uuid] = index;
                    }

                    objects[index] = lastObject;
                    objects.pop();

                    for (j in 0...nBindings) {
                        var bindingsForPath:Array<PropertyBinding> = bindings[j];

                        bindingsForPath[index] = bindingsForPath[lastIndex];
                        bindingsForPath.pop();
                    }
                }
            }
        }
        nCachedObjects_ = nCachedObjects;
    }

    public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
        var indicesByPath:ObjectMap<Int> = _bindingsIndicesByPath;
        var index:Int = indicesByPath.get(path);
        var bindings:Array<Array<PropertyBinding>> = _bindings;

        if (index != null) return bindings[index];

        var paths:Array<String> = _paths;
        var parsedPaths:Array<Dynamic> = _parsedPaths;
        var objects:Array<Any> = _objects;
        var nObjects:Int = objects.length;
        var nCachedObjects:Int = nCachedObjects_;
        var bindingsForPath:Array<PropertyBinding> = new Array(nObjects);

        index = bindings.length;

        indicesByPath[path] = index;

        paths.push(path);
        parsedPaths.push(parsedPath);
        bindings.push(bindingsForPath);

        for (i in nCachedObjects...nObjects) {
            var obj:Any = objects[i];
            bindingsForPath[i] = new PropertyBinding(obj, path, parsedPath);
        }

        return bindingsForPath;
    }

    public function unsubscribe_(path:String) {
        var indicesByPath:ObjectMap<Int> = _bindingsIndicesByPath;
        var index:Int = indicesByPath.get(path);

        if (index != null) {
            var paths:Array<String> = _paths;
            var parsedPaths:Array<Dynamic> = _parsedPaths;
            var bindings:Array<Array<PropertyBinding>> = _bindings;
            var lastBindingsIndex:Int = bindings.length - 1;
            var lastBindings:Array<PropertyBinding> = bindings[lastBindingsIndex];
            var lastBindingsPath:String = paths[lastBindingsIndex];

            indicesByPath[lastBindingsPath] = index;

            bindings[index] = lastBindings;
            bindings.pop();

            parsedPaths[index] = parsedPaths[lastBindingsIndex];
            parsedPaths.pop();

            paths[index] = paths[lastBindingsIndex];
            paths.pop();
        }
    }
}