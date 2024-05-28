Here is the converted Haxe code:
```
package three.animation;

import haxe.ds.ArraySort;

class AnimationObjectGroup {
  public var isAnimationObjectGroup:Bool = true;
  public var uuid:String;
  private var _objects:Array.Dynamic = [];
  private var nCachedObjects_:Int = 0;
  private var _indicesByUUID:Map<String, Int> = new Map<String, Int>();
  private var _paths:Array<String> = [];
  private var _parsedPaths:Array<Dynamic> = [];
  private var _bindings:Array<Array<PropertyBinding>> = [];
  private var _bindingsIndicesByPath:Map<String, Int> = new Map<String, Int>();
  public var stats: {
    objects: {
      get_total():Int,
      get_inUse():Int
    },
    get_bindingsPerObject():Int
  };

  public function new() {
    uuid = MathUtils.generateUUID();
    for (i in 0...args.length) {
      _objects.push(args[i]);
      _indicesByUUID[args[i].uuid] = i;
    }
    stats = {
      objects: {
        get_total():Int {
          return _objects.length;
        },
        get_inUse():Int {
          return _total - nCachedObjects_;
        }
      },
      get_bindingsPerObject():Int {
        return _bindings.length;
      }
    };
  }

  public function add(objects:Array<Dynamic>) {
    var objects:Array<Dynamic> = _objects,
      indicesByUUID:Map<String, Int> = _indicesByUUID,
      paths:Array<String> = _paths,
      parsedPaths:Array<Dynamic> = _parsedPaths,
      bindings:Array<Array<PropertyBinding>> = _bindings,
      nBindings:Int = bindings.length;
    var knownObject:Dynamic;
    var nObjects:Int = objects.length;
    var nCachedObjects:Int = nCachedObjects_;
    for (i in 0...objects.length) {
      var object:Dynamic = objects[i];
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
        knownObject = objects[index];
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
      } else if (objects[index] != knownObject) {
        Console.error('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
      }
    }
    nCachedObjects_ = nCachedObjects;
  }

  public function remove(objects:Array<Dynamic>) {
    var objects:Array<Dynamic> = _objects,
      indicesByUUID:Map<String, Int> = _indicesByUUID,
      bindings:Array<Array<PropertyBinding>> = _bindings,
      nBindings:Int = bindings.length;
    var nCachedObjects:Int = nCachedObjects_;
    for (i in 0...objects.length) {
      var object:Dynamic = objects[i],
        uuid:String = object.uuid,
        index:Int = indicesByUUID[uuid];
      if (index != null && index >= nCachedObjects) {
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
    nCachedObjects_ = nCachedObjects;
  }

  public function uncache(objects:Array<Dynamic>) {
    var objects:Array<Dynamic> = _objects,
      indicesByUUID:Map<String, Int> = _indicesByUUID,
      bindings:Array<Array<PropertyBinding>> = _bindings,
      nBindings:Int = bindings.length;
    var nCachedObjects:Int = nCachedObjects_,
      nObjects:Int = objects.length;
    for (i in 0...objects.length) {
      var object:Dynamic = objects[i],
        uuid:String = object.uuid,
        index:Int = indicesByUUID[uuid];
      if (index != null) {
        delete indicesByUUID[uuid];
        if (index < nCachedObjects) {
          var firstActiveIndex:Int = --nCachedObjects,
            lastCachedObject:Dynamic = objects[firstActiveIndex],
            lastIndex:Int = --nObjects,
            lastObject:Dynamic = objects[lastIndex];
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
          var lastIndex:Int = --nObjects,
            lastObject:Dynamic = objects[lastIndex];
          if (lastIndex > 0) {
            indicesByUUID[lastObject.uuid] = index;
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

  public function subscribe_(path:String, parsedPath:Dynamic) {
    var indicesByPath:Map<String, Int> = _bindingsIndicesByPath;
    var index:Int = indicesByPath[path];
    var bindings:Array<Array<PropertyBinding>> = _bindings;
    if (index != null) return bindings[index];
    var paths:Array<String> = _paths,
      parsedPaths:Array<Dynamic> = _parsedPaths,
      objects:Array<Dynamic> = _objects,
      nObjects:Int = objects.length,
      nCachedObjects:Int = nCachedObjects_,
      bindingsForPath:Array<PropertyBinding> = new Array<PropertyBinding>(nObjects);
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

  public function unsubscribe_(path:String) {
    var indicesByPath:Map<String, Int> = _bindingsIndicesByPath,
      index:Int = indicesByPath[path];
    if (index != null) {
      var paths:Array<String> = _paths,
        parsedPaths:Array<Dynamic> = _parsedPaths,
        bindings:Array<Array<PropertyBinding>> = _bindings,
        lastBindingsIndex:Int = bindings.length - 1,
        lastBindings:Array<PropertyBinding> = bindings[lastBindingsIndex],
        lastBindingsPath:String = paths[lastBindingsIndex];
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
```