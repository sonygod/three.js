package three.animation;

import three.math.MathUtils;

class AnimationObjectGroup {
    public var isAnimationObjectGroup:Bool = true;
    public var uuid:String = MathUtils.generateUUID();
    private var _objects:Array<Dynamic> = [];
    private var nCachedObjects_:Int = 0;
    private var _indicesByUUID:Map<String, Int> = new Map();
    private var _paths:Array<String> = [];
    private var _parsedPaths:Array<Dynamic> = [];
    private var _bindings:Array<Array<PropertyBinding>> = [];
    private var _bindingsIndicesByPath:Map<String, Int> = new Map();
    public var stats:Dynamic = {
        objects: {
            get_total():Int {
                return _objects.length;
            },
            get_inUse():Int {
                return _objects.length - nCachedObjects_;
            }
        },
        get_bindingsPerObject():Int {
            return _bindings.length;
        }
    };

    public function new() {
        for (arg in Sys.args()) {
            _objects.push(arg);
            _indicesByUUID[arg.uuid] = _objects.length - 1;
        }
    }

    public function add(objects:Array<Dynamic>):Void {
        var objects:Array<Dynamic> = this._objects;
        var indicesByUUID:Map<String, Int> = this._indicesByUUID;
        var paths:Array<String> = this._paths;
        var parsedPaths:Array<Dynamic> = this._parsedPaths;
        var bindings:Array<Array<PropertyBinding>> = this._bindings;
        var nBindings:Int = bindings.length;
        var nObjects:Int = objects.length;
        var nCachedObjects:Int = this.nCachedObjects_;

        for (object in objects) {
            var uuid:String = object.uuid;
            var index:Int = indicesByUUID[uuid];

            if (index == null) {
                index = nObjects++;
                indicesByUUID[uuid] = index;
                objects.push(object);

                for (j in 0...nBindings) {
                    bindings[j].push(new PropertyBinding(object, paths[j], parsedPaths[j]));
                }
            } else if (index < nCachedObjects) {
                // move existing object to the ACTIVE region
                var firstActiveIndex:Int = --nCachedObjects;
                var lastCachedObject:Dynamic = objects[firstActiveIndex];
                indicesByUUID[lastCachedObject.uuid] = index;
                objects[index] = lastCachedObject;

                indicesByUUID[uuid] = firstActiveIndex;
                objects[firstActiveIndex] = object;

                for (j in 0...nBindings) {
                    var bindingsForPath:Array<PropertyBinding> = bindings[j];
                    var lastCached:PropertyBinding = bindingsForPath[firstActiveIndex];
                    var binding:PropertyBinding = bindingsForPath[index];

                    bindingsForPath[index] = lastCached;

                    if (binding == null) {
                        binding = new PropertyBinding(object, paths[j], parsedPaths[j]);
                    }

                    bindingsForPath[firstActiveIndex] = binding;
                }
            } else if (objects[index] != object) {
                trace('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
            }
        }

        this.nCachedObjects_ = nCachedObjects;
    }

    public function remove(objects:Array<Dynamic>):Void {
        var objects:Array<Dynamic> = this._objects;
        var indicesByUUID:Map<String, Int> = this._indicesByUUID;
        var bindings:Array<Array<PropertyBinding>> = this._bindings;
        var nBindings:Int = bindings.length;
        var nCachedObjects:Int = this.nCachedObjects_;

        for (object in objects) {
            var uuid:String = object.uuid;
            var index:Int = indicesByUUID[uuid];

            if (index != null && index >= nCachedObjects) {
                // move existing object into the CACHED region
                var lastCachedIndex:Int = nCachedObjects++;
                var firstActiveObject:Dynamic = objects[lastCachedIndex];

                indicesByUUID[firstActiveObject.uuid] = index;
                objects[index] = firstActiveObject;

                indicesByUUID[uuid] = lastCachedIndex;
                objects[lastCachedIndex] = object;

                for (j in 0...nBindings) {
                    var bindingsForPath:Array<PropertyBinding> = bindings[j];
                    var firstActive:PropertyBinding = bindingsForPath[lastCachedIndex];
                    var binding:PropertyBinding = bindingsForPath[index];

                    bindingsForPath[index] = firstActive;
                    bindingsForPath[lastCachedIndex] = binding;
                }
            }
        }

        this.nCachedObjects_ = nCachedObjects;
    }

    public function uncache(objects:Array<Dynamic>):Void {
        var objects:Array<Dynamic> = this._objects;
        var indicesByUUID:Map<String, Int> = this._indicesByUUID;
        var bindings:Array<Array<PropertyBinding>> = this._bindings;
        var nBindings:Int = bindings.length;
        var nCachedObjects:Int = this.nCachedObjects_;
        var nObjects:Int = objects.length;

        for (object in objects) {
            var uuid:String = object.uuid;
            var index:Int = indicesByUUID[uuid];

            if (index != null) {
                delete indicesByUUID[uuid];

                if (index < nCachedObjects) {
                    // object is cached, shrink the CACHED region
                    var firstActiveIndex:Int = --nCachedObjects;
                    var lastCachedObject:Dynamic = objects[firstActiveIndex];
                    var lastIndex:Int = --nObjects;
                    var lastObject:Dynamic = objects[lastIndex];

                    indicesByUUID[lastCachedObject.uuid] = index;
                    objects[index] = lastCachedObject;

                    indicesByUUID[lastObject.uuid] = firstActiveIndex;
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
                    // object is active, just swap with the last and pop
                    var lastIndex:Int = --nObjects;
                    var lastObject:Dynamic = objects[lastIndex];

                    indicesByUUID[lastObject.uuid] = index;

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

        this.nCachedObjects_ = nCachedObjects;
    }

    public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
        var indicesByPath:Map<String, Int> = this._bindingsIndicesByPath;
        var index:Int = indicesByPath[path];
        var bindings:Array<Array<PropertyBinding>> = this._bindings;

        if (index != null) return bindings[index];

        var paths:Array<String> = this._paths;
        var parsedPaths:Array<Dynamic> = this._parsedPaths;
        var objects:Array<Dynamic> = this._objects;
        var nObjects:Int = objects.length;
        var nCachedObjects:Int = this.nCachedObjects_;
        var bindingsForPath:Array<PropertyBinding> = new Array(nObjects);

        index = bindings.length;

        indicesByPath[path] = index;

        paths.push(path);
        parsedPaths.push(parsedPath);
        bindings.push(bindingsForPath);

        for (i in nCachedObjects...objects.length) {
            var object:Dynamic = objects[i];
            bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);
        }

        return bindingsForPath;
    }

    public function unsubscribe_(path:String):Void {
        var indicesByPath:Map<String, Int> = this._bindingsIndicesByPath;
        var index:Int = indicesByPath[path];

        if (index != null) {
            var paths:Array<String> = this._paths;
            var parsedPaths:Array<Dynamic> = this._parsedPaths;
            var bindings:Array<Array<PropertyBinding>> = this._bindings;
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