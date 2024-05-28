import js.js;
import js.Browser;

class AnimationObjectGroup {
    public var isAnimationObjectGroup:Bool = true;
    public var uuid:String;
    private var _objects:Array<Dynamic>;
    private var nCachedObjects_:Int;
    private var _indicesByUUID:Map<String, Int>;
    private var _paths:Array<String>;
    private var _parsedPaths:Array<Dynamic>;
    private var _bindings:Array<Array<PropertyBinding>>;
    private var _bindingsIndicesByPath:Map<String, Int>;
    public var stats:AnimationObjectGroup_Stats;

    public function new() {
        uuid = MathUtils.generateUUID();
        _objects = [];
        nCachedObjects_ = 0;
        _indicesByUUID = new Map();
        _paths = [];
        _parsedPaths = [];
        _bindings = [];
        _bindingsIndicesByPath = new Map();
        stats = {
            objects: {
                get_total: $bind(this, $field("objects", "total")),
                get_inUse: $bind(this, $field("objects", "inUse"))
            },
            get_bindingsPerObject: $bind(this, $field("bindingsPerObject"))
        };
    }

    public function add(...objects:Array<Dynamic>) {
        var knownObject:Dynamic;
        var nObjects = _objects.length;
        var nCachedObjects = nCachedObjects_;

        for (obj in objects) {
            var object = obj;
            var uuid = object.uuid;
            var index = _indicesByUUID.get(uuid);

            if (index == null) {
                // unknown object -> add it to the ACTIVE region
                index = nObjects++;
                _indicesByUUID.set(uuid, index);
                _objects.push(object);

                // accounting is done, now do the same for all bindings
                for (j in 0..._bindings.length) {
                    _bindings[j].push(new PropertyBinding(object, _paths[j], _parsedPaths[j]));
                }
            } else if (index < nCachedObjects) {
                knownObject = _objects[index];

                // move existing object to the ACTIVE region
                var firstActiveIndex = --nCachedObjects;
                var lastCachedObject = _objects[firstActiveIndex];

                _indicesByUUID.set(lastCachedObject.uuid, index);
                _objects[index] = lastCachedObject;

                _indicesByUUID.set(uuid, firstActiveIndex);
                _objects[firstActiveIndex] = object;

                // accounting is done, now do the same for all bindings
                for (j in 0..._bindings.length) {
                    var bindingsForPath = _bindings[j];
                    var lastCached = bindingsForPath[firstActiveIndex];
                    var binding = bindingsForPath[index];

                    bindingsForPath[index] = lastCached;

                    if (binding == null) {
                        // since we do not bother to create new bindings
                        // for objects that are cached, the binding may
                        // or may not exist
                        binding = new PropertyBinding(object, _paths[j], _parsedPaths[j]);
                    }

                    bindingsForPath[firstActiveIndex] = binding;
                }
            } else if (_objects[index] != knownObject) {
                js.Browser.console.error("THREE.AnimationObjectGroup: Different objects with the same UUID " +
                    "detected. Clean the caches or recreate your infrastructure when reloading scenes.");
            } // else the object is already where we want it to be
        } // for arguments

        nCachedObjects_ = nCachedObjects;
    }

    public function remove(...objects:Array<Dynamic>) {
        var nCachedObjects = nCachedObjects_;

        for (obj in objects) {
            var object = obj;
            var uuid = object.uuid;
            var index = _indicesByUUID.get(uuid);

            if (index != null && index >= nCachedObjects) {
                // move existing object into the CACHED region
                var lastCachedIndex = nCachedObjects++;
                var firstActiveObject = _objects[lastCachedIndex];

                _indicesByUUID.set(firstActiveObject.uuid, index);
                _objects[index] = firstActiveObject;

                _indicesByUUID.set(uuid, lastCachedIndex);
                _objects[lastCachedIndex] = object;

                // accounting is done, now do the same for all bindings
                for (j in 0..._bindings.length) {
                    var bindingsForPath = _bindings[j];
                    var firstActive = bindingsForPath[lastCachedIndex];
                    var binding = bindingsForPath[index];

                    bindingsForPath[index] = firstActive;
                    bindingsForPath[lastCachedIndex] = binding;
                }
            }
        } // for arguments

        nCachedObjects_ = nCachedObjects;
    }

    // remove & forget
    public function uncache(...objects:Array<Dynamic>) {
        var nCachedObjects = nCachedObjects_;
        var nObjects = _objects.length;

        for (obj in objects) {
            var object = obj;
            var uuid = object.uuid;
            var index = _indicesByUUID.get(uuid);

            if (index != null) {
                _indicesByUUID.remove(uuid);

                if (index < nCachedObjects) {
                    // object is cached, shrink the CACHED region
                    var firstActiveIndex = --nCachedObjects;
                    var lastCachedObject = _objects[firstActiveIndex];
                    var lastIndex = --nObjects;
                    var lastObject = _objects[lastIndex];

                    // last cached object takes this object's place
                    _indicesByUUID.set(lastCachedObject.uuid, index);
                    _objects[index] = lastCachedObject;

                    // last object goes to the activated slot and pop
                    _indicesByUUID.set(lastObject.uuid, firstActiveIndex);
                    _objects[firstActiveIndex] = lastObject;
                    _objects.pop();

                    // accounting is done, now do the same for all bindings
                    for (j in 0..._bindings.length) {
                        var bindingsForPath = _bindings[j];
                        var lastCached = bindingsForPath[firstActiveIndex];
                        var last = bindingsForPath[lastIndex];

                        bindingsForPath[index] = lastCached;
                        bindingsForPath[firstActiveIndex] = last;
                        bindingsForPath.pop();
                    }
                } else {
                    // object is active, just swap with the last and pop
                    var lastIndex = --nObjects;
                    var lastObject = _objects[lastIndex];

                    if (lastIndex > 0) {
                        _indicesByUUID.set(lastObject.uuid, index);
                    }

                    _objects[index] = lastObject;
                    _objects.pop();

                    // accounting is done, now do the same for all bindings
                    for (j in 0..._bindings.length) {
                        var bindingsForPath = _bindings[j];

                        bindingsForPath[index] = bindingsForPath[lastIndex];
                        bindingsForPath.pop();
                    }
                } // cached or active
            } // if object is known
        } // for arguments

        nCachedObjects_ = nCachedObjects;
    }

    // Internal interface used by befriended PropertyBinding.Composite:
    public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
        // returns an array of bindings for the given path that is changed
        // according to the contained objects in the group
        var index = _bindingsIndicesByPath.get(path);
        var bindings = _bindings;

        if (index != null) return bindings[index];

        var paths = _paths;
        var parsedPaths = _parsedPaths;
        var objects = _objects;
        var nObjects = objects.length;
        var nCachedObjects = nCachedObjects_;
        var bindingsForPath = new Array<PropertyBinding>(nObjects);

        index = bindings.length;

        _bindingsIndicesByPath.set(path, index);

        paths.push(path);
        parsedPaths.push(parsedPath);
        bindings.push(bindingsForPath);

        for (i in nCachedObjects...nObjects) {
            var object = objects[i];
            bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);
        }

        return bindingsForPath;
    }

    public function unsubscribe_(path:String) {
        // tells the group to forget about a property path and no longer
        // update the array previously obtained with 'subscribe_'
        var index = _bindingsIndicesByPath.get(path);

        if (index != null) {
            var paths = _paths;
            var parsedPaths = _parsedPaths;
            var bindings = _bindings;
            var lastBindingsIndex = bindings.length - 1;
            var lastBindings = bindings[lastBindingsIndex];
            var lastBindingsPath = path[lastBindingsIndex];

            _bindingsIndicesByPath.set(lastBindingsPath, index);

            bindings[index] = lastBindings;
            bindings.pop();

            parsedPaths[index] = parsedPaths[lastBindingsIndex];
            parsedPaths.pop();

            paths[index] = paths[lastBindingsIndex];
            paths.pop();
        }
    }
}

class AnimationObjectGroup_Stats {
    public function get_objects():AnimationObjectGroup_Stats_Objects {
        return { total: $bind(this, $field("total")), inUse: $bind(this, $field("inUse")) };
    }

    public function get_bindingsPerObject():Int {
        return cast _bindings.length;
    }
}

class AnimationObjectGroup_Stats_Objects {
    public function get_total():Int {
        return cast _objects.length;
    }

    public function get_inUse():Int {
        return cast (this.total - nCachedObjects_);
    }
}