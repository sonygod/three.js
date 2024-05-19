package three.js.editor;

import three.js.Three;

class SidebarMaterial {
    private var editor:Editor;
    private var strings:Strings;
    private var currentObject:Object3D;
    private var currentMaterialSlot:Int = 0;
    private var container:UIPanel;
    private var materialSlotSelect:UISelect;
    private var materialUUID:UIInput;
    private var materialUUIDRenew:UIButton;
    private var materialName:UIInput;
    private var materialClass:UISelect;
    private var materialUserData:UITextArea;
    private var exportJson:UIButton;

    public function new(editor:Editor) {
        this.editor = editor;
        this.strings = editor.strings;
        this.container = new UIPanel();
        this.container.setBorderTop('0');
        this.container.setDisplay('none');
        this.container.setPaddingTop('20px');

        // Current material slot
        var materialSlotRow = new UIRow();
        materialSlotRow.add(new UIText(strings.getKey('sidebar/material/slot')).setClass('Label'));
        materialSlotSelect = new UISelect().setWidth('170px').setFontSize('12px').onChange(update);
        materialSlotSelect.setOptions({ 0: '' }).setValue(0);
        materialSlotRow.add(materialSlotSelect);
        container.add(materialSlotRow);

        // Type
        var materialClassRow = new UIRow();
        materialClassRow.add(new UIText(strings.getKey('sidebar/material/type')).setClass('Label'));
        materialClass = new UISelect().setWidth('150px').setFontSize('12px').onChange(update);
        materialClassRow.add(materialClass);
        container.add(materialClassRow);

        // UUID
        var materialUUIDRow = new UIRow();
        materialUUIDRow.add(new UIText(strings.getKey('sidebar/material/uuid')).setClass('Label'));
        materialUUID = new UIInput().setWidth('102px').setFontSize('12px').setDisabled(true);
        materialUUIDRenew = new UIButton(strings.getKey('sidebar/material/new')).setMarginLeft('7px');
        materialUUIDRenew.onClick(function() {
            materialUUID.setValue(Three.MathUtils.generateUUID());
            update();
        });
        materialUUIDRow.add(materialUUID);
        materialUUIDRow.add(materialUUIDRenew);
        container.add(materialUUIDRow);

        // Name
        var materialNameRow = new UIRow();
        materialNameRow.add(new UIText(strings.getKey('sidebar/material/name')).setClass('Label'));
        materialName = new UIInput().setWidth('150px').setFontSize('12px').onChange(function() {
            editor.execute(new SetMaterialValueCommand(editor, editor.selected, 'name', materialName.getValue(), currentMaterialSlot));
        });
        materialNameRow.add(materialName);
        container.add(materialNameRow);

        // Program
        var materialProgram = new SidebarMaterialProgram(editor, 'vertexShader');
        container.add(materialProgram);

        // Color
        var materialColor = new SidebarMaterialColorProperty(editor, 'color', strings.getKey('sidebar/material/color'));
        container.add(materialColor);

        // ... (rest of the properties)

        // Export JSON
        exportJson = new UIButton(strings.getKey('sidebar/material/export'));
        exportJson.setMarginLeft('120px');
        exportJson.onClick(function() {
            var object = editor.selected;
            var material = object.material;

            var output = material.toJSON();

            try {
                output = Json.stringify(output, null, '\t');
                output = output.replace(/[\n\t]+([\d\.e\-\[\]]+)/g, '$1');
            } catch (e) {
                output = Json.stringify(output);
            }

            editor.utils.save(new Blob([output]), '${materialName.getValue() || 'material'}.json');
        });
        container.add(exportJson);

        update = function() {
            var previousSelectedSlot = currentMaterialSlot;

            currentMaterialSlot = Std.parseInt(materialSlotSelect.getValue());

            if (currentMaterialSlot != previousSelectedSlot) {
                editor.signals.materialChanged.dispatch(currentObject, currentMaterialSlot);
            }

            var material = editor.getObjectMaterial(currentObject, currentMaterialSlot);

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
                        editor.removeMaterial(currentObject.material[currentMaterialSlot]);
                    } else {
                        editor.removeMaterial(currentObject.material);
                    }

                    editor.execute(new SetMaterialCommand(editor, currentObject, material, currentMaterialSlot), strings.getKey('command/SetMaterial') + ': ' + materialClass.getValue());
                    editor.addMaterial(material);
                }

                try {
                    var userData = Json.parse(materialUserData.getValue());
                    if (Json.stringify(material.userData) != Json.stringify(userData)) {
                        editor.execute(new SetMaterialValueCommand(editor, currentObject, 'userData', userData, currentMaterialSlot));
                    }
                } catch (exception) {
                    console.warn(exception);
                }

                refreshUI();
            }
        };

        setRowVisibility = function() {
            var material = currentObject.material;

            if (Array.isArray(material)) {
                materialSlotRow.setDisplay('');
            } else {
                materialSlotRow.setDisplay('none');
            }
        };

        refreshUI = function() {
            if (!currentObject) return;

            var material = currentObject.material;

            if (Array.isArray(material)) {
                var slotOptions = {};

                currentMaterialSlot = Math.max(0, Math.min(material.length, currentMaterialSlot));

                for (i in 0...material.length) {
                    slotOptions[i] = Std.string(i + 1) + ': ' + material[i].name;
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
                materialUserData.setValue(Json.stringify(material.userData, null, '  '));
            } catch (error) {
                console.log(error);
            }

            materialUserData.setBorderColor('transparent');
            materialUserData.setBackgroundColor('');
        };

        editor.signals.objectSelected.add(function(object:Object3D) {
            var hasMaterial = false;

            if (object && object.material) {
                hasMaterial = true;

                if (Array.isArray(object.material) && object.material.length == 0) {
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

        editor.signals.materialChanged.add(refreshUI);
    }
}

// Material classes
private var materialClasses:Map<String, Class<Material>> = [
    'LineBasicMaterial' => Three.LineBasicMaterial,
    'LineDashedMaterial' => Three.LineDashedMaterial,
    'MeshBasicMaterial' => Three.MeshBasicMaterial,
    'MeshDepthMaterial' => Three.MeshDepthMaterial,
    'MeshNormalMaterial' => Three.MeshNormalMaterial,
    'MeshLambertMaterial' => Three.MeshLambertMaterial,
    'MeshMatcapMaterial' => Three.MeshMatcapMaterial,
    'MeshPhongMaterial' => Three.MeshPhongMaterial,
    'MeshToonMaterial' => Three.MeshToonMaterial,
    'MeshStandardMaterial' => Three.MeshStandardMaterial,
    'MeshPhysicalMaterial' => Three.MeshPhysicalMaterial,
    'RawShaderMaterial' => Three.RawShaderMaterial,
    'ShaderMaterial' => Three.ShaderMaterial,
    'ShadowMaterial' => Three.ShadowMaterial,
    'SpriteMaterial' => Three.SpriteMaterial,
    'PointsMaterial' => Three.PointsMaterial
];

private var vertexShaderVariables:Array<String> = [
    'uniform mat4 projectionMatrix;',
    'uniform mat4 modelViewMatrix;',
    'attribute vec3 position;'
].join('\n');

private var meshMaterialOptions:Map<String, String> = [
    'MeshBasicMaterial' => 'MeshBasicMaterial',
    'MeshDepthMaterial' => 'MeshDepthMaterial',
    'MeshNormalMaterial' => 'MeshNormalMaterial',
    'MeshLambertMaterial' => 'MeshLambertMaterial',
    'MeshMatcapMaterial' => 'MeshMatcapMaterial',
    'MeshPhongMaterial' => 'MeshPhongMaterial',
    'MeshToonMaterial' => 'MeshToonMaterial',
    'MeshStandardMaterial' => 'MeshStandardMaterial',
    'MeshPhysicalMaterial' => 'MeshPhysicalMaterial',
    'RawShaderMaterial' => 'RawShaderMaterial',
    'ShaderMaterial' => 'ShaderMaterial',
    'ShadowMaterial' => 'ShadowMaterial'
];

private var lineMaterialOptions:Map<String, String> = [
    'LineBasicMaterial' => 'LineBasicMaterial',
    'LineDashedMaterial' => 'LineDashedMaterial',
    'RawShaderMaterial' => 'RawShaderMaterial',
    'ShaderMaterial' => 'ShaderMaterial'
];

private var spriteMaterialOptions:Map<String, String> = [
    'SpriteMaterial' => 'SpriteMaterial',
    'RawShaderMaterial' => 'RawShaderMaterial',
    'ShaderMaterial' => 'ShaderMaterial'
];

private var pointsMaterialOptions:Map<String, String> = [
    'PointsMaterial' => 'PointsMaterial',
    'RawShaderMaterial' => 'RawShaderMaterial',
    'ShaderMaterial' => 'ShaderMaterial'
];