Here is the equivalent Haxe code:
```
package three.js.editor.js.commands;

import three.js.editor.js.Command;

/**
 * @param editor Editor
 * @param object THREE.Object3D
 * @param attributeName String
 * @param newValue Dynamic (number, string, boolean or object)
 * @constructor
 */
class SetMaterialValueCommand extends Command {
  public var type:String;
  public var name:String;
  public var updatable:Bool;
  public var object:Dynamic;
  public var materialSlot:Int;
  public var oldValue:Dynamic;
  public var newValue:Dynamic;
  public var attributeName:String;

  public function new(editor:Editor, object:Dynamic = null, attributeName:String = '', newValue:Dynamic = null, materialSlot:Int = -1) {
    super(editor);

    this.type = 'SetMaterialValueCommand';
    this.name = editor.strings.getKey('command/SetMaterialValue') + ': ' + attributeName;
    this.updatable = true;

    this.object = object;
    this.materialSlot = materialSlot;

    var material:Dynamic = (object != null) ? editor.getObjectMaterial(object, materialSlot) : null;

    this.oldValue = (material != null) ? material[attributeName] : null;
    this.newValue = newValue;

    this.attributeName = attributeName;
  }

  public function execute():Void {
    var material:Dynamic = editor.getObjectMaterial(object, materialSlot);

    material[attributeName] = newValue;
    material.needsUpdate = true;

    editor.signals.objectChanged.dispatch(object);
    editor.signals.materialChanged.dispatch(object, materialSlot);
  }

  public function undo():Void {
    var material:Dynamic = editor.getObjectMaterial(object, materialSlot);

    material[attributeName] = oldValue;
    material.needsUpdate = true;

    editor.signals.objectChanged.dispatch(object);
    editor.signals.materialChanged.dispatch(object, materialSlot);
  }

  public function update(cmd:SetMaterialValueCommand):Void {
    newValue = cmd.newValue;
  }

  public function toJSON():Dynamic {
    var output:Dynamic = super.toJSON(this);

    output.objectUuid = object.uuid;
    output.attributeName = attributeName;
    output.oldValue = oldValue;
    output.newValue = newValue;
    output.materialSlot = materialSlot;

    return output;
  }

  public function fromJSON(json:Dynamic):Void {
    super.fromJSON(json);

    attributeName = json.attributeName;
    oldValue = json.oldValue;
    newValue = json.newValue;
    object = editor.objectByUuid(json.objectUuid);
    materialSlot = json.materialSlot;
  }
}
```
Note that I've kept the same naming conventions and structure as the original JavaScript code. I've also used the `Dynamic` type to represent the `newValue` and `oldValue` properties, as well as the `material` property, since they can hold different types of values.