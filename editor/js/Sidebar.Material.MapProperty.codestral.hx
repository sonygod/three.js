import three.THREE;
import ui.UI;
import ui.three.UIThree;
import commands.SetMaterialMapCommand;
import commands.SetMaterialValueCommand;
import commands.SetMaterialRangeCommand;
import commands.SetMaterialVectorCommand;

class SidebarMaterialMapProperty {

    private var editor: dynamic;
    private var signals: dynamic;
    private var container: UI.UIRow;
    private var enabled: UI.UICheckbox;
    private var map: UIThree.UITexture;
    private var mapType: String;
    private var colorMaps: Array<String>;
    private var intensity: Null<UI.UINumber>;
    private var scale: Null<UI.UINumber>;
    private var scaleX: Null<UI.UINumber>;
    private var scaleY: Null<UI.UINumber>;
    private var rangeMin: Null<UI.UINumber>;
    private var rangeMax: Null<UI.UINumber>;
    private var object: Null<dynamic>;
    private var materialSlot: Int;
    private var material: Null<dynamic>;

    public function new(editor: dynamic, property: String, name: String) {
        this.editor = editor;
        this.signals = editor.signals;

        this.container = new UI.UIRow();
        this.container.add(new UI.UIText(name).setClass('Label'));

        this.enabled = new UI.UICheckbox(false).setMarginRight('8px').onChange(this.onChange.bind(this));
        this.container.add(this.enabled);

        this.map = new UIThree.UITexture(editor).onChange(this.onMapChange.bind(this));
        this.container.add(this.map);

        this.mapType = property.replace('Map', '');

        this.colorMaps = ['map', 'emissiveMap', 'sheenColorMap', 'specularColorMap', 'envMap'];

        if (property === 'aoMap') {
            this.intensity = new UI.UINumber(1).setWidth('30px').setRange(0, 1).onChange(this.onIntensityChange.bind(this));
            this.container.add(this.intensity);
        }

        if (property === 'bumpMap' || property === 'displacementMap') {
            this.scale = new UI.UINumber().setWidth('30px').onChange(this.onScaleChange.bind(this));
            this.container.add(this.scale);
        }

        if (property === 'normalMap' || property === 'clearcoatNormalMap') {
            this.scaleX = new UI.UINumber().setWidth('30px').onChange(this.onScaleXYChange.bind(this));
            this.container.add(this.scaleX);

            this.scaleY = new UI.UINumber().setWidth('30px').onChange(this.onScaleXYChange.bind(this));
            this.container.add(this.scaleY);
        }

        if (property === 'iridescenceThicknessMap') {
            var range = new UI.UIDiv().setMarginLeft('3px');
            this.container.add(range);

            var rangeMinRow = new UI.UIRow().setMarginBottom('0px').setStyle('min-height', '0px');
            range.add(rangeMinRow);

            rangeMinRow.add(new UI.UIText('min:').setWidth('35px'));

            this.rangeMin = new UI.UINumber().setWidth('40px').onChange(this.onRangeChange.bind(this));
            rangeMinRow.add(this.rangeMin);

            var rangeMaxRow = new UI.UIRow().setMarginBottom('6px').setStyle('min-height', '0px');
            range.add(rangeMaxRow);

            rangeMaxRow.add(new UI.UIText('max:').setWidth('35px'));

            this.rangeMax = new UI.UINumber().setWidth('40px').onChange(this.onRangeChange.bind(this));
            rangeMaxRow.add(this.rangeMax);

            // Additional settings for iridescenceThicknessMap
            this.rangeMin.setPrecision(0).setRange(0, Float.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit('nm');
            this.rangeMax.setPrecision(0).setRange(0, Float.POSITIVE_INFINITY).setNudge(1).setStep(10).setUnit('nm');
        }

        this.object = null;
        this.materialSlot = 0;
        this.material = null;

        this.signals.objectSelected.add(function(selected) {
            this.map.setValue(null);
            this.update(selected);
        }.bind(this));

        this.signals.materialChanged.add(this.update.bind(this));
    }

    private function onChange() {
        var newMap = this.enabled.getValue() ? this.map.getValue() : null;

        if (this.material[property] !== newMap) {
            if (newMap !== null) {
                var geometry = this.object.geometry;

                if (geometry.hasAttribute('uv') === false) trace('Geometry doesn\'t have uvs: ' + Std.string(geometry));

                if (property === 'envMap') newMap.mapping = THREE.EquirectangularReflectionMapping;
            }

            this.editor.execute(new SetMaterialMapCommand(this.editor, this.object, property, newMap, this.materialSlot));
        }
    }

    private function onMapChange(texture) {
        if (texture !== null) {
            if (this.colorMaps.includes(property) && texture.isDataTexture !== true && texture.colorSpace !== THREE.SRGBColorSpace) {
                texture.colorSpace = THREE.SRGBColorSpace;
                this.material.needsUpdate = true;
            }
        }

        this.enabled.setDisabled(false);
        this.onChange();
    }

    private function onIntensityChange() {
        if (this.material[property + 'Intensity'] !== this.intensity.getValue()) {
            this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, property + 'Intensity', this.intensity.getValue(), this.materialSlot));
        }
    }

    private function onScaleChange() {
        if (this.material[this.mapType + 'Scale'] !== this.scale.getValue()) {
            this.editor.execute(new SetMaterialValueCommand(this.editor, this.object, this.mapType + 'Scale', this.scale.getValue(), this.materialSlot));
        }
    }

    private function onScaleXYChange() {
        var value = [this.scaleX.getValue(), this.scaleY.getValue()];

        if (this.material[this.mapType + 'Scale'].x !== value[0] || this.material[this.mapType + 'Scale'].y !== value[1]) {
            this.editor.execute(new SetMaterialVectorCommand(this.editor, this.object, this.mapType + 'Scale', value, this.materialSlot));
        }
    }

    private function onRangeChange() {
        var value = [this.rangeMin.getValue(), this.rangeMax.getValue()];

        if (this.material[this.mapType + 'Range'][0] !== value[0] || this.material[this.mapType + 'Range'][1] !== value[1]) {
            this.editor.execute(new SetMaterialRangeCommand(this.editor, this.object, this.mapType + 'Range', value[0], value[1], this.materialSlot));
        }
    }

    private function update(currentObject, currentMaterialSlot: Int = 0) {
        this.object = currentObject;
        this.materialSlot = currentMaterialSlot;

        if (this.object === null) return;
        if (this.object.material === undefined) return;

        this.material = this.editor.getObjectMaterial(this.object, this.materialSlot);

        if (this.property in this.material) {
            if (this.material[property] !== null) {
                this.map.setValue(this.material[property]);
            }

            this.enabled.setValue(this.material[property] !== null);
            this.enabled.setDisabled(this.map.getValue() === null);

            if (this.intensity !== null) {
                this.intensity.setValue(this.material[property + 'Intensity']);
            }

            if (this.scale !== null) {
                this.scale.setValue(this.material[this.mapType + 'Scale']);
            }

            if (this.scaleX !== null) {
                this.scaleX.setValue(this.material[this.mapType + 'Scale'].x);
                this.scaleY.setValue(this.material[this.mapType + 'Scale'].y);
            }

            if (this.rangeMin !== null) {
                this.rangeMin.setValue(this.material[this.mapType + 'Range'][0]);
                this.rangeMax.setValue(this.material[this.mapType + 'Range'][1]);
            }

            this.container.setDisplay('');
        } else {
            this.container.setDisplay('none');
        }
    }

    public function getContainer() {
        return this.container;
    }
}