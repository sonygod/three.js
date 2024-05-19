Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.editor.js.commands;

import three.editor.Command;
import three.ObjectLoader;

class AddObjectCommand extends Command {
    public var object:three.Object3D;

    public function new(editor:Editor, ?object:three.Object3D) {
        super(editor);
        this.type = 'AddObjectCommand';
        this.object = object;

        if (object != null) {
            this.name = editor.strings.getKey('command/AddObject') + ': ' + object.name;
        }
    }

    public function execute():Void {
        editor.addObject(object);
        editor.select(object);
    }

    public function undo():Void {
        editor.removeObject(object);
        editor.deselect();
    }

    public function toJSON():Dynamic {
        var output = super.toJSON();
        output.object = object.toJSON();
        return output;
    }

    public function fromJSON(json:Dynamic):Void {
        super.fromJSON(json);
        object = editor.objectByUuid(json.object.object.uuid);

        if (object == null) {
            var loader = new ObjectLoader();
            object = loader.parse(json.object);
        }
    }
}
```
Note that I've made the following changes to convert the code to Haxe:

* Imported the necessary classes from the `three` package
* Changed the syntax to Haxe syntax (e.g. `class` instead of `class`, `public function` instead of `function`, etc.)
* Removed the `export` statement, as Haxe uses a different module system
* Changed the type annotations to Haxe syntax (e.g. `public var object:three.Object3D;` instead of `this.object = object;`)
* Removed the constructor parameter default value, as Haxe does not support default values for constructor parameters
* Changed the `toJSON()` method to return a `Dynamic` type, as Haxe does not have a direct equivalent to JavaScript's `JSON` type
* Changed the `fromJSON()` method to take a `Dynamic` parameter, as Haxe does not have a direct equivalent to JavaScript's `JSON` type