Here is the converted Haxe code:
```
package three.js.playground.libs;

import js.html.Event;
import js.html.EventTarget;

class Loader extends EventTarget {
    public static inline var DEFAULT:Int = 0;
    public static inline var OBJECTS:Int = 1;

    private var parseType:Int;
    private var events:Dynamic = { 'load': [] };
    private var data:Dynamic;

    public function new(?parseType:Int = DEFAULT) {
        super();
        this.parseType = parseType;
        events = { 'load': [] };
    }

    public function setParseType(type:Int):Loader {
        this.parseType = type;
        return this;
    }

    public function getParseType():Int {
        return this.parseType;
    }

    public function onLoad(callback:Void->Void):Loader {
        events.load.push(callback);
        return this;
    }

    public function load(url:String, ?lib:Dynamic = {}):Promise<Dynamic> {
        return fetch(url)
            .then(response -> response.json())
            .then(result -> {
                data = parse(result, lib);
                dispatchEventList(events.load, this);
                return data;
            })
            .catchError(err -> {
                console.error('Loader:', err);
            });
    }

    private function parse(json:Dynamic, ?lib:Dynamic = {}):Dynamic {
        json = _parseObjects(json, lib);
        var parseType = this.parseType;
        if (parseType == DEFAULT) {
            var type = json.type;
            var flowClass:Dynamic = lib.exists(type) ? lib[type] : (LoaderLib.exists(type) ? LoaderLib[type] : Flow[type]);
            var flowObj = Type.createInstance(flowClass, []);
            if (flowObj.getSerializable() != null) {
                flowObj.deserialize(json);
            }
            return flowObj;
        } else if (parseType == OBJECTS) {
            return json;
        }
        return null;
    }

    private function _parseObjects(json:Dynamic, ?lib:Dynamic = {}):Dynamic {
        json = { ...json };
        var objects:Dynamic = {};
        for (id in json.objects.keys()) {
            var obj:Dynamic = json.objects[id];
            obj.objects = objects;
            var type = obj.type;
            var flowClass:Dynamic = lib.exists(type) ? lib[type] : (LoaderLib.exists(type) ? LoaderLib[type] : Flow[type]);
            if (flowClass == null) {
                console.error('Class "${type}" not found!');
            }
            objects[id] = Type.createInstance(flowClass, []);
            objects[id].deserializeLib(json.objects[id], lib);
        }
        var ref:Map<Dynamic, Bool> = new Map();
        var deserializePass:Void->Void = function(?prop:String) {
            for (id in json.objects.keys()) {
                var newObject:Dynamic = objects[id];
                if (!ref.exists(newObject) && (prop == null || newObject[prop] == true)) {
                    ref.set(newObject, true);
                    if (newObject.getSerializable() != null) {
                        newObject.deserialize(json.objects[id]);
                    }
                }
            }
        };
        deserializePass('isNode');
        deserializePass('isElement');
        deserializePass('isInput');
        deserializePass();
        json.objects = objects;
        return json;
    }
}
```
Note that I've used Haxe's `js` library to interact with JavaScript APIs, and assumed that `fetch` and `EventTarget` are available in the Haxe standard library. I've also used Haxe's dynamic typing to match the JavaScript code's dynamic nature.