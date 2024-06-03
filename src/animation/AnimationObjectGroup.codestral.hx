import js.Browser;
import three.animation.PropertyBinding;
import three.math.MathUtils;

class AnimationObjectGroup {
    public var isAnimationObjectGroup:Bool = true;
    public var uuid:String = MathUtils.generateUUID();
    private var _objects:Array<Dynamic>;
    private var nCachedObjects_:Int = 0;
    private var _indicesByUUID:Object;
    private var _paths:Array<String>;
    private var _parsedPaths:Array<Dynamic>;
    private var _bindings:Array<Array<PropertyBinding>>;
    private var _bindingsIndicesByPath:haxe.ds.StringMap;
    public var stats:Dynamic;

    public function new(...args) {
        _objects = args;
        _indicesByUUID = {};
        for (i in 0...args.length) {
            _indicesByUUID[args[i].uuid] = i;
        }

        _paths = [];
        _parsedPaths = [];
        _bindings = [];
        _bindingsIndicesByPath = new haxe.ds.StringMap();

        var scope = this;
        stats = {
            objects: {
                get total():Int {
                    return scope._objects.length;
                },
                get inUse():Int {
                    return this.total - scope.nCachedObjects_;
                }
            },
            get bindingsPerObject():Int {
                return scope._bindings.length;
            }
        };
    }

    public function add(...args) {
        var nObjects = _objects.length;
        var nCachedObjects = nCachedObjects_;
        var nBindings = _bindings.length;

        for (i in 0...args.length) {
            var object = args[i];
            var uuid = object.uuid;
            var index = _indicesByUUID[uuid];

            if (index == null) {
                index = nObjects++;
                _indicesByUUID[uuid] = index;
                _objects.push(object);

                for (j in 0...nBindings) {
                    _bindings[j].push(new PropertyBinding(object, _paths[j], _parsedPaths[j]));
                }
            } else if (index < nCachedObjects) {
                var firstActiveIndex = --nCachedObjects;
                var lastCachedObject = _objects[firstActiveIndex];

                _indicesByUUID[lastCachedObject.uuid] = index;
                _objects[index] = lastCachedObject;

                _indicesByUUID[uuid] = firstActiveIndex;
                _objects[firstActiveIndex] = object;

                for (j in 0...nBindings) {
                    var bindingsForPath = _bindings[j];
                    var lastCached = bindingsForPath[firstActiveIndex];
                    var binding = bindingsForPath[index];

                    bindingsForPath[index] = lastCached;

                    if (binding == null) {
                        binding = new PropertyBinding(object, _paths[j], _parsedPaths[j]);
                    }

                    bindingsForPath[firstActiveIndex] = binding;
                }
            } else if (_objects[index] != object) {
                Browser.window.console.error('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
            }
        }

        nCachedObjects_ = nCachedObjects;
    }

    public function remove(...args) {
        var nCachedObjects = nCachedObjects_;
        var nBindings = _bindings.length;

        for (i in 0...args.length) {
            var object = args[i];
            var uuid = object.uuid;
            var index = _indicesByUUID[uuid];

            if (index != null && index >= nCachedObjects) {
                var lastCachedIndex = nCachedObjects++;
                var firstActiveObject = _objects[lastCachedIndex];

                _indicesByUUID[firstActiveObject.uuid] = index;
                _objects[index] = firstActiveObject;

                _indicesByUUID[uuid] = lastCachedIndex;
                _objects[lastCachedIndex] = object;

                for (j in 0...nBindings) {
                    var bindingsForPath = _bindings[j];
                    var firstActive = bindingsForPath[lastCachedIndex];
                    var binding = bindingsForPath[index];

                    bindingsForPath[index] = firstActive;
                    bindingsForPath[lastCachedIndex] = binding;
                }
            }
        }

        nCachedObjects_ = nCachedObjects;
    }

    public function uncache(...args) {
        var nCachedObjects = nCachedObjects_;
        var nObjects = _objects.length;
        var nBindings = _bindings.length;

        for (i in 0...args.length) {
            var object = args[i];
            var uuid = object.uuid;
            var index = _indicesByUUID[uuid];

            if (index != null) {
                delete _indicesByUUID[uuid];

                if (index < nCachedObjects) {
                    var firstActiveIndex = --nCachedObjects;
                    var lastCachedObject = _objects[firstActiveIndex];
                    var lastIndex = --nObjects;
                    var lastObject = _objects[lastIndex];

                    _indicesByUUID[lastCachedObject.uuid] = index;
                    _objects[index] = lastCachedObject;

                    _indicesByUUID[uuid] = firstActiveIndex;
                    _objects[firstActiveIndex] = lastObject;
                    _objects.pop();

                    for (j in 0...nBindings) {
                        var bindingsForPath = _bindings[j];
                        var lastCached = bindingsForPath[firstActiveIndex];
                        var last = bindingsForPath[lastIndex];

                        bindingsForPath[index] = lastCached;
                        bindingsForPath[firstActiveIndex] = last;
                        bindingsForPath.pop();
                    }
                } else {
                    var lastIndex = --nObjects;
                    var lastObject = _objects[lastIndex];

                    if (lastIndex > 0) {
                        _indicesByUUID[lastObject.uuid] = index;
                    }

                    _objects[index] = lastObject;
                    _objects.pop();

                    for (j in 0...nBindings) {
                        var bindingsForPath = _bindings[j];

                        bindingsForPath[index] = bindingsForPath[lastIndex];
                        bindingsForPath.pop();
                    }
                }
            }
        }

        nCachedObjects_ = nCachedObjects;
    }

    public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
        var index = _bindingsIndicesByPath.exists(path) ? _bindingsIndicesByPath.get(path) : null;
        var bindings = _bindings;

        if (index != null) return bindings[index];

        var nObjects = _objects.length;
        var nCachedObjects = nCachedObjects_;
        var bindingsForPath = new Array<PropertyBinding>(nObjects);

        index = bindings.length;

        _bindingsIndicesByPath.set(path, index);

        _paths.push(path);
        _parsedPaths.push(parsedPath);
        bindings.push(bindingsForPath);

        for (i in nCachedObjects..._objects.length) {
            var object = _objects[i];
            bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);
        }

        return bindingsForPath;
    }

    public function unsubscribe_(path:String) {
        var index = _bindingsIndicesByPath.exists(path) ? _bindingsIndicesByPath.get(path) : null;

        if (index != null) {
            var lastBindingsIndex = _bindings.length - 1;
            var lastBindings = _bindings[lastBindingsIndex];
            var lastBindingsPath = _paths[lastBindingsIndex];

            _bindingsIndicesByPath.set(lastBindingsPath, index);

            _bindings[index] = lastBindings;
            _bindings.pop();

            _parsedPaths[index] = _parsedPaths[lastBindingsIndex];
            _parsedPaths.pop();

            _paths[index] = _paths[lastBindingsIndex];
            _paths.pop();
        }
    }
}