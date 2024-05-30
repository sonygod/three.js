import js.Browser.window;
import js.Lib.three.editor.js.libs.ui.*;

class SidebarGeometryBufferGeometry {

    var strings:Dynamic;
    var signals:Dynamic;
    var container:UIRow;

    public function new(editor:Dynamic) {
        strings = editor.strings;
        signals = editor.signals;
        container = new UIRow();
        signals.objectSelected.add(update);
        signals.geometryChanged.add(update);
    }

    function update(object:Dynamic) {
        if (object == null) return;
        if (object == undefined) return;

        var geometry = object.geometry;

        if (geometry != null) {
            container.clear();
            container.setDisplay('block');

            var attributesRow = new UIRow();
            var textAttributes = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/attributes')).setClass('Label');
            attributesRow.add(textAttributes);
            var containerAttributes = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
            attributesRow.add(containerAttributes);

            var index = geometry.index;

            if (index != null) {
                containerAttributes.add(new UIText(strings.getKey('sidebar/geometry/buffer_geometry/index')).setWidth('80px'));
                containerAttributes.add(new UIText(editor.utils.formatNumber(index.count)).setFontSize('12px'));
                containerAttributes.add(new UIBreak());
            }

            var attributes = geometry.attributes;

            for (name in attributes) {
                var attribute = attributes[name];
                containerAttributes.add(new UIText(name).setWidth('80px'));
                containerAttributes.add(new UIText(editor.utils.formatNumber(attribute.count) + ' (' + attribute.itemSize + ')').setFontSize('12px'));
                containerAttributes.add(new UIBreak());
            }

            container.add(attributesRow);

            var morphAttributes = geometry.morphAttributes;
            var hasMorphTargets = Object.keys(morphAttributes).length > 0;

            if (hasMorphTargets) {
                var rowMorphAttributes = new UIRow();
                var textMorphAttributes = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphAttributes')).setClass('Label');
                rowMorphAttributes.add(textMorphAttributes);
                var containerMorphAttributes = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
                rowMorphAttributes.add(containerMorphAttributes);

                for (name in morphAttributes) {
                    var morphTargets = morphAttributes[name];
                    containerMorphAttributes.add(new UIText(name).setWidth('80px'));
                    containerMorphAttributes.add(new UIText(editor.utils.formatNumber(morphTargets.length)).setFontSize('12px'));
                    containerMorphAttributes.add(new UIBreak());
                }

                container.add(rowMorphAttributes);

                var rowMorphRelative = new UIRow();
                var textMorphRelative = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphRelative')).setClass('Label');
                rowMorphRelative.add(textMorphRelative);
                var checkboxMorphRelative = new UICheckbox().setValue(geometry.morphTargetsRelative).setDisabled(true);
                rowMorphRelative.add(checkboxMorphRelative);

                container.add(rowMorphRelative);
            }
        } else {
            container.setDisplay('none');
        }
    }

    public function getContainer():UIRow {
        return container;
    }
}