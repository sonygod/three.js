import js.Browser.document;
import js.Lib.{UIButton, UIRow, UIText};

class SidebarMaterialProgram {

    var editor:Dynamic;
    var property:Dynamic;
    var signals:Dynamic;
    var strings:Dynamic;
    var object:Dynamic;
    var materialSlot:Dynamic;
    var material:Dynamic;
    var container:UIRow;

    public function new(editor:Dynamic, property:Dynamic) {
        this.editor = editor;
        this.property = property;
        this.signals = editor.signals;
        this.strings = editor.strings;
        this.object = null;
        this.materialSlot = null;
        this.material = null;
        this.container = new UIRow();
        this.container.add(new UIText(strings.getKey('sidebar/material/program')).setClass('Label'));

        var programInfo = new UIButton(strings.getKey('sidebar/material/info'));
        programInfo.setMarginRight('4px');
        programInfo.onClick(function () {
            signals.editScript.dispatch(object, 'programInfo');
        });
        this.container.add(programInfo);

        var programVertex = new UIButton(strings.getKey('sidebar/material/vertex'));
        programVertex.setMarginRight('4px');
        programVertex.onClick(function () {
            signals.editScript.dispatch(object, 'vertexShader');
        });
        this.container.add(programVertex);

        var programFragment = new UIButton(strings.getKey('sidebar/material/fragment'));
        programFragment.setMarginRight('4px');
        programFragment.onClick(function () {
            signals.editScript.dispatch(object, 'fragmentShader');
        });
        this.container.add(programFragment);

        this.signals.objectSelected.add(this.update);
        this.signals.materialChanged.add(this.update);
    }

    function update(currentObject:Dynamic, currentMaterialSlot:Dynamic = 0) {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object == null) return;
        if (this.object.material == undefined) return;

        this.material = editor.getObjectMaterial(this.object, this.materialSlot);

        if (this.property in this.material) {
            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer():UIRow {
        return this.container;
    }
}