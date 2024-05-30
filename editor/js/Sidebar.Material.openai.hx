package three.editor.js;

import threeEDITOR.ui.UIButton;
import threeEDITOR.ui.UIInput;
import threeEDITOR.ui.UIPanel;
import threeEDITOR.ui.UIRow;
import threeEDITOR.ui.UISelect;
import threeEDITOR.ui.UIText;
import threeEDITOR.ui.UITextArea;

class SidebarMaterial {
    public var container:UIPanel;
    public var editor:Editor;
    public var strings:Dynamic;
    public var signals:Dynamic;
    public var currentObject:Dynamic;
    public var currentMaterialSlot:Int;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;

        this.currentObject = null;
        this.currentMaterialSlot = 0;

        this.container = new UIPanel();
        this.container.setBorderTop('0');
        this.container.setDisplay('none');
        this.container.setPaddingTop('20px');

        // Current material slot

        var materialSlotRow:UIRow = new UIRow();
        materialSlotRow.add(new UIText(strings.getKey('sidebar/material/slot')).setClass('Label'));
        var materialSlotSelect:UISelect = new UISelect().setWidth('170px').setFontSize('12px').onChange(update);
        materialSlotSelect.setOptions({0:''}).setValue(0);
        materialSlotRow.add(materialSlotSelect);
        this.container.add(materialSlotRow);

        // type

        var materialClassRow:UIRow = new UIRow();
        var materialClass:UISelect = new UISelect().setWidth('150px').setFontSize('12px').onChange(update);
        materialClassRow.add(new UIText(strings.getKey('sidebar/material/type')).setClass('Label'));
        materialClassRow.add(materialClass);
        this.container.add(materialClassRow);

        // uuid

        var materialUUIDRow:UIRow = new UIRow();
        var materialUUID:UIInput = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        var materialUUIDRenew:UIButton = new UIButton(strings.getKey('sidebar/material/new')).setMarginLeft('7px');
        materialUUIDRenew.onClick(function() {
            materialUUID.setValue(THREE.MathUtils.generateUUID());
            update();
        });
        materialUUIDRow.add(new UIText(strings.getKey('sidebar/material/uuid')).setClass('Label'));
        materialUUIDRow.add(materialUUID);
        materialUUIDRow.add(materialUUIDRenew);
        this.container.add(materialUUIDRow);

        // name

        var materialNameRow:UIRow = new UIRow();
        var materialName:UIInput = new UIInput().setWidth('150px').setFontSize('12px').onChange(function() {
            editor.execute(new SetMaterialValueCommand(editor, editor.selected, 'name', materialName.getValue(), currentMaterialSlot));
        });
        materialNameRow.add(new UIText(strings.getKey('sidebar/material/name')).setClass('Label'));
        materialNameRow.add(materialName);
        this.container.add(materialNameRow);

        // program

        var materialProgram:SidebarMaterialProgram = new SidebarMaterialProgram(editor, 'vertexShader');
        this.container.add(materialProgram);

        // color

        var materialColor:SidebarMaterialColorProperty = new SidebarMaterialColorProperty(editor, 'color', strings.getKey('sidebar/material/color'));
        this.container.add(materialColor);

        // specular

        var materialSpecular:SidebarMaterialColorProperty = new SidebarMaterialColorProperty(editor, 'specular', strings.getKey('sidebar/material/specular'));
        this.container.add(materialSpecular);

        // ...

        // Export JSON

        var exportJson:UIButton = new UIButton(strings.getKey('sidebar/material/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function() {
            var object:Dynamic = editor.selected;
            var material:Dynamic = object.material;
            var output:String = material.toJSON();
            try {
                output = JSON.stringify(output, null, '\t');
                output = output.replace(/[\n\t]+([\d\.e\-\[\]]+)/g, '$1');
            } catch (e:Dynamic) {
                output = JSON.stringify(output);
            }
            editor.utils.save(new Blob([output]), '${materialName.getValue() || 'material'}.json');
        });
        this.container.add(exportJson);

        //

        function update() {
            var previousSelectedSlot:Int = currentMaterialSlot;
            currentMaterialSlot = Std.parseInt(materialSlotSelect.getValue());
            if (currentMaterialSlot != previousSelectedSlot) {
                editor.signals.materialChanged.dispatch(currentObject, currentMaterialSlot);
            }
            var material:Dynamic = editor.getObjectMaterial(currentObject, currentMaterialSlot);
            if (material) {
                if (material.uuid != undefined && material.uuid != materialUUID.getValue()) {
                    editor.execute(new SetMaterialValueCommand(editor, currentObject, 'uuid', materialUUID.getValue(), currentMaterialSlot));
                }
                if (material.type != materialClass.getValue()) {
                    material = new materialClasses[materialClass.getValue()]();
                    if (material.type == 'RawShaderMaterial') {
                        material.vertexShader = vertexShaderVariables + material.vertexShader;
                    }
                    if (Array.isArray(currentObject.material)) {
                        // don't remove the entire multi-material. just the material of the selected slot
                        editor.removeMaterial(currentObject.material[currentMaterialSlot]);
                    } else {
                        editor.removeMaterial(currentObject.material);
                    }
                    editor.execute(new SetMaterialCommand(editor, currentObject, material, currentMaterialSlot), strings.getKey('command/SetMaterial') + ': ' + materialClass.getValue());
                    editor.addMaterial(material);
                    // TODO Copy other references in the scene graph
                    // keeping name and UUID then.
                    // Also there should be means to create a unique
                    // copy for the current object explicitly and to
                    // attach the current material to other objects.
                }
                try {
                    var userData:Dynamic = JSON.parse(materialUserData.getValue());
                    if (JSON.stringify(material.userData) != JSON.stringify(userData)) {
                        editor.execute(new SetMaterialValueCommand(editor, currentObject, 'userData', userData, currentMaterialSlot));
                    }
                } catch (exception:Dynamic) {
                    console.warn(exception);
                }
                refreshUI();
            }
        }

        //

        function setRowVisibility() {
            var material:Dynamic = currentObject.material;
            if (Array.isArray(material)) {
                materialSlotRow.setDisplay('');
            } else {
                materialSlotRow.setDisplay('none');
            }
        }

        function refreshUI() {
            if (!currentObject) return;
            var material:Dynamic = currentObject.material;
            if (Array.isArray(material)) {
                var slotOptions:Dynamic = {};
                currentMaterialSlot = Math.max(0, Math.min(material.length, currentMaterialSlot));
                for (i in 0...material.length) {
                    slotOptions[i] = String(i + 1) + ': ' + material[i].name;
                }
                materialSlotSelect.setOptions(slotOptions).setValue(currentMaterialSlot);
            }
            material = editor.getObjectMaterial(currentObject, currentMaterialSlot);
            if (material.uuid != undefined) {
                materialUUID.setValue(material.uuid);
            }
            if (material.name != undefined) {
                materialName.setValue(material.name);
            }
            if (currentObject.isMesh) {
                materialClass.setOptions(meshMaterialOptions);
            } else if (currentObject.isSprite) {
                materialClass.setOptions(spriteMaterialOptions);
            } else if (currentObject.isPoints) {
                materialClass.setOptions(pointsMaterialOptions);
            } else if (currentObject.isLine) {
                materialClass.setOptions(lineMaterialOptions);
            }
            materialClass.setValue(material.type);
            setRowVisibility();
            try {
                materialUserData.setValue(JSON.stringify(material.userData, null, '  '));
            } catch (error:Dynamic) {
                console.log(error);
            }
            materialUserData.setBorderColor('transparent');
            materialUserData.setBackgroundColor('');
        }

        // events

        signals.objectSelected.add(function(object:Dynamic) {
            var hasMaterial:Bool = false;
            if (object && object.material) {
                hasMaterial = true;
                if (Array.isArray(object.material) && object.material.length === 0) {
                    hasMaterial = false;
                }
            }
            if (hasMaterial) {
                currentObject = object;
                refreshUI();
                container.setDisplay('');
            } else {
                currentObject = null;
                container.setDisplay('none');
            }
        });

        signals.materialChanged.add(refreshUI);

        return container;
    }
}

class materialClasses {
    public static var LineBasicMaterial:Dynamic;
    public static var LineDashedMaterial:Dynamic;
    public static var MeshBasicMaterial:Dynamic;
    public static var MeshDepthMaterial:Dynamic;
    public static var MeshNormalMaterial:Dynamic;
    public static var MeshLambertMaterial:Dynamic;
    public static var MeshMatcapMaterial:Dynamic;
    public static var MeshPhongMaterial:Dynamic;
    public static var MeshToonMaterial:Dynamic;
    public static var MeshStandardMaterial:Dynamic;
    public static var MeshPhysicalMaterial:Dynamic;
    public static var RawShaderMaterial:Dynamic;
    public static var ShaderMaterial:Dynamic;
    public static var ShadowMaterial:Dynamic;
    public static var SpriteMaterial:Dynamic;
    public static var PointsMaterial:Dynamic;
}

class vertexShaderVariables {
    public static var variables:Array<String> = [
        'uniform mat4 projectionMatrix;',
        'uniform mat4 modelViewMatrix;',
        'attribute vec3 position;'
    ].join('\n');
}

class meshMaterialOptions {
    public static var options:Dynamic = {
        'MeshBasicMaterial':'MeshBasicMaterial',
        'MeshDepthMaterial':'MeshDepthMaterial',
        'MeshNormalMaterial':'MeshNormalMaterial',
        'MeshLambertMaterial':'MeshLambertMaterial',
        'MeshMatcapMaterial':'MeshMatcapMaterial',
        'MeshPhongMaterial':'MeshPhongMaterial',
        'MeshToonMaterial':'MeshToonMaterial',
        'MeshStandardMaterial':'MeshStandardMaterial',
        'MeshPhysicalMaterial':'MeshPhysicalMaterial',
        'RawShaderMaterial':'RawShaderMaterial',
        'ShaderMaterial':'ShaderMaterial',
        'ShadowMaterial':'ShadowMaterial'
    };
}

class lineMaterialOptions {
    public static var options:Dynamic = {
        'LineBasicMaterial':'LineBasicMaterial',
        'LineDashedMaterial':'LineDashedMaterial',
        'RawShaderMaterial':'RawShaderMaterial',
        'ShaderMaterial':'ShaderMaterial'
    };
}

class spriteMaterialOptions {
    public static var options:Dynamic = {
        'SpriteMaterial':'SpriteMaterial',
        'RawShaderMaterial':'RawShaderMaterial',
        'ShaderMaterial':'ShaderMaterial'
    };
}

class pointsMaterialOptions {
    public static var options:Dynamic = {
        'PointsMaterial':'PointsMaterial',
        'RawShaderMaterial':'RawShaderMaterial',
        'ShaderMaterial':'ShaderMaterial'
    };
}