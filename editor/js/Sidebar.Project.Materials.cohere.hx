import js.Browser.Window;

import js.three.Object3D;

import js.three.Material;

import js.ui_components.UIBreak;

import js.ui_components.UIPanel;

import js.ui_components.UIRow;

import js.ui_components.UIText;

import js.ui_components.UIListbox;

import js.ui_components.UIButton;

class SidebarProjectMaterials {
    static function create(editor:Editor) {
        var container = new UIPanel();
        var headerRow = new UIRow();
        headerRow.add(new UIText(editor.strings.getKey('sidebar/project/materials').toUpperCase()));
        container.add(headerRow);
        var listbox = new UIListbox();
        container.add(listbox);
        container.add(new UIBreak());
        var buttonsRow = new UIRow();
        container.add(buttonsRow);
        var assignMaterial = new UIButton(editor.strings.getKey('sidebar/project/Assign'));
        assignMaterial.onClick(function() {
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
            listbox.setItems(editor.materials.iterator().map($it => $it).toArray());
        }
        editor.signals.objectSelected.add(function(object:Object3D) {
            if (object != null) {
                var index = editor.materials.iterator().map($it => $it).toArray().indexOf(object.material);
                listbox.selectIndex(index);
            }
        });
        editor.signals.materialAdded.add(refreshMaterialBrowserUI);
        editor.signals.materialChanged.add(refreshMaterialBrowserUI);
        editor.signals.materialRemoved.add(refreshMaterialBrowserUI);
        return container;
    }
}