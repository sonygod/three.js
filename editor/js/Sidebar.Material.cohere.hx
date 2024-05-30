import js.three.*;
import js.threelabs.ui.*;

import SetMaterialCommand from './commands/SetMaterialCommand.hx';
import SetMaterialValueCommand from './commands/SetMaterialValueCommand.hx';

import SidebarMaterialBooleanProperty from './SidebarMaterialBooleanProperty.hx';
import SidebarMaterialColorProperty from './SidebarMaterialColorProperty.hx';
import SidebarMaterialConstantProperty from './SidebarMaterialConstantProperty.hx';
import SidebarMaterialMapProperty from './SidebarMaterialMapProperty.hx';
import SidebarMaterialNumberProperty from './SidebarMaterialNumberProperty.hx';
import SidebarMaterialRangeValueProperty from './SidebarMaterialRangeValueProperty.hx';
import SidebarMaterialProgram from './SidebarMaterialProgram.hx';

class SidebarMaterial {
    public var signals:EditorSignals;
    public var strings:EditorStrings;
    public var currentObject:Dynamic;
    public var currentMaterialSlot:Int;
    public var container:UIPanel;
    public var materialSlotRow:UIRow;
    public var materialSlotSelect:UISelect;
    public var materialClassRow:UIRow;
    public var materialClass:UISelect;
    public var materialUUIDRow:UIRow;
    public var materialUUID:UIInput;
    public var materialUUIDRenew:UIButton;
    public var materialNameRow:UIRow;
    public var materialName:UIInput;
    public var materialProgram:SidebarMaterialProgram;
    public var materialColor:SidebarMaterialColorProperty;
    public var materialSpecular:SidebarMaterialColorProperty;
    public var materialShininess:SidebarMaterialNumberProperty;
    public var materialEmissive:SidebarMaterialColorProperty;
    public var materialReflectivity:SidebarMaterialNumberProperty;
    public var materialIOR:SidebarMaterialNumberProperty;
    public var materialRoughness:SidebarMaterialNumberProperty;
    public var materialMetalness:SidebarMaterialNumberProperty;
    public var materialClearcoat:SidebarMaterialNumberProperty;
    public var materialClearcoatRoughness:SidebarMaterialNumberProperty;
    public var materialDispersion:SidebarMaterialNumberProperty;
    public var materialIridescence:SidebarMaterialNumberProperty;
    public var materialIridescenceIOR:SidebarMaterialNumberProperty;
    public var materialIridescenceThicknessMax:SidebarMaterialRangeValueProperty;
    public var materialSheen:SidebarMaterialNumberProperty;
    public var materialSheenRoughness:SidebarMaterialNumberProperty;
    public var materialSheenColor:SidebarMaterialColorProperty;
    public var materialTransmission:SidebarMaterialNumberProperty;
    public var materialAttenuationDistance:SidebarMaterialNumberProperty;
    public var materialAttenuationColor:SidebarMaterialColorProperty;
    public var materialThickness:SidebarMaterialNumberProperty;
    public var materialVertexColors:SidebarMaterialBooleanProperty;
    public var materialDepthPacking:SidebarMaterialConstantProperty;
    public var materialMap:SidebarMaterialMapProperty;
    public var materialSpecularMap:SidebarMaterialMapProperty;
    public var materialEmissiveMap:SidebarMaterialMapProperty;
    public var materialMatcapMap:SidebarMaterialMapProperty;
    public var materialAlphaMap:SidebarMaterialMapProperty;
    public var materialBumpMap:SidebarMaterialMapProperty;
    public var materialNormalMap:SidebarMaterialMapProperty;
    public var materialClearcoatMap:SidebarMaterialMapProperty;
    public var materialClearcoatNormalMap:SidebarMaterialMapProperty;
    public var materialClearcoatRoughnessMap:SidebarMaterialMapProperty;
    public var materialDisplacementMap:SidebarMaterialMapProperty;
    public var materialRoughnessMap:SidebarMaterialMapProperty;
    public var materialMetalnessMap:SidebarMaterialMapProperty;
    public var materialIridescenceMap:SidebarMaterialMapProperty;
    public var materialSheenColorMap:SidebarMaterialMapProperty;
    public var materialSheenRoughnessMap:SidebarMaterialMapProperty;
    public var materialIridescenceThicknessMap:SidebarMaterialMapProperty;
    public var materialEnvMap:SidebarMaterialMapProperty;
    public var materialLightMap:SidebarMaterialMapProperty;
    public var materialAOMap:SidebarMaterialMapProperty;
    public var materialGradientMap:SidebarMaterialMapProperty;
    public var transmissionMap:SidebarMaterialMapProperty;
    public var thicknessMap:SidebarMaterialMapProperty;
    public var materialSide:SidebarMaterialConstantProperty;
    public var materialSize:SidebarMaterialNumberProperty;
    public var materialSizeAttenuation:SidebarMaterialBooleanProperty;
    public var materialFlatShading:SidebarMaterialBooleanProperty;
    public var materialBlending:SidebarMaterialConstantProperty;
    public var materialOpacity:SidebarMaterialNumberProperty;
    public var materialTransparent:SidebarMaterialBooleanProperty;
    public var materialForceSinglePass:SidebarMaterialBooleanProperty;
    public var materialAlphaTest:SidebarMaterialNumberProperty;
    public var materialDepthTest:SidebarMaterialBooleanProperty;
    public var materialDepthWrite:SidebarMaterialBooleanProperty;
    public var materialWireframe:SidebarMaterialBooleanProperty;
    public var materialUserDataRow:UIRow;
    public var materialUserData:UITextArea;
    public var exportJson:UIButton;

    public function new(editor:Editor) {
        signals = editor.signals;
        strings = editor.strings;

        currentObject = null;
        currentMaterialSlot = 0;

        container = UIPanel_Impl_.fromJS(new js.threelabs.ui.UIPanel());
        container.setBorderTop('0');
        container.setDisplay('none');
        container.setPaddingTop('20px');

        // Current material slot
        materialSlotRow = UIRow_Impl_.fromJS(new js.threelabs.ui.UIRow());
        materialSlotRow.add(UIText_Impl_.fromJS(new js.threelabs.ui.UIText(strings.getKey('sidebar/material/slot'))).setClass('Label'));
        materialSlotSelect = UISelect_Impl_.fromJS(new js.threelabs.ui.UISelect());
        materialSlotSelect.setWidth('170px');
        materialSlotSelect.setFontSize('12px');
        materialSlotSelect.onChange(update_dyn());
        materialSlotSelect.setOptions({0: ''});
        materialSlotSelect.setValue(0);
        materialSlotRow.add(materialSlotSelect);
        container.add(materialSlotRow);

        // type
        materialClassRow = UIRow_Impl_.fromJS(new js.threelabs.ui.UIRow());
        materialClass = UISelect_Impl_.fromJS(new js.threelabs.ui.UISelect());
        materialClass.setWidth('150px');
        materialClass.setFontSize('12px');
        materialClass.onChange(update_dyn());
        materialClassRow.add(UIText_Impl_.fromJS(new js.threelabs.ui.UIText(strings.getKey('sidebar/material/type'))).setClass('Label'));
        materialClassRow.add(materialClass);
        container.add(materialClassRow);

        // uuid
        materialUUIDRow = UIRow_Impl_.fromJS(new js.threelabs.ui.UIRow());
        materialUUID = UIInput_Impl_.fromJS(new js.threelabs.ui.UIInput());
        materialUUID.setWidth('102px');
        materialUUID.setFontSize('12px');
        materialUUID.setDisabled(true);
        materialUUIDRenew = UIButton_Impl_.fromJS(new js.threelabs.ui.UIButton(strings.getKey('sidebar/material/new')));
        materialUUIDRenew.setMarginLeft('7px');
        materialUUIDRenew.onClick(function() {
            materialUUID.setValue(THREE.MathUtils.generateUUID());
            update();
        });
        materialUUIDRow.add(UIText_Impl_.fromJS(new js.threelabs.ui.UIText(strings.getKey('sidebar/material/uuid'))).setClass('Label'));
        materialUUIDRow.add(materialUUID);
        materialUUIDRow.add(materialUUIDRenew);
        container.add(materialUUIDRow);

        // name
        materialNameRow = UIRow_Impl_.fromJS(new js.threelabs.ui.UIRow());
        materialName = UIInput_Impl_.fromJS(new js.threelabs.ui.UIInput());
        materialName.setWidth('150px');
        materialName.setFontSize('12px');
        materialName.onChange(function() {
            editor.execute(SetMaterialValueCommand_Impl_.fromJS(new js.threelabs.commands.SetMaterialValueCommand(editor, editor.selected, 'name', materialName.getValue(), currentMaterialSlot)));
        });
        materialNameRow.add(UIText_Impl_.fromJS(new js.threelabs.ui.UIText(strings.getKey('sidebar/material/name'))).setClass('Label'));
        materialNameRow.add(materialName);
        container.add(materialNameRow);

        // program
        materialProgram = SidebarMaterialProgram_Impl_.fromJS(new js.threelabs.SidebarMaterialProgram(editor, 'vertexShader'));
        container.add(materialProgram);

        // color
        materialColor = SidebarMaterialColorProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialColorProperty(editor, 'color', strings.getKey('sidebar/material/color')));
        container.add(materialColor);

        // specular
        materialSpecular = SidebarMaterialColorProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialColorProperty(editor, 'specular', strings.getKey('sidebar/material/specular')));
        container.add(materialSpecular);

        // shininess
        materialShininess = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'shininess', strings.getKey('sidebar/material/shininess')));
        container.add(materialShininess);

        // emissive
        materialEmissive = SidebarMaterialColorProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialColorProperty(editor, 'emissive', strings.getKey('sidebar/material/emissive')));
        container.add(materialEmissive);

        // reflectivity
        materialReflectivity = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'reflectivity', strings.getKey('sidebar/material/reflectivity')));
        container.add(materialReflectivity);

        // ior
        materialIOR = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'ior', strings.getKey('sidebar/material/ior'), [1, 2.333], 3));
        container.add(materialIOR);

        // roughness
        materialRoughness = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'roughness', strings.getKey('sidebar/material/roughness'), [0, 1]));
        container.add(materialRoughness);

        // metalness
        materialMetalness = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'metalness', strings.getKey('sidebar/material/metalness'), [0, 1]));
        container.add(materialMetalness);

        // clearcoat
        materialClearcoat = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'clearcoat', strings.getKey('sidebar/material/clearcoat'), [0, 1]));
        container.add(materialClearcoat);

        // clearcoatRoughness
        materialClearcoatRoughness = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'clearcoatRoughness', strings.getKey('sidebar/material/clearcoatroughness'), [0, 1]));
        container.add(materialClearcoatRoughness);

        // dispersion
        materialDispersion = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'dispersion', strings.getKey('sidebar/material/dispersion'), [0, 10]));
        container.add(materialDispersion);

        // iridescence
        materialIridescence = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'iridescence', strings.getKey('sidebar/material/iridescence'), [0, 1]));
        container.add(materialIridescence);

        // iridescenceIOR
        materialIridescenceIOR = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'iridescenceIOR', strings.getKey('sidebar/material/iridescenceIOR'), [1, 5]));
        container.add(materialIridescenceIOR);

        // iridescenceThicknessMax
        materialIridescenceThicknessMax = SidebarMaterialRangeValueProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialRangeValueProperty(editor, 'iridescenceThicknessRange', strings.getKey('sidebar/material/iridescenceThicknessMax'), false, [0, Double.POSITIVE_INFINITY], 0, 10, 1, 'nm'));
        container.add(materialIridescenceThicknessMax);

        // sheen
        materialSheen = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'sheen', strings.getKey('sidebar/material/sheen'), [0, 1]));
        container.add(materialSheen);

        // sheen roughness
        materialSheenRoughness = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'sheenRoughness', strings.getKey('sidebar/material/sheenroughness'), [0, 1]));
        container.add(materialSheenRoughness);

        // sheen color
        materialSheenColor = SidebarMaterialColorProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialColorProperty(editor, 'sheenColor', strings.getKey('sidebar/material/sheencolor')));
        container.add(materialSheenColor);

        // transmission
        materialTransmission = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'transmission', strings.getKey('sidebar/material/transmission'), [0, 1]));
        container.add(materialTransmission);

        // attenuation distance
        materialAttenuationDistance = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'attenuationDistance', strings.getKey('sidebar/material/attenuationDistance')));
        container.add(materialAttenuationDistance);

        // attenuation tint
        materialAttenuationColor = SidebarMaterialColorProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialColorProperty(editor, 'attenuationColor', strings.getKey('sidebar/material/attenuationColor')));
        container.add(materialAttenuationColor);

        // thickness
        materialThickness = SidebarMaterialNumberProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialNumberProperty(editor, 'thickness', strings.getKey('sidebar/material/thickness')));
        container.add(materialThickness);

        // vertex colors
        materialVertexColors = SidebarMaterialBooleanProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialBooleanProperty(editor, 'vertexColors', strings.getKey('sidebar/material/vertexcolors')));
        container.add(materialVertexColors);

        // depth packing
        var materialDepthPackingOptions = {
            [THREE.BasicDepthPacking]: 'Basic',
            [THREE.RGBADepthPacking]: 'RGBA'
        };
        materialDepthPacking = SidebarMaterialConstantProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialConstantProperty(editor, 'depthPacking', strings.getKey('sidebar/material/depthPacking'), materialDepthPackingOptions));
        container.add(materialDepthPacking);

        // map
        materialMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'map', strings.getKey('sidebar/material/map')));
        container.add(materialMap);

        // specular map
        materialSpecularMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'specularMap', strings.getKey('sidebar/material/specularmap')));
        container.add(materialSpecularMap);

        // emissive map
        materialEmissiveMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'emissiveMap', strings.getKey('sidebar/material/emissivemap')));
        container.add(materialEmissiveMap);

        // matcap map
        materialMatcapMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'matcap', strings.getKey('sidebar/material/matcap')));
        container.add(materialMatcapMap);

        // alpha map
        materialAlphaMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'alphaMap', strings.getKey('sidebar/material/alphamap')));
        container.add(materialAlphaMap);

        // bump map
        materialBumpMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'bumpMap', strings.getKey('sidebar/material/bumpmap')));
        container.add(materialBumpMap);

        // normal map
        materialNormalMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'normalMap', strings.getKey('sidebar/material/normalmap')));
        container.add(materialNormalMap);

        // clearcoat map
        materialClearcoatMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'clearcoatMap', strings.getKey('sidebar/material/clearcoatmap')));
        container.add(materialClearcoatMap);

        // clearcoat normal map
        materialClearcoatNormalMap = SidebarMaterialMapProperty_Impl_.fromJS(new js.threelabs.SidebarMaterialMapProperty(editor, 'clearcoatNormalMap', strings.