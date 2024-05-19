package three.js.editor.js;

import js.ui.UIButton;
import js.ui.UIRow;
import js.ui.UIText;

class SidebarMaterialProgram {
    private var editor:Editor;
    private var property:String;
    private var signals: Signals;
    private var strings:Strings;
    private var object:Object3D;
    private var materialSlot:Int;
    private var material:Material;
    private var container:UIRow;

    public function new(editor:Editor, property:String) {
        this.editor = editor;
        this.property = property;
        signals = editor.signals;
        strings = editor.strings;

        object = null;
        materialSlot = 0;
        material = null;

        container = new UIRow();
        container.add(new UIText(strings.getKey('sidebar/material/program')).setClass('Label'));

        var programInfo:UIButton = new UIButton(strings.getKey('sidebar/material/info'));
        programInfo.setMarginRight('4px');
        programInfo.onClick(function() {
            signals.editScript.dispatch(object, 'programInfo');
        });
        container.add(programInfo);

        var programVertex:UIButton = new UIButton(strings.getKey('sidebar/material/vertex'));
        programVertex.setMarginRight('4px');
        programVertex.onClick(function() {
            signals.editScript.dispatch(object, 'vertexShader');
        });
        container.add(programVertex);

        var programFragment:UIButton = new UIButton(strings.getKey('sidebar/material/fragment'));
        programFragment.setMarginRight('4px');
        programFragment.onClick(function() {
            signals.editScript.dispatch(object, 'fragmentShader');
        });
        container.add(programFragment);

        update = function(currentObject:Object3D, currentMaterialSlot:Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == null) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (Reflect.hasField(material, property)) {
                container.setDisplay('');
            } else {
                container.setDisplay('none');
            }
        };

        signals.objectSelected.add(update);
        signals.materialChanged.add(update);
    }
}