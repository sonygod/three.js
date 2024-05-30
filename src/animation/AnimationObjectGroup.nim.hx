import MathUtils.MathUtils;
import PropertyBinding.PropertyBinding;

/**
 * A group of objects that receives a shared animation state.
 *
 * Usage:
 *
 *  - Add objects you would otherwise pass as 'root' to the
 *    constructor or the .clipAction method of AnimationMixer.
 *
 *  - Instead pass this object as 'root'.
 *
 *  - You can also add and remove objects later when the mixer
 *    is running.
 *
 * Note:
 *
 *    Objects of this class appear as one object to the mixer,
 *    so cache control of the individual objects must be done
 *    on the group.
 *
 * Limitation:
 *
 *  - The animated properties must be compatible among the
 *    all objects in the group.
 *
 *  - A single property can either be controlled through a
 *    target group or directly, but not both.
 */
class AnimationObjectGroup {

    public var isAnimationObjectGroup:Bool = true;
    public var uuid:String = MathUtils.generateUUID();
    private var _objects:Array<Dynamic>;
    private var _indicesByUUID:Map<String, Int>;
    private var _paths:Array<String>;
    private var _parsedPaths:Array<Dynamic>;
    private var _bindings:Array<Array<PropertyBinding>>;
    private var _bindingsIndicesByPath:Map<String, Int>;
    public var stats:Stats;

    public function new() {

        _objects = Array.prototype.slice.call( arguments );

        _indicesByUUID = new Map<String, Int>();

        for ( i in 0...arguments.length ) {

            _indicesByUUID[arguments[i].uuid] = i;

        }

        _paths = [];
        _parsedPaths = [];
        _bindings = [];
        _bindingsIndicesByPath = new Map<String, Int>();

        var scope = this;

        stats = {

            objects: {
                get total() {

                    return _objects.length;

                },
                get inUse() {

                    return this.total - scope.nCachedObjects_;

                }
            },
            get bindingsPerObject() {

                return _bindings.length;

            }

        };

    }

    public function add(...objects:Array<Dynamic>) {

        var objects = _objects,
            indicesByUUID = _indicesByUUID,
            paths = _paths,
            parsedPaths = _parsedPaths,
            bindings = _bindings,
            nBindings = bindings.length;

        var knownObject:Dynamic,
            nObjects = objects.length,
            nCachedObjects = this.nCachedObjects_;

        for ( i in 0...objects.length ) {

            var object = objects[i],
                uuid = object.uuid;
            var index = indicesByUUID[uuid];

            if ( index == null ) {

                index = nObjects++;
                indicesByUUID[uuid] = index;
                objects.push(object);

                for ( j in 0...nBindings ) {

                    bindings[j].push(new PropertyBinding(object, paths[j], parsedPaths[j]));

                }

            } else if ( index < nCachedObjects ) {

                knownObject = objects[index];

                var firstActiveIndex = --nCachedObjects,
                    lastCachedObject = objects[firstActiveIndex];

                indicesByUUID[lastCachedObject.uuid] = index;
                objects[index] = lastCachedObject;

                indicesByUUID[uuid] = firstActiveIndex;
                objects[firstActiveIndex] = object;

                for ( j in 0...nBindings ) {

                    var bindingsForPath = bindings[j],
                        lastCached = bindingsForPath[firstActiveIndex];

                    var binding = bindingsForPath[index];

                    bindingsForPath[index] = lastCached;

                    if ( binding == null ) {

                        binding = new PropertyBinding(object, paths[j], parsedPaths[j]);

                    }

                    bindingsForPath[firstActiveIndex] = binding;

                }

            } else if ( objects[index] != knownObject ) {

                trace('THREE.AnimationObjectGroup: Different objects with the same UUID ' +
                    'detected. Clean the caches or recreate your infrastructure when reloading scenes.');

            }

        }

        this.nCachedObjects_ = nCachedObjects;

    }

    public function remove(...objects:Array<Dynamic>) {

        var objects = _objects,
            indicesByUUID = _indicesByUUID,
            bindings = _bindings,
            nBindings = bindings.length;

        var nCachedObjects = this.nCachedObjects_;

        for ( i in 0...objects.length ) {

            var object = objects[i],
                uuid = object.uuid,
                index = indicesByUUID[uuid];

            if ( index != null && index >= nCachedObjects ) {

                var lastCachedIndex = nCachedObjects++;
                var firstActiveObject = objects[lastCachedIndex];

                indicesByUUID[firstActiveObject.uuid] = index;
                objects[index] = firstActiveObject;

                indicesByUUID[uuid] = lastCachedIndex;
                objects[lastCachedIndex] = object;

                for ( j in 0...nBindings ) {

                    var bindingsForPath = bindings[j],
                        firstActive = bindingsForPath[lastCachedIndex],
                        binding = bindingsForPath[index];

                    bindingsForPath[index] = firstActive;
                    bindingsForPath[lastCachedIndex] = binding;

                }

            }

        }

        this.nCachedObjects_ = nCachedObjects;

    }

    public function uncache(...objects:Array<Dynamic>) {

        var objects = _objects,
            indicesByUUID = _indicesByUUID,
            bindings = _bindings,
            nBindings = bindings.length;

        var nCachedObjects = this.nCachedObjects_,
            nObjects = objects.length;

        for ( i in 0...objects.length ) {

            var object = objects[i],
                uuid = object.uuid,
                index = indicesByUUID[uuid];

            if ( index != null ) {

                delete indicesByUUID[uuid];

                if ( index < nCachedObjects ) {

                    var firstActiveIndex = --nCachedObjects,
                        lastCachedObject = objects[firstActiveIndex],
                        lastIndex = --nObjects,
                        lastObject = objects[lastIndex];

                    indicesByUUID[lastCachedObject.uuid] = index;
                    objects[index] = lastCachedObject;

                    indicesByUUID[uuid] = firstActiveIndex;
                    objects[firstActiveIndex] = object;
                    objects.pop();

                    for ( j in 0...nBindings ) {

                        var bindingsForPath = bindings[j],
                            lastCached = bindingsForPath[firstActiveIndex],
                            last = bindingsForPath[lastIndex];

                        bindingsForPath[index] = lastCached;
                        bindingsForPath[firstActiveIndex] = last;
                        bindingsForPath.pop();

                    }

                } else {

                    var lastIndex = --nObjects,
                        lastObject = objects[lastIndex];

                    if ( lastIndex > 0 ) {

                        indicesByUUID[lastObject.uuid] = index;

                    }

                    objects[index] = lastObject;
                    objects.pop();

                    for ( j in 0...nBindings ) {

                        var bindingsForPath = bindings[j];

                        bindingsForPath[index] = bindingsForPath[lastIndex];
                        bindingsForPath.pop();

                    }

                }

            }

        }

        this.nCachedObjects_ = nCachedObjects;

    }

    public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {

        var indicesByPath = _bindingsIndicesByPath;
        var index = indicesByPath[path];
        var bindings = _bindings;

        if ( index != null ) return bindings[index];

        var paths = _paths,
            parsedPaths = _parsedPaths,
            objects = _objects,
            nObjects = objects.length,
            nCachedObjects = this.nCachedObjects_,
            bindingsForPath = new Array<PropertyBinding>();

        index = bindings.length;

        indicesByPath[path] = index;

        paths.push(path);
        parsedPaths.push(parsedPath);
        bindings.push(bindingsForPath);

        for ( i in nCachedObjects...objects.length ) {

            var object = objects[i];
            bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);

        }

        return bindingsForPath;

    }

    public function unsubscribe_(path:String) {

        var indicesByPath = _bindingsIndicesByPath,
            index = indicesByPath[path];

        if ( index != null ) {

            var paths = _paths,
                parsedPaths = _parsedPaths,
                bindings = _bindings,
                lastBindingsIndex = bindings.length - 1,
                lastBindings = bindings[lastBindingsIndex],
                lastBindingsPath = paths[lastBindingsIndex];

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