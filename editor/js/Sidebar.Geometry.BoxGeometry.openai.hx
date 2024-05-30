package three.js.editor.js;

import three.js.Three;

import ui.UI Div;
import ui.UIRow;
import ui.UIText;
import ui.UINumber;
import ui.UIInteger;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // width

        var widthRow = new UIRow();
        var width = new UINumber(3).setValue(parameters.width);
        width.onChange = update;

        widthRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/width')).setClass('Label'));
        widthRow.add(width);

        container.add(widthRow);

        // height

        var heightRow = new UIRow();
        var height = new UINumber(3).setValue(parameters.height);
        height.onChange = update;

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        // depth

        var depthRow = new UIRow();
        var depth = new UINumber(3).setValue(parameters.depth);
        depth.onChange = update;

        depthRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/depth')).setClass('Label'));
        depthRow.add(depth);

        container.add(depthRow);

        // widthSegments

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Math.POSITIVE_INFINITY);
        widthSegments.onChange = update;

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/widthseg')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Math.POSITIVE_INFINITY);
        heightSegments.onChange = update;

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/heightseg')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        // depthSegments

        var depthSegmentsRow = new UIRow();
        var depthSegments = new UIInteger(parameters.depthSegments).setRange(1, Math.POSITIVE_INFINITY);
        depthSegments.onChange = update;

        depthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/depthseg')).setClass('Label'));
        depthSegmentsRow.add(depthSegments);

        container.add(depthSegmentsRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.BoxGeometry(
                width.getValue(),
                height.getValue(),
                depth.getValue(),
                widthSegments.getValue(),
                heightSegments.getValue(),
                depthSegments.getValue()
            )));
        }

        return container;
    }
}