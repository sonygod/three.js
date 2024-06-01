import haxe.ds.StringMap;
import js.lib.Promise;

import three.THREE;

import editor.commands.SetMaterialCommand;
import editor.Editor;
import ui.UIBreak;
import ui.UIButton;
import ui.UIListbox;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;

class SidebarProjectMaterials extends UIPanel {

    public function new(editor:Editor) {
        super();

        var signals = editor.signals;
        var strings = editor.strings;

        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/project/materials').toUpperCase()));

        add(headerRow);

        var listbox = new UIListbox();
        add(listbox);

        add(new UIBreak());

        var buttonsRow = new UIRow();
        add(buttonsRow);

        var assignMaterial = new UIButton(strings.getKey('sidebar/project/Assign'));
        assignMaterial.onClick(function(_) {
            var selectedObject = editor.selected;

            if (selectedObject != null) {
                var oldMaterial = selectedObject.material;

                // only assing materials to objects with a material property (e.g. avoid assigning material to THREE.Group)

                if (oldMaterial != null) {
                    var material = getMaterialById(editor.materials, Std.parseInt(listbox.getValue()));

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
            listbox.setItems(Lambda.array(editor.materials));
        }

        signals.objectSelected.add(function(object:THREE.Object3D) {
            if (object != null) {
                var index = Lambda.indexOf(Lambda.array(editor.materials), object.material);
                listbox.selectIndex(index);
            }
        });

        signals.materialAdded.add(refreshMaterialBrowserUI);
        signals.materialChanged.add(refreshMaterialBrowserUI);
        signals.materialRemoved.add(refreshMaterialBrowserUI);
    }

    function getMaterialById(materials:Array<THREE.Material>, id:Int):THREE.Material {
        for (material in materials) {
            if (material.id == id) {
                return material;
            }
        }
        return null;
    }
}