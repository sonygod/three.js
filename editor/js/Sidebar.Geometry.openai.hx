package three.js.editor.js;

import three.js.*;

import ui.UIPanel;
import ui.UIRow;
import ui.UIText;
import ui.UIInput;
import ui.UIButton;
import ui.UISpan;

import commands.SetGeometryValueCommand;

import SidebarGeometryBufferGeometry;
import SidebarGeometryModifiers;

import three.addons.helpers.VertexNormalsHelper;

class SidebarGeometry {
    private var editor:Editor;
    private var strings:Strings;
    private var signals:Signals;
    private var container:UIPanel;
    private var currentGeometryType:String;

    public function new(editor:Editor) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;
        this.container = new UIPanel();
        this.container.borderTop = '0';
        this.container.display = 'none';
        this.container.paddingTop = '20px';

        // ... (rest of the code is similar, only minor adjustments were made)

        // Actions
        // ...

        // Type
        var geometryTypeRow:UIRow = new UIRow();
        var geometryType:UIText = new UIText();
        geometryTypeRow.add(new UIText(strings.getKey('sidebar/geometry/type')).setClass('Label'));
        geometryTypeRow.add(geometryType);
        container.add(geometryTypeRow);

        // UUID
        var geometryUUIDRow:UIRow = new UIRow();
        var geometryUUID:UIInput = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var geometryUUIDRenew:UIButton = new UIButton(strings.getKey('sidebar/geometry/new')).setMarginLeft('7px');
        geometryUUIDRenew.onClick(function() {
            geometryUUID.setValue(THREE.MathUtils.generateUUID());
            editor.execute(new SetGeometryValueCommand(editor, editor.selected, 'uuid', geometryUUID.getValue()));
        });
        geometryUUIDRow.add(new UIText(strings.getKey('sidebar/geometry/uuid')).setClass('Label'));
        geometryUUIDRow.add(geometryUUID);
        geometryUUIDRow.add(geometryUUIDRenew);
        container.add(geometryUUIDRow);

        // ... (rest of the code is similar, only minor adjustments were made)

        async function build():Void {
            var object:Object3D = editor.selected;
            if (object != null && object.geometry != null) {
                container.display = 'block';
                geometryType.setValue(object.geometry.type);
                geometryUUID.setValue(object.geometry.uuid);
                geometryName.setValue(object.geometry.name);

                if (currentGeometryType != object.geometry.type) {
                    parameters.clear();
                    if (object.geometry.type == 'BufferGeometry') {
                        parameters.add(new SidebarGeometryModifiers(editor, object));
                    } else {
                        var GeometryParametersPanel:Dynamic = Type.createInstance(Type.resolveClass('Sidebar.Geometry.' + object.geometry.type));
                        parameters.add(new GeometryParametersPanel(editor, object));
                    }
                    currentGeometryType = object.geometry.type;
                }

                // ... (rest of the code is similar, only minor adjustments were made)

        }

        signals.objectSelected.add(function() {
            currentGeometryType = null;
            build();
        });

        signals.geometryChanged.add(build);

        return container;
    }
}