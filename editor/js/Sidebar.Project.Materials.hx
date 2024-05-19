package three.js.editor.js;

import ui.UIBreak;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIListbox;
import ui.UIButton;

import commands.SetMaterialCommand;

class SidebarProjectMaterials {
    private var editor:Editor;
    private var signals:Signals;
    private var strings:Strings;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;

        var container:UIPanel = new UIPanel();

        var headerRow:UIRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/project/materials').toUpperCase()));
        container.add(headerRow);

        var listbox:UIListbox = new UIListbox();
        container.add(listbox);

        container.add(new UIBreak());

        var buttonsRow:UIRow = new UIRow();
        container.add(buttonsRow);

        var assignMaterial:UIButton = new UIButton(strings.getKey('sidebar/project/Assign'));
        assignMaterial.onClick(function() {
            var selectedObject:Object3D = editor.selected;

            if (selectedObject != null) {
                var oldMaterial:Material = selectedObject.material;

                if (oldMaterial != null) {
                    var material:Material = editor.getMaterialById(Std.parseInt(listbox.getValue()));

                    if (material != null) {
                        editor.removeMaterial(oldMaterial);
                        editor.execute(new SetMaterialCommand(editor, selectedObject, material));
                        editor.addMaterial(material);
                    }
                }
            }
        });
        buttonsRow.add(assignMaterial);

        // Signals
        function refreshMaterialBrowserUI() {
            listbox.setItems([for (material in editor.materials) material]);
        }

        signals.objectSelected.add(function(object:Object3D) {
            if (object != null) {
                var index:Int = Lambda.indexOf(editor.materials, object.material);
                listbox.selectIndex(index);
            }
        });

        signals.materialAdded.add(refreshMaterialBrowserUI);
        signals.materialChanged.add(refreshMaterialBrowserUI);
        signals.materialRemoved.add(refreshMaterialBrowserUI);

        return container;
    }
}