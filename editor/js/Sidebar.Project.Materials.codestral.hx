import ui.UIBreak;
import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIListbox;
import ui.UIButton;
import commands.SetMaterialCommand;
import editor.Editor;

class SidebarProjectMaterials {
    public function new(editor: Editor) {
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
            if (selectedObject != null) {
                var oldMaterial = selectedObject.material;
                if (oldMaterial != null) {
                    var material = editor.getMaterialById(Std.parseInt(listbox.getValue()));
                    if (material != null) {
                        editor.removeMaterial(oldMaterial);
                        editor.execute(new SetMaterialCommand(editor, selectedObject, material));
                        editor.addMaterial(material);
                    }
                }
            }
        });
        buttonsRow.add(assignMaterial);

        function refreshMaterialBrowserUI() {
            listbox.setItems(Type.createEmptyInstance(editor.materials)._hx_getFields());
        }

        signals.objectSelected.add(function (object) {
            if (object != null) {
                var index = Type.createEmptyInstance(editor.materials)._hx_getFields().indexOf(object.material);
                listbox.selectIndex(index);
            }
        });

        signals.materialAdded.add(refreshMaterialBrowserUI);
        signals.materialChanged.add(refreshMaterialBrowserUI);
        signals.materialRemoved.add(refreshMaterialBrowserUI);

        return container;
    }
}