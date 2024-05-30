package three.js.editor.js;

import three.js.Three;
import js.jquery.JQuery;

import ui.UICheckbox;
import ui.UIDiv;
import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import ui.UITexture;
import commands.SetMaterialMapCommand;
import commands.SetMaterialValueCommand;
import commands.SetMaterialRangeCommand;
import commands.SetMaterialVectorCommand;

class SidebarMaterialMapProperty {
    private var editor:Editor;
    private var property:String;
    private var name:String;
    private var container:UIRow;
    private var enabled:UICheckbox;
    private var map:UITexture;
    private var intensity:UINumber;
    private var scale:UINumber;
    private var scaleX:UINumber;
    private var scaleY:UINumber;
    private var rangeMin:UINumber;
    private var rangeMax:UINumber;
    private var object:Dynamic;
    private var materialSlot:Int;
    private var material:Dynamic;

    public function new(editor:Editor, property:String, name:String) {
        this.editor = editor;
        this.property = property;
        this.name = name;

        container = new UIRow();
        container.add(new UIText(name).setClass('Label'));

        enabled = new UICheckbox(false).setMarginRight('8px').onChange(function(_) onChange());
        container.add(enabled);

        map = new UITexture(editor).onChange(function(_) onMapChange());
        container.add(map);

        var mapType:String = property.replace('Map', '');

        if (property == 'aoMap') {
            intensity = new UINumber(1).setWidth('30px').setRange(0, 1).onChange(function(_) onIntensityChange());
            container.add(intensity);
        }

        if (property == 'bumpMap' || property == 'displacementMap') {
            scale = new UINumber().setWidth('30px').onChange(function(_) onScaleChange());
            container.add(scale);
        }

        if (property == 'normalMap' || property == 'clearcoatNormalMap') {
            scaleX = new UINumber().setWidth('30px').onChange(function(_) onScaleXYChange());
            container.add(scaleX);

            scaleY = new UINumber().setWidth('30px').onChange(function(_) onScaleXYChange());
            container.add(scaleY);
        }

        if (property == 'iridescenceThicknessMap') {
            var range:UIDiv = new UIDiv().setMarginLeft('3px');
            container.add(range);

            var rangeMinRow:UIRow = new UIRow().setMarginBottom('0px').setStyle('min-height', '0px');
            range.add(rangeMinRow);

            rangeMinRow.add(new UIText('min:'));

            rangeMin = new UINumber().setWidth('40px').onChange(function(_) onRangeChange());
            rangeMinRow.add(rangeMin);

            var rangeMaxRow:UIRow = new UIRow().setMarginBottom('6px').setStyle('min-height', '0px');
            range.add(rangeMaxRow);

            rangeMaxRow.add(new UIText('max:'));

            rangeMax = new UINumber().setWidth('40px').onChange(function(_) onRangeChange());
            rangeMaxRow.add(rangeMax);

            rangeMin.setPrecision(0).setRange(0, Math.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit('nm');
            rangeMax.setPrecision(0).setRange(0, Math.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit('nm');
        }

        function onChange() {
            var newMap:Dynamic = enabled.getValue() ? map.getValue() : null;

            if (material[property] != newMap) {
                if (newMap != null) {
                    var geometry:Dynamic = object.geometry;

                    if (!geometry.hasAttribute('uv')) {
                        console.warn('Geometry doesn\'t have uvs:', geometry);
                    }

                    if (property == 'envMap') {
                        newMap.mapping = Three.EquirectangularReflectionMapping;
                    }
                }

                editor.execute(new SetMaterialMapCommand(editor, object, property, newMap, materialSlot));
            }
        }

        function onMapChange(texture:Dynamic) {
            if (texture != null) {
                if (colorMaps.indexOf(property) != -1 && !texture.isDataTexture && texture.colorSpace != Three.SRGBColorSpace) {
                    texture.colorSpace = Three.SRGBColorSpace;
                    material.needsUpdate = true;
                }
            }

            enabled.setDisabled(false);

            onChange();
        }

        function onIntensityChange() {
            if (material[property + 'Intensity'] != intensity.getValue()) {
                editor.execute(new SetMaterialValueCommand(editor, object, property + 'Intensity', intensity.getValue(), materialSlot));
            }
        }

        function onScaleChange() {
            if (material[mapType + 'Scale'] != scale.getValue()) {
                editor.execute(new SetMaterialValueCommand(editor, object, mapType + 'Scale', scale.getValue(), materialSlot));
            }
        }

        function onScaleXYChange() {
            var value:Array<Dynamic> = [scaleX.getValue(), scaleY.getValue()];

            if (material[mapType + 'Scale'].x != value[0] || material[mapType + 'Scale'].y != value[1]) {
                editor.execute(new SetMaterialVectorCommand(editor, object, mapType + 'Scale', value, materialSlot));
            }
        }

        function onRangeChange() {
            var value:Array<Dynamic> = [rangeMin.getValue(), rangeMax.getValue()];

            if (material[mapType + 'Range'][0] != value[0] || material[mapType + 'Range'][1] != value[1]) {
                editor.execute(new SetMaterialRangeCommand(editor, object, mapType + 'Range', value[0], value[1], materialSlot));
            }
        }

        function update(currentObject:Dynamic, currentMaterialSlot:Int = 0) {
            object = currentObject;
            materialSlot = currentMaterialSlot;

            if (object == null) return;
            if (object.material == undefined) return;

            material = editor.getObjectMaterial(object, materialSlot);

            if (property in material) {
                if (material[property] != null) {
                    map.setValue(material[property]);
                }

                enabled.setValue(material[property] != null);
                enabled.setDisabled(map.getValue() == null);

                if (intensity != null) {
                    intensity.setValue(material[property + 'Intensity']);
                }

                if (scale != null) {
                    scale.setValue(material[mapType + 'Scale']);
                }

                if (scaleX != null) {
                    scaleX.setValue(material[mapType + 'Scale'].x);
                    scaleY.setValue(material[mapType + 'Scale'].y);
                }

                if (rangeMin != null) {
                    rangeMin.setValue(material[mapType + 'Range'][0]);
                    rangeMax.setValue(material[mapType + 'Range'][1]);
                }

                container.setDisplay('');
            } else {
                container.setDisplay('none');
            }
        }

        jQuery(editor.signals).on('objectSelected', function(selected) {
            map.setValue(null);

            update(selected);
        });

        jQuery(editor.signals).on('materialChanged', update);

        return container;
    }
}