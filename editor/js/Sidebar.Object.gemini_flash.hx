import three.core.Object3D;
import three.cameras.OrthographicCamera;
import three.lights.AmbientLight;
import three.lights.HemisphereLight;
import three.lights.Light;
import three.math.Color;
import three.math.Euler;
import three.math.Vector3;
import three.MathUtils;

import js.Lib;

import ui.panels.UIPanel;
import ui.panels.UIRow;
import ui.inputs.UIInput;
import ui.inputs.UIButton;
import ui.inputs.UIColor;
import ui.inputs.UICheckbox;
import ui.inputs.UIInteger;
import ui.inputs.UITextArea;
import ui.inputs.UIText;
import ui.inputs.UINumber;
import ui.UIBoolean;

import commands.SetUuidCommand;
import commands.SetValueCommand;
import commands.SetPositionCommand;
import commands.SetRotationCommand;
import commands.SetScaleCommand;
import commands.SetColorCommand;

import SidebarObjectAnimation from './Sidebar.Object.Animation';

class SidebarObject {

    public function new(editor : Editor) {

        final strings = editor.strings;
        final signals = editor.signals;

        final container = new UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        // type

        final objectTypeRow = new UIRow();
        final objectType = new UIText();

        objectTypeRow.add(new UIText(strings.getKey('sidebar/object/type')).setClass('Label'));
        objectTypeRow.add(objectType);

        container.add(objectTypeRow);

        // uuid

        final objectUUIDRow = new UIRow();
        final objectUUID = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        final objectUUIDRenew = new UIButton(strings.getKey('sidebar/object/new')).setMarginLeft('7px').onClick(function() {

            objectUUID.setValue(MathUtils.generateUUID());

            editor.execute(new SetUuidCommand(editor, cast editor.selected, objectUUID.getValue()));

        });

        objectUUIDRow.add(new UIText(strings.getKey('sidebar/object/uuid')).setClass('Label'));
        objectUUIDRow.add(objectUUID);
        objectUUIDRow.add(objectUUIDRenew);

        container.add(objectUUIDRow);

        // name

        final objectNameRow = new UIRow();
        final objectName = new UIInput().setWidth('150px').setFontSize('12px').onChange(function() {

            editor.execute(new SetValueCommand(editor, cast editor.selected, 'name', objectName.getValue()));

        });

        objectNameRow.add(new UIText(strings.getKey('sidebar/object/name')).setClass('Label'));
        objectNameRow.add(objectName);

        container.add(objectNameRow);

        // position

        final objectPositionRow = new UIRow();
        final objectPositionX = new UINumber().setPrecision(3).setWidth('50px').onChange(update);
        final objectPositionY = new UINumber().setPrecision(3).setWidth('50px').onChange(update);
        final objectPositionZ = new UINumber().setPrecision(3).setWidth('50px').onChange(update);

        objectPositionRow.add(new UIText(strings.getKey('sidebar/object/position')).setClass('Label'));
        objectPositionRow.add(objectPositionX, objectPositionY, objectPositionZ);

        container.add(objectPositionRow);

        // rotation

        final objectRotationRow = new UIRow();
        final objectRotationX = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);
        final objectRotationY = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);
        final objectRotationZ = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);

        objectRotationRow.add(new UIText(strings.getKey('sidebar/object/rotation')).setClass('Label'));
        objectRotationRow.add(objectRotationX, objectRotationY, objectRotationZ);

        container.add(objectRotationRow);

        // scale

        final objectScaleRow = new UIRow();
        final objectScaleX = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);
        final objectScaleY = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);
        final objectScaleZ = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);

        objectScaleRow.add(new UIText(strings.getKey('sidebar/object/scale')).setClass('Label'));
        objectScaleRow.add(objectScaleX, objectScaleY, objectScaleZ);

        container.add(objectScaleRow);

        // fov

        final objectFovRow = new UIRow();
        final objectFov = new UINumber().onChange(update);

        objectFovRow.add(new UIText(strings.getKey('sidebar/object/fov')).setClass('Label'));
        objectFovRow.add(objectFov);

        container.add(objectFovRow);

        // left

        final objectLeftRow = new UIRow();
        final objectLeft = new UINumber().onChange(update);

        objectLeftRow.add(new UIText(strings.getKey('sidebar/object/left')).setClass('Label'));
        objectLeftRow.add(objectLeft);

        container.add(objectLeftRow);

        // right

        final objectRightRow = new UIRow();
        final objectRight = new UINumber().onChange(update);

        objectRightRow.add(new UIText(strings.getKey('sidebar/object/right')).setClass('Label'));
        objectRightRow.add(objectRight);

        container.add(objectRightRow);

        // top

        final objectTopRow = new UIRow();
        final objectTop = new UINumber().onChange(update);

        objectTopRow.add(new UIText(strings.getKey('sidebar/object/top')).setClass('Label'));
        objectTopRow.add(objectTop);

        container.add(objectTopRow);

        // bottom

        final objectBottomRow = new UIRow();
        final objectBottom = new UINumber().onChange(update);

        objectBottomRow.add(new UIText(strings.getKey('sidebar/object/bottom')).setClass('Label'));
        objectBottomRow.add(objectBottom);

        container.add(objectBottomRow);

        // near

        final objectNearRow = new UIRow();
        final objectNear = new UINumber().onChange(update);

        objectNearRow.add(new UIText(strings.getKey('sidebar/object/near')).setClass('Label'));
        objectNearRow.add(objectNear);

        container.add(objectNearRow);

        // far

        final objectFarRow = new UIRow();
        final objectFar = new UINumber().onChange(update);

        objectFarRow.add(new UIText(strings.getKey('sidebar/object/far')).setClass('Label'));
        objectFarRow.add(objectFar);

        container.add(objectFarRow);

        // intensity

        final objectIntensityRow = new UIRow();
        final objectIntensity = new UINumber().onChange(update);

        objectIntensityRow.add(new UIText(strings.getKey('sidebar/object/intensity')).setClass('Label'));
        objectIntensityRow.add(objectIntensity);

        container.add(objectIntensityRow);

        // color

        final objectColorRow = new UIRow();
        final objectColor = new UIColor().onInput(update);

        objectColorRow.add(new UIText(strings.getKey('sidebar/object/color')).setClass('Label'));
        objectColorRow.add(objectColor);

        container.add(objectColorRow);

        // ground color

        final objectGroundColorRow = new UIRow();
        final objectGroundColor = new UIColor().onInput(update);

        objectGroundColorRow.add(new UIText(strings.getKey('sidebar/object/groundcolor')).setClass('Label'));
        objectGroundColorRow.add(objectGroundColor);

        container.add(objectGroundColorRow);

        // distance

        final objectDistanceRow = new UIRow();
        final objectDistance = new UINumber().setRange(0, Math.POSITIVE_INFINITY).onChange(update);

        objectDistanceRow.add(new UIText(strings.getKey('sidebar/object/distance')).setClass('Label'));
        objectDistanceRow.add(objectDistance);

        container.add(objectDistanceRow);

        // angle

        final objectAngleRow = new UIRow();
        final objectAngle = new UINumber().setPrecision(3).setRange(0, Math.PI / 2).onChange(update);

        objectAngleRow.add(new UIText(strings.getKey('sidebar/object/angle')).setClass('Label'));
        objectAngleRow.add(objectAngle);

        container.add(objectAngleRow);

        // penumbra

        final objectPenumbraRow = new UIRow();
        final objectPenumbra = new UINumber().setRange(0, 1).onChange(update);

        objectPenumbraRow.add(new UIText(strings.getKey('sidebar/object/penumbra')).setClass('Label'));
        objectPenumbraRow.add(objectPenumbra);

        container.add(objectPenumbraRow);

        // decay

        final objectDecayRow = new UIRow();
        final objectDecay = new UINumber().setRange(0, Math.POSITIVE_INFINITY).onChange(update);

        objectDecayRow.add(new UIText(strings.getKey('sidebar/object/decay')).setClass('Label'));
        objectDecayRow.add(objectDecay);

        container.add(objectDecayRow);

        // shadow

        final objectShadowRow = new UIRow();

        objectShadowRow.add(new UIText(strings.getKey('sidebar/object/shadow')).setClass('Label'));

        final objectCastShadow = new UIBoolean(false, strings.getKey('sidebar/object/cast')).onChange(update);
        objectShadowRow.add(objectCastShadow);

        final objectReceiveShadow = new UIBoolean(false, strings.getKey('sidebar/object/receive')).onChange(update);
        objectShadowRow.add(objectReceiveShadow);

        container.add(objectShadowRow);

        // shadow bias

        final objectShadowBiasRow = new UIRow();

        objectShadowBiasRow.add(new UIText(strings.getKey('sidebar/object/shadowBias')).setClass('Label'));

        final objectShadowBias = new UINumber(0).setPrecision(5).setStep(0.0001).setNudge(0.00001).onChange(update);
        objectShadowBiasRow.add(objectShadowBias);

        container.add(objectShadowBiasRow);

        // shadow normal offset

        final objectShadowNormalBiasRow = new UIRow();

        objectShadowNormalBiasRow.add(new UIText(strings.getKey('sidebar/object/shadowNormalBias')).setClass('Label'));

        final objectShadowNormalBias = new UINumber(0).onChange(update);
        objectShadowNormalBiasRow.add(objectShadowNormalBias);

        container.add(objectShadowNormalBiasRow);

        // shadow radius

        final objectShadowRadiusRow = new UIRow();

        objectShadowRadiusRow.add(new UIText(strings.getKey('sidebar/object/shadowRadius')).setClass('Label'));

        final objectShadowRadius = new UINumber(1).onChange(update);
        objectShadowRadiusRow.add(objectShadowRadius);

        container.add(objectShadowRadiusRow);

        // visible

        final objectVisibleRow = new UIRow();
        final objectVisible = new UICheckbox().onChange(update);

        objectVisibleRow.add(new UIText(strings.getKey('sidebar/object/visible')).setClass('Label'));
        objectVisibleRow.add(objectVisible);

        container.add(objectVisibleRow);

        // frustumCulled

        final objectFrustumCulledRow = new UIRow();
        final objectFrustumCulled = new UICheckbox().onChange(update);

        objectFrustumCulledRow.add(new UIText(strings.getKey('sidebar/object/frustumcull')).setClass('Label'));
        objectFrustumCulledRow.add(objectFrustumCulled);

        container.add(objectFrustumCulledRow);

        // renderOrder

        final objectRenderOrderRow = new UIRow();
        final objectRenderOrder = new UIInteger().setWidth('50px').onChange(update);

        objectRenderOrderRow.add(new UIText(strings.getKey('sidebar/object/renderorder')).setClass('Label'));
        objectRenderOrderRow.add(objectRenderOrder);

        container.add(objectRenderOrderRow);

        // user data

        final objectUserDataRow = new UIRow();
        final objectUserData = new UITextArea().setWidth('150px').setHeight('40px').setFontSize('12px').onChange(update);
        objectUserData.onKeyUp(function() {

            try {

                Json.parse(objectUserData.getValue());

                objectUserData.dom.classList.add('success');
                objectUserData.dom.classList.remove('fail');

            } catch (error : Dynamic) {

                objectUserData.dom.classList.remove('success');
                objectUserData.dom.classList.add('fail');

            }

        });

        objectUserDataRow.add(new UIText(strings.getKey('sidebar/object/userdata')).setClass('Label'));
        objectUserDataRow.add(objectUserData);

        container.add(objectUserDataRow);

        // Export JSON

        final exportJson = new UIButton(strings.getKey('sidebar/object/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function() {

            final object = cast(editor.selected, Object3D);

            final output = try Json.stringify(object.toJSON(), null, '\t') catch (e : Dynamic) Json.stringify(object.toJSON());

            editor.utils.save(new Blob([output]), '${if (objectName.getValue() != null) objectName.getValue() else 'object'}.json');

        });
        container.add(exportJson);

        // Animations

        container.add(new SidebarObjectAnimation(editor));

        //

        function update() {

            final object = cast(editor.selected, Object3D);

            if (object != null) {

                final newPosition = new Vector3(objectPositionX.getValue(), objectPositionY.getValue(), objectPositionZ.getValue());
                if (object.position.distanceTo(newPosition) >= 0.01) {

                    editor.execute(new SetPositionCommand(editor, object, newPosition));

                }

                final newRotation = new Euler(objectRotationX.getValue() * MathUtils.DEG2RAD, objectRotationY.getValue() * MathUtils.DEG2RAD, objectRotationZ.getValue() * MathUtils.DEG2RAD);
                if (Vector3.setFromEuler(object.rotation).distanceTo(Vector3.setFromEuler(newRotation)) >= 0.01) {

                    editor.execute(new SetRotationCommand(editor, object, newRotation));

                }

                final newScale = new Vector3(objectScaleX.getValue(), objectScaleY.getValue(), objectScaleZ.getValue());
                if (object.scale.distanceTo(newScale) >= 0.01) {

                    editor.execute(new SetScaleCommand(editor, object, newScale));

                }

                if (Reflect.hasField(object, 'fov') && Math.abs(object.fov - objectFov.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'fov', objectFov.getValue()));
                    object.updateProjectionMatrix();

                }

                if (Reflect.hasField(object, 'left') && Math.abs(object.left - objectLeft.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'left', objectLeft.getValue()));
                    object.updateProjectionMatrix();

                }

                if (Reflect.hasField(object, 'right') && Math.abs(object.right - objectRight.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'right', objectRight.getValue()));
                    object.updateProjectionMatrix();

                }

                if (Reflect.hasField(object, 'top') && Math.abs(object.top - objectTop.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'top', objectTop.getValue()));
                    object.updateProjectionMatrix();

                }

                if (Reflect.hasField(object, 'bottom') && Math.abs(object.bottom - objectBottom.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'bottom', objectBottom.getValue()));
                    object.updateProjectionMatrix();

                }

                if (Reflect.hasField(object, 'near') && Math.abs(object.near - objectNear.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'near', objectNear.getValue()));
                    if (Std.isOfType(object, OrthographicCamera)) {

                        (cast(object, OrthographicCamera)).updateProjectionMatrix();

                    }

                }

                if (Reflect.hasField(object, 'far') && Math.abs(object.far - objectFar.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'far', objectFar.getValue()));
                    if (Std.isOfType(object, OrthographicCamera)) {

                        (cast(object, OrthographicCamera)).updateProjectionMatrix();

                    }

                }

                if (Reflect.hasField(object, 'intensity') && Math.abs(object.intensity - objectIntensity.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'intensity', objectIntensity.getValue()));

                }

                if (Reflect.hasField(object, 'color') && (cast(object.color, Color)).getHex() != objectColor.getHexValue()) {

                    editor.execute(new SetColorCommand(editor, object, 'color', objectColor.getHexValue()));

                }

                if (Reflect.hasField(object, 'groundColor') && (cast(object.groundColor, Color)).getHex() != objectGroundColor.getHexValue()) {

                    editor.execute(new SetColorCommand(editor, object, 'groundColor', objectGroundColor.getHexValue()));

                }

                if (Reflect.hasField(object, 'distance') && Math.abs(object.distance - objectDistance.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'distance', objectDistance.getValue()));

                }

                if (Reflect.hasField(object, 'angle') && Math.abs(object.angle - objectAngle.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'angle', objectAngle.getValue()));

                }

                if (Reflect.hasField(object, 'penumbra') && Math.abs(object.penumbra - objectPenumbra.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'penumbra', objectPenumbra.getValue()));

                }

                if (Reflect.hasField(object, 'decay') && Math.abs(object.decay - objectDecay.getValue()) >= 0.01) {

                    editor.execute(new SetValueCommand(editor, object, 'decay', objectDecay.getValue()));

                }

                if (object.visible != objectVisible.getValue()) {

                    editor.execute(new SetValueCommand(editor, object, 'visible', objectVisible.getValue()));

                }

                if (object.frustumCulled != objectFrustumCulled.getValue()) {

                    editor.execute(new SetValueCommand(editor, object, 'frustumCulled', objectFrustumCulled.getValue()));

                }

                if (object.renderOrder != objectRenderOrder.getValue()) {

                    editor.execute(new SetValueCommand(editor, object, 'renderOrder', objectRenderOrder.getValue()));

                }

                if (Reflect.hasField(object, 'castShadow') && object.castShadow != objectCastShadow.getValue()) {

                    editor.execute(new SetValueCommand(editor, object, 'castShadow', objectCastShadow.getValue()));

                }

                if (Reflect.hasField(object, 'receiveShadow') && object.receiveShadow != objectReceiveShadow.getValue()) {

                    if (object.material != null) {

                        object.material.needsUpdate = true;

                    }
                    editor.execute(new SetValueCommand(editor, object, 'receiveShadow', objectReceiveShadow.getValue()));

                }

                if (Reflect.hasField(object, 'shadow')) {

                    if (object.shadow.bias != objectShadowBias.getValue()) {

                        editor.execute(new SetValueCommand(editor, object.shadow, 'bias', objectShadowBias.getValue()));

                    }

                    if (object.shadow.normalBias != objectShadowNormalBias.getValue()) {

                        editor.execute(new SetValueCommand(editor, object.shadow, 'normalBias', objectShadowNormalBias.getValue()));

                    }

                    if (object.shadow.radius != objectShadowRadius.getValue()) {

                        editor.execute(new SetValueCommand(editor, object.shadow, 'radius', objectShadowRadius.getValue()));

                    }

                }

                try {

                    final userData = Json.parse(objectUserData.getValue());
                    if (Json.stringify(object.userData) != Json.stringify(userData)) {

                        editor.execute(new SetValueCommand(editor, object, 'userData', userData));

                    }

                } catch (exception : Dynamic) {

                    trace('Error updating user data', exception);

                }

            }

        }

        function updateRows(object : Object3D) {

            final properties = {
                'fov': objectFovRow,
                'left': objectLeftRow,
                'right': objectRightRow,
                'top': objectTopRow,
                'bottom': objectBottomRow,
                'near': objectNearRow,
                'far': objectFarRow,
                'intensity': objectIntensityRow,
                'color': objectColorRow,
                'groundColor': objectGroundColorRow,
                'distance': objectDistanceRow,
                'angle': objectAngleRow,
                'penumbra': objectPenumbraRow,
                'decay': objectDecayRow,
                'castShadow': objectShadowRow,
                'receiveShadow': objectReceiveShadow,
                'shadow': [objectShadowBiasRow, objectShadowNormalBiasRow, objectShadowRadiusRow]
            };

            for (property in Reflect.fields(properties)) {

                final uiElement = Reflect.field(properties, property);

                if (Std.isOfType(uiElement, Array)) {

                    for (i in 0...cast(uiElement, Array<Dynamic>).length) {

                        (cast(uiElement, Array<Dynamic>))[i].setDisplay(if (Reflect.hasField(object, property)) '' else 'none');

                    }

                } else {

                    (cast(uiElement, Dynamic)).setDisplay(if (Reflect.hasField(object, property)) '' else 'none');

                }

            }

            //

            if (Std.isOfType(object, Light)) {

                objectReceiveShadow.setDisplay('none');

            }

            if (Std.isOfType(object, AmbientLight) || Std.isOfType(object, HemisphereLight)) {

                objectShadowRow.setDisplay('none');

            }

        }

        function updateTransformRows(object : Object3D) {

            if (Std.isOfType(object, Light) || (Std.isOfType(object, Object3D) && Reflect.hasField(object.userData, 'targetInverse'))) {

                objectRotationRow.setDisplay('none');
                objectScaleRow.setDisplay('none');

            } else {

                objectRotationRow.setDisplay('');
                objectScaleRow.setDisplay('');

            }

        }

        // events

        signals.objectSelected.add(function(object : Object3D) {

            if (object != null) {

                container.setDisplay('block');

                updateRows(object);
                updateUI(object);

            } else {

                container.setDisplay('none');

            }

        });

        signals.objectChanged.add(function(object : Object3D) {

            if (object != editor.selected) {
                return;
            }

            updateUI(object);

        });

        signals.refreshSidebarObject3D.add(function(object : Object3D) {

            if (object != editor.selected) {
                return;
            }

            updateUI(object);

        });

        function updateUI(object : Object3D) {

            objectType.setValue(object.type);

            objectUUID.setValue(object.uuid);
            objectName.setValue(object.name);

            objectPositionX.setValue(object.position.x);
            objectPositionY.setValue(object.position.y);
            objectPositionZ.setValue(object.position.z);

            objectRotationX.setValue(object.rotation.x * MathUtils.RAD2DEG);
            objectRotationY.setValue(object.rotation.y * MathUtils.RAD2DEG);
            objectRotationZ.setValue(object.rotation.z * MathUtils.RAD2DEG);

            objectScaleX.setValue(object.scale.x);
            objectScaleY.setValue(object.scale.y);
            objectScaleZ.setValue(object.scale.z);

            if (Reflect.hasField(object, 'fov')) {

                objectFov.setValue(object.fov);

            }

            if (Reflect.hasField(object, 'left')) {

                objectLeft.setValue(object.left);

            }

            if (Reflect.hasField(object, 'right')) {

                objectRight.setValue(object.right);

            }

            if (Reflect.hasField(object, 'top')) {

                objectTop.setValue(object.top);

            }

            if (Reflect.hasField(object, 'bottom')) {

                objectBottom.setValue(object.bottom);

            }

            if (Reflect.hasField(object, 'near')) {

                objectNear.setValue(object.near);

            }

            if (Reflect.hasField(object, 'far')) {

                objectFar.setValue(object.far);

            }

            if (Reflect.hasField(object, 'intensity')) {

                objectIntensity.setValue(object.intensity);

            }

            if (Reflect.hasField(object, 'color')) {

                objectColor.setHexValue((cast(object.color, Color)).getHexString());

            }

            if (Reflect.hasField(object, 'groundColor')) {

                objectGroundColor.setHexValue((cast(object.groundColor, Color)).getHexString());

            }

            if (Reflect.hasField(object, 'distance')) {

                objectDistance.setValue(object.distance);

            }

            if (Reflect.hasField(object, 'angle')) {

                objectAngle.setValue(object.angle);

            }

            if (Reflect.hasField(object, 'penumbra')) {

                objectPenumbra.setValue(object.penumbra);

            }

            if (Reflect.hasField(object, 'decay')) {

                objectDecay.setValue(object.decay);

            }

            if (Reflect.hasField(object, 'castShadow')) {

                objectCastShadow.setValue(object.castShadow);

            }

            if (Reflect.hasField(object, 'receiveShadow')) {

                objectReceiveShadow.setValue(object.receiveShadow);

            }

            if (Reflect.hasField(object, 'shadow')) {

                objectShadowBias.setValue(object.shadow.bias);
                objectShadowNormalBias.setValue(object.shadow.normalBias);
                objectShadowRadius.setValue(object.shadow.radius);

            }

            objectVisible.setValue(object.visible);
            objectFrustumCulled.setValue(object.frustumCulled);
            objectRenderOrder.setValue(object.renderOrder);

            try {

                objectUserData.setValue(Json.stringify(object.userData, null, '  '));

            } catch (error : Dynamic) {

                trace(error);

            }

            objectUserData.setBorderColor('transparent');
            objectUserData.setBackgroundColor('');

            updateTransformRows(object);

        }

        return container;

    }
}