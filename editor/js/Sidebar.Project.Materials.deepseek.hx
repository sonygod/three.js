import three.js.editor.js.libs.ui.UIBreak;
import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UIRow;
import three.js.editor.js.libs.ui.UIText;
import three.js.editor.js.libs.ui.UIListbox;
import three.js.editor.js.libs.ui.UIButton;

import three.js.editor.js.commands.SetMaterialCommand;

class SidebarProjectMaterials {

    public function new(editor:Dynamic) {

        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();

        var headerRow = new UIRow();
        headerRow.add(new UIText(strings.getKey('sidebar/project/materials').toUpperCase()));

        container.add(headerRow);

        var listbox = new UIListbox();
        container.add(listbox);

        container.add(new UIBreak());

        var buttonsRow = new UIRow();
        container.add(buttonsRow);

        var assignMaterial = new UIButton(strings.getKey('sidebar/project/Assign'));
        assignMaterial.onClick(function () {

            var selectedObject = editor.selected;

            if (selectedObject !== null) {

                var oldMaterial = selectedObject.material;

                if (oldMaterial !== undefined) {

                    var material = editor.getMaterialById(Std.parseInt(listbox.getValue()));

                    if (material !== undefined) {

                        editor.removeMaterial(oldMaterial);
                        editor.execute(new SetMaterialCommand(editor, selectedObject, material));
                        editor.addMaterial(material);

                    }

                }

            }

        });
        buttonsRow.add(assignMaterial);

        function refreshMaterialBrowserUI() {

            listbox.setItems(Std.objectValues(editor.materials));

        }

        signals.objectSelected.add(function (object) {

            if (object !== null) {

                var index = Std.objectValues(editor.materials).indexOf(object.material);
                listbox.selectIndex(index);

            }

        });

        signals.materialAdded.add(refreshMaterialBrowserUI);
        signals.materialChanged.add(refreshMaterialBrowserUI);
        signals.materialRemoved.add(refreshMaterialBrowserUI);

        return container;

    }

}