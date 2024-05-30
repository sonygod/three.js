import js.three.MathUtils;
import js.three.Vector3;
import js.three.Euler;

import js.ui.UIPanel;
import js.ui.UIRow;
import js.ui.UIInput;
import js.ui.UIButton;
import js.ui.UIColor;
import js.ui.UICheckbox;
import js.ui.UIInteger;
import js.ui.UITextArea;
import js.ui.UIText;
import js.ui.UINumber;

import js.ui.three.UIBoolean;

import js.commands.SetUuidCommand;
import js.commands.SetValueCommand;
import js.commands.SetPositionCommand;
import js.commands.SetRotationCommand;
import js.commands.SetScaleCommand;
import js.commands.SetColorCommand;

import js.Sidebar.Object.Animation.SidebarObjectAnimation;

class SidebarObject {
    public function new(editor:Editor) {
        var strings = editor.strings;
        var signals = editor.signals;
        var container = UIPanel();
        container.setBorderTop('0');
        container.setPaddingTop('20px');
        container.setDisplay('none');

        // Actions

        /*
        let objectActions = new UI.Select().setPosition('absolute').setRight('8px').setFontSize('11px');
        objectActions.setOptions({
            'Actions': 'Actions',
            'Reset Position': 'Reset Position',
            'Reset Rotation': 'Reset Rotation',
            'Reset Scale': 'Reset Scale'
        });
        objectActions.onClick(function(event) {
            event.stopPropagation(); // Avoid panel collapsing
        });
        objectActions.onChange(function(event) {
            let object = editor.selected;
            switch (this.getValue()) {
                case 'Reset Position':
                    editor.execute(new SetPositionCommand(editor, object, new Vector3(0, 0, 0)));
                    break;
                case 'Reset Rotation':
                    editor.execute(new SetRotationCommand(editor, object, new Euler(0, 0, 0)));
                    break;
                case 'Reset Scale':
                    editor.execute(new SetScaleCommand(editor, object, new Vector3(1, 1, 1)));
                    break;
            }
            this.setValue('Actions');
        });
        container.addStatic(objectActions);
        */

        // type

        var objectTypeRow = UIRow();
        var objectType = UIText();

        objectTypeRow.add(new UIText(strings.getKey('sidebar/object/type')).setClass('Label'));
        objectTypeRow.add(objectType);

        container.add(objectTypeRow);

        // uuid

        var objectUUIDRow = UIRow();
        var objectUUID = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var objectUUIDRenew = new UIButton(strings.getKey('sidebar/object/new')).setMarginLeft('7px').onClick(function() {
            objectUUID.setValue(MathUtils.generateUUID());
            editor.execute(new SetUuidCommand(editor, editor.selected, objectUUID.getValue()));
        });

        objectUUIDRow.add(new UIText(strings.getKey('sidebar/object/uuid')).setClass('Label'));
        objectUUIDRow.add(objectUUID);
        objectUUIDRow.add(objectUUIDRenew);

        container.add(objectUUIDRow);

        // name

        var objectNameRow = UIRow();
        var objectName = new UIInput().setWidth('150px').setFontSize('12px').onChange(function() {
            editor.execute(new SetValueCommand(editor, editor.selected, 'name', objectName.getValue()));
        });

        objectNameRow.add(new UIText(strings.getKey('sidebar/object/name')).setClass('Label'));
        objectNameRow.add(objectName);

        container.add(objectNameRow);

        // position

        var objectPositionRow = UIRow();
        var objectPositionX = new UINumber().setPrecision(3).setWidth('50px').onChange(update);
        var objectPositionY = new UINumber().setPrecision(3).setWidth('50px').onChange(update);
        var objectPositionZ = new UINumber().setPrecision(3).setWidth('50px').onChange(update);

        objectPositionRow.add(new UIText(strings.getKey('sidebar/object/position')).setClass('Label'));
        objectPositionRow.add(objectPositionX, objectPositionY, objectPositionZ);

        container.add(objectPositionRow);

        // rotation

        var objectRotationRow = UIRow();
        var objectRotationX = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);
        var objectRotationY = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);
        var objectRotationZ = new UINumber().setStep(10).setNudge(0.1).setUnit('°').setWidth('50px').onChange(update);

        objectRotationRow.add(new UIText(strings.getKey('sidebar/object/rotation')).setClass('Label'));
        objectRotationRow.add(objectRotationX, objectRotationY, objectRotationZ);

        container.add(objectRotationRow);

        // scale

        var objectScaleRow = UIRow();
        var objectScaleX = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);
        var objectScaleY = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);
        var objectScaleZ = new UINumber(1).setPrecision(3).setWidth('50px').onChange(update);

        objectScaleRow.add(new UIText(strings.getKey('sidebar/object/scale')).setClass('Label'));
        objectScaleRow.add(objectScaleX, objectScaleY, objectScaleZ);

        container.add(objectScaleRow);

        // fov

        var objectFovRow = UIRow();
        var objectFov = new UINumber().onChange(update);

        objectFovRow.add(new UIText(strings.getKey('sidebar/object/fov')).setClass('Label'));
        objectFovRow.add(objectFov);

        container.add(objectFovRow);

        // left

        var objectLeftRow = UIRow();
        var objectLeft = new UINumber().onChange(update);

        objectLeftRow.add(new UIText(strings.getKey('sidebar/object/left')).setClass('Label'));
        objectLeftRow.add(objectLeft);

        container.add(objectLeftRow);

        // right

        var objectRightRow = UIRow();
        var objectRight = new UINumber().onChange(update);

        objectRightRow.add(new UIText(strings.getKey('sidebar/object/right')).setClass('Label'));
        objectRightRow.add(objectRight);

        container.add(objectRightRow);

        // top

        var objectTopRow = UIRow();
        var objectTop = new UINumber().onChange(update);

        objectTopRow.add(new UIText(strings.getKey('sidebar/object/top')).setClass('Label'));
        objectTopRow.add(objectTop);

        container.add(objectTopRow);

        // bottom

        var objectBottomRow = UIRow();
        var objectBottom = new UINumber().onChange(update);

        objectBottomRow.add(new UIText(strings.getKey('sidebar/object/bottom')).setClass('Label'));
        objectBottomRow.add(objectBottom);

        container.add(objectBottomRow);

        // near

        var objectNearRow = UIRow();
        var objectNear = new UINumber().onChange(update);

        objectNearRow.add(new UIText(strings.getKey('sidebar/object/near')).setClass('Label'));
        objectNearRow.add(objectNear);

        container.add(objectNearRow);

        // far

        var objectFarRow = UIRow();
        var objectFar = new UINumber().onChange(update);

        objectFarRow.add(new UIText(strings.getKey('sidebar/object/far')).setClass('Label'));
        objectFarRow.add(objectFar);

        container.add(objectFarRow);

        // intensity

        var objectIntensityRow = UIRow();
        var objectIntensity = new UINumber().onChange(update);

        objectIntensityRow.add(new UIText(strings.getKey('sidebar/object/intensity')).setClass('Label'));
        objectIntensityRow.add(objectIntensity);

        container.add(objectIntensityRow);

        // color

        var objectColorRow = UIRow();
        var objectColor = new UIColor().onInput(update);

        objectColorRow.add(new UIText(strings.getKey('sidebar/object/color')).setClass('Label'));
        objectColorRow.add(objectColor);

        container.add(objectColorRow);

        // ground color

        var objectGroundColorRow = UIRow();
        var objectGroundColor = new UIColor().onInput(update);

        objectGroundColorRow.add(new UIText(strings.getKey('sidebar/object/groundcolor')).setClass('Label'));
        objectGroundColorRow.add(objectGroundColor);

        container.add(objectGroundColorRow);

        // distance

        var objectDistanceRow = UIRow();
        var objectDistance = new UINumber().setRange(0, Math.PosInfinity).onChange(update);

        objectDistanceRow.add(new UIText(strings.getKey('sidebar/object/distance')).setClass('Label'));
        objectDistanceRow.add(objectDistance);

        container.add(objectDistanceRow);

        // angle

        var objectAngleRow = UIRow();
        var objectAngle = new UINumber().setPrecision(3).setRange(0, Math.PI / 2).onChange(update);

        objectAngleRow.add(new UIText(strings.getKey('sidebar/object/angle')).setClass('Label'));
        objectAngleRow.add(objectAngle);

        container.add(objectAngleRow);

        // penumbra

        var objectPenumbraRow = UIRow();
        var objectPenumbra = new UINumber().setRange(0, 1).onChange(update);

        objectPenumbraRow.add(new UIText(strings.getKey('sidebar/object/penumbra')).setClass('Label'));
        objectPenumbraRow.add(objectPenumbra);

        container.add(objectPenumbraRow);

        // decay

        var objectDecayRow = UIRow();
        var objectDecay = new UINumber().setRange(0, Math.PosInfinity).onChange(update);

        objectDecayRow.add(new UIText(strings.getKey('sidebar/object/decay')).setClass('Label'));
        objectDecayRow.add(objectDecay);

        container.add(objectDecayRow);

        // shadow

        var objectShadowRow = UIRow();

        objectShadowRow.add(new UIText(strings.getKey('sidebar/object/shadow')).setClass('Label'));

        var objectCastShadow = new UIBoolean(false, strings.getKey('sidebar/object/cast')).onChange(update);
        objectShadowRow.add(objectCastShadow);

        var objectReceiveShadow = new UIBoolean(false, strings.getKey('sidebar/object/receive')).onChange(update);
        objectShadowRow.add(objectReceiveShadow);

        container.add(objectShadowRow);

        // shadow bias

        var objectShadowBiasRow = UIRow();

        objectShadowBiasRow.add(new UIText(strings.getKey('sidebar/object/shadowBias')).setClass('Label'));

        var objectShadowBias = new UINumber(0).setPrecision(5).setStep(0.0001).setNudge(0.00001).onChange(update);
        objectShadowBiasRow.add(objectShadowBias);

        container.add(objectShadowBiasRow);

        // shadow normal offset

        var objectShadowNormalBiasRow = UIRow();

        objectShadowNormalBiasRow.add(new UIText(strings.getKey('sidebar/object/shadowNormalBias')).setClass('Label'));

        var objectShadowNormalBias = new UINumber(0).onChange(update);
        objectShadowNormalBiasRow.add(objectShadowNormalBias);

        container.add(objectShadowNormalBiasRow);

        // shadow radius

        var objectShadowRadiusRow = UIRow();

        objectShadowRadiusRow.add(new UIText(strings.getKey('sidebar/object/shadowRadius')).setClass('Label'));

        var objectShadowRadius = new UINumber(1).onChange(update);
        objectShadowRadiusRow.add(objectShadowRadius);

        container.add(objectShadowRadiusRow);

        // visible

        var objectVisibleRow = UIRow();
        var objectVisible = new UICheckbox().onChange(update);

        objectVisibleRow.add(new UIText(strings.getKey('sidebar/object/visible')).setClass('Label'));
        objectVisibleRow.add(objectVisible);

        container.add(objectVisibleRow);

        // frustumCulled

        var objectFrustumCulledRow = UIRow();
        var objectFrustumCulled = new UICheckbox().onChange(update);

        objectFrustumCulledRow.add(new UIText(strings.getKey('sidebar/object/frustumcull')).setClass('Label'));
        objectFrustumCulledRow.add(objectFrustumCulled);

        container.add(objectFrustumCulledRow);

        // renderOrder

        var objectRenderOrderRow = UIRow();
        var objectRenderOrder = new UIInteger().setWidth('50px').onChange(update);

        objectRenderOrderRow.add(new UIText(strings.getKey('sidebar/object/renderorder')).setClass('Label'));
        objectRenderOrderRow.add(objectRenderOrder);

        container.add(objectRenderOrderRow);

        // user data

        var objectUserDataRow = UIRow();
        var objectUserData = new UITextArea().setWidth('150px').setHeight('40px').setFontSize('12px').onChange(update);
        objectUserData.onKeyUp(function() {
            try {
                JSON.parse(objectUserData.getValue());
                objectUserData.dom.classList.add('success');
                objectUserData.dom.classList.remove('fail');
            } catch (error) {
                objectUserData.dom.classList.remove('success');
                objectUserData.dom.classList.add('fail');
            }
        });

        objectUserDataRow.add(new UIText(strings.getKey('sidebar/object/userdata')).setClass('Label'));
        objectUserDataRow.add(objectUserData);

        container.add(objectUserDataRow);

        // Export JSON

        var exportJson = new UIButton(strings.getKey('sidebar/object/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function() {
            let object = editor.selected;
            let output = object.toJSON();
            try {
                output = JSON.stringify(output, null, '\t');
                output = output.replace(/[\n\t]+([\d\.e\-\[\]]+)/g, '$1');
            } catch (e) {
                output = JSON.stringify(output);
            }
            editor.utils.save(new Blob([output]), `${objectName.getValue() || 'object'}.json`);
        });
        container.add(exportJson);

        // Animations

        container.add(new SidebarObjectAnimation(editor));

        //

        function update() {
            let object = editor.selected;
            if (object != null) {
                let newPosition = new Vector3(objectPositionX.getValue(), objectPositionY.getValue(), objectPositionZ.getValue());
                if (object.position.distanceTo(newPosition) >= 0.01) {
                    editor.execute(new SetPositionCommand(editor, object, newPosition));
                }
                let newRotation = new Euler(objectRotationX.getValue() * MathUtils.DEG2RAD, objectRotationY.getValue() * MathUtils.DEG2RAD, objectRotationZ.getValue() * MathUtils.DEG2RAD);
                if (new Vector3().setFromEuler(object.rotation).distanceTo(new Vector3().setFromEuler(newRotation)) >= 0.01) {
                    editor.execute(new SetRotationCommand(editor, object, newRotation));
                }
                let newScale = new Vector3(objectScaleX.getValue(), objectScaleY.getValue(), objectScaleZ.getValue());
                if (object.scale.distanceTo(newScale) >= 0.01) {
                    editor.execute(new SetScaleCommand(editor, object, newScale));
                }
                if (object.fov != null && Math.abs(object.fov - objectFov.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'fov', objectFov.getValue()));
                    object.updateProjectionMatrix();
                }
                if (object.left != null && Math.abs(object.left - objectLeft.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'left', objectLeft.getValue()));
                    object.updateProjectionMatrix();
                }
                if (object.right != null && Math.abs(object.right - objectRight.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'right', objectRight.getValue()));
                    object.updateProjectionMatrix();
                }
                if (object.top != null && Math.abs(object.top - objectTop.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'top', objectTop.getValue()));
                    object.updateProjectionMatrix();
                }
                if (object.bottom != null && Math.abs(object.bottom - objectBottom.getValue()) >= 0.01)
{
                    editor.execute(new SetValueCommand(editor, object, 'bottom', objectBottom.getValue()));
                    object.updateProjectionMatrix();
                }
                if (object.near != null && Math.abs(object.near - objectNear.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'near', objectNear.getValue()));
                    if (object.isOrthographicCamera) {
                        object.updateProjectionMatrix();
                    }
                }
                if (object.far != null && Math.abs(object.far - objectFar.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'far', objectFar.getValue()));
                    if (object.isOrthographicCamera) {
                        object.updateProjectionMatrix();
                    }
                }
                if (object.intensity != null && Math.abs(object.intensity - objectIntensity.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'intensity', objectIntensity.getValue()));
                }
                if (object.color != null && object.color.getHex() != objectColor.getHexValue()) {
                    editor.execute(new SetColorCommand(editor, object, 'color', objectColor.getHexValue()));
                }
                if (object.groundColor != null && object.groundColor.getHex() != objectGroundColor.getHexValue()) {
                    editor.execute(new SetColorCommand(editor, object, 'groundColor', objectGroundColor.getHexValue()));
                }
                if (object.distance != null && Math.abs(object.distance - objectDistance.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'distance', objectDistance.getValue()));
                }
                if (object.angle != null && Math.abs(object.angle - objectAngle.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'angle', objectAngle.getValue()));
                }
                if (object.penumbra != null && Math.abs(object.penumbra - objectPenumbra.getValue()) >= 0.01) {
                    editor.execute(new SetValueCommand(editor, object, 'penumbra', objectPenumbra.getValue()));
                }
                if (object.decay != null && Math.abs(object.decay - objectDecay.getValue()) >= 0.01) {
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
                if (object.castShadow != null && object.castShadow != objectCastShadow.getValue()) {
                    editor.execute(new SetValueCommand(editor, object, 'castShadow', objectCastShadow.getValue()));
                }
                if (object.receiveShadow != objectReceiveShadow.getValue()) {
                    if (object.material != null) object.material.needsUpdate = true;
                    editor.execute(new SetValueCommand(editor, object, 'receiveShadow', objectReceiveShadow.getValue()));
                }
                if (object.shadow != null) {
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
                    let userData = JSON.parse(objectUserData.getValue());
                    if (JSON.stringify(object.userData) != JSON.stringify(userData)) {
                        editor.execute(new SetValueCommand(editor, object, 'userData', userData));
                    }
                } catch (exception) {
                    trace(exception);
                }
            }
        }

        function updateRows(object:Dynamic) {
            let properties = {
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
            for (property in properties) {
                let uiElement = properties[property];
                if (Type.isArray(uiElement)) {
                    for (i in 0...uiElement.length) {
                        uiElement[i].setDisplay(object[property] != null ? '' : 'none');
                    }
                } else {
                    uiElement.setDisplay(object[property] != null ? '' : 'none');
                }
            }
            if (object.isLight) {
                objectReceiveShadow.setDisplay('none');
            }
            if (object.isAmbientLight || object.isHemisphereLight) {
                objectShadowRow.setDisplay('none');
            }
        }

        function updateTransformRows(object:Dynamic) {
            if (object.isLight || (object.isObject3D && object.userData.targetInverse)) {
                objectRotationRow.setDisplay('none');
                objectScaleRow.setDisplay('none');
            } else {
                objectRotationRow.setDisplay('');
                objectScaleRow.setDisplay('');
            }
        }

        // events

        signals.objectSelected.add(function(object:Dynamic) {
            if (object != null) {
                container.setDisplay('block');
                updateRows(object);
                updateUI(object);
            } else {
                container.setDisplay('none');
            }
        });

        signals.objectChanged.add(function(object:Dynamic) {
            if (object != editor.selected) return;
            updateUI(object);
        });

        signals.refreshSidebarObject3D.add(function(object:Dynamic) {
            if (object != editor.selected) return;
            updateUI(object);
        });

        function updateUI(object:Dynamic) {
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
            if (object.fov != null) {
                objectFov.setValue(object.fov);
            }
            if (object.left != null) {
                objectLeft.setValue(object.left);
            }
            if (object.right != null) {
                objectRight.setValue(object.right);
            }
            if (object.top != null) {
                objectTop.setValue(object.top);
            }
            if (object.bottom != null) {
                objectBottom.setValue(object.bottom);
            }
            if (object.near != null) {
                objectNear.setValue(object.near);
            }
            if (object.far != null) {
                objectFar.setValue(object.far);
            }
            if (object.intensity != null) {
                objectIntensity.setValue(object.intensity);
            }
            if (object.color != null) {
                objectColor.setHexValue(object.color.getHexString());
            }
            if (object.groundColor != null) {
                objectGroundColor.setHexValue(object.groundColor.getHexString());
            }
            if (object.distance != null) {
                objectDistance.setValue(object.distance);
            }
            if (object.angle != null) {
                objectAngle.setValue(object.angle);
            }
            if (object.penumbra != null) {
                objectPenumbra.setValue(object.penumbra);
            }
            if (object.decay != null) {
                objectDecay.setValue(object.decay);
            }
            if (object.castShadow != null) {
                objectCastShadow.setValue(object.castShadow);
            }
            if (object.receiveShadow != null) {
                objectReceiveShadow.setValue(object.receiveShadow);
            }
            if (object.shadow != null) {
                objectShadowBias.setValue(object.shadow.bias);
                objectShadowNormalBias.setValue(object.shadow.normalBias);
                objectShadowRadius.setValue(object.shadow.radius);
            }
            objectVisible.setValue(object.visible);
            objectFrustumCulled.setValue(object.frustumCulled);
            objectRenderOrder.setValue(object.renderOrder);
            try {
                objectUserData.setValue(JSON.stringify(object.userData, null, '  '));
            } catch (error) {
                trace(error);
            }
            objectUserData.setBorderColor('transparent');
            objectUserData.setBackgroundColor('');
            updateTransformRows(object);
        }

        return container;
    }
}