package three.js.editor;

import three.js.Three;

class SidebarObject {
    public var container:UIPanel;

    public function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;

        container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        // type
        var objectTypeRow = new UIRow();
        var objectType = new UIText();
        objectTypeRow.add(new UIText(strings.getKey('sidebar/object/type')).setClass('Label'));
        objectTypeRow.add(objectType);
        container.add(objectTypeRow);

        // uuid
        var objectUUIDRow = new UIRow();
        var objectUUID = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var objectUUIDRenew = new UIButton(strings.getKey('sidebar/object/new')).setMarginLeft('7px');
        objectUUIDRenew.onClick(function() {
            objectUUID.setValue(Three.MathUtils.generateUUID());
            editor.execute(new SetUuidCommand(editor, editor.selected, objectUUID.getValue()));
        });
        objectUUIDRow.add(new UIText(strings.getKey('sidebar/object/uuid')).setClass('Label'));
        objectUUIDRow.add(objectUUID);
        objectUUIDRow.add(objectUUIDRenew);
        container.add(objectUUIDRow);

        // name
        var objectNameRow = new UIRow();
        var objectName = new UIInput().setWidth('150px').setFontSize('12px');
        objectName.onChange(function() {
            editor.execute(new SetValueCommand(editor, editor.selected, 'name', objectName.getValue()));
        });
        objectNameRow.add(new UIText(strings.getKey('sidebar/object/name')).setClass('Label'));
        objectNameRow.add(objectName);
        container.add(objectNameRow);

        // position
        var objectPositionRow = new UIRow();
        var objectPositionX = new UINumber().setPrecision(3).setWidth('50px');
        var objectPositionY = new UINumber().setPrecision(3).setWidth('50px');
        var objectPositionZ = new UINumber().setPrecision(3).setWidth('50px');
        objectPositionRow.add(new UIText(strings.getKey('sidebar/object/position')).setClass('Label'));
        objectPositionRow.add(objectPositionX, objectPositionY, objectPositionZ);
        container.add(objectPositionRow);

        // rotation
        var objectRotationRow = new UIRow();
        var objectRotationX = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px');
        var objectRotationY = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px');
        var objectRotationZ = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px');
        objectRotationRow.add(new UIText(strings.getKey('sidebar/object/rotation')).setClass('Label'));
        objectRotationRow.add(objectRotationX, objectRotationY, objectRotationZ);
        container.add(objectRotationRow);

        // scale
        var objectScaleRow = new UIRow();
        var objectScaleX = new UINumber(1).setPrecision(3).setWidth('50px');
        var objectScaleY = new UINumber(1).setPrecision(3).setWidth('50px');
        var objectScaleZ = new UINumber(1).setPrecision(3).setWidth('50px');
        objectScaleRow.add(new UIText(strings.getKey('sidebar/object/scale')).setClass('Label'));
        objectScaleRow.add(objectScaleX, objectScaleY, objectScaleZ);
        container.add(objectScaleRow);

        // ... (rest of the code)

        function update() {
            var object = editor.selected;
            if (object != null) {
                // ...
            }
        }

        function updateRows(object:Object3D) {
            // ...
        }

        function updateUI(object:Object3D) {
            // ...
        }

        signals.objectSelected.add(function(object:Object3D) {
            if (object != null) {
                container.setDisplay('block');
                updateRows(object);
                updateUI(object);
            } else {
                container.setDisplay('none');
            }
        });

        signals.objectChanged.add(function(object:Object3D) {
            if (object != editor.selected) return;
            updateUI(object);
        });

        signals.refreshSidebarObject3D.add(function(object:Object3D) {
            if (object != editor.selected) return;
            updateUI(object);
        });
    }
}