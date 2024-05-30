package three.js.editor.js;

import three_js.*;
import js.html.DOMElement;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry:PlaneGeometry = cast object.geometry;
        var parameters = geometry.parameters;

        // width

        var widthRow = new UIRow();
        var width = new UINumber(parameters.width);
        width.onChange = update;

        widthRow.addChild(new UIText(strings.getKey('sidebar/geometry/plane_geometry/width')).setClass('Label'));
        widthRow.addChild(width);

        container.addChild(widthRow);

        // height

        var heightRow = new UIRow();
        var height = new UINumber(parameters.height);
        height.onChange = update;

        heightRow.addChild(new UIText(strings.getKey('sidebar/geometry/plane_geometry/height')).setClass('Label'));
        heightRow.addChild(height);

        container.addChild(heightRow);

        // widthSegments

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments);
        widthSegments.setRange(1, Math.POSITIVE_INFINITY);
        widthSegments.onChange = update;

        widthSegmentsRow.addChild(new UIText(strings.getKey('sidebar/geometry/plane_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.addChild(widthSegments);

        container.addChild(widthSegmentsRow);

        // heightSegments

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments);
        heightSegments.setRange(1, Math.POSITIVE_INFINITY);
        heightSegments.onChange = update;

        heightSegmentsRow.addChild(new UIText(strings.getKey('sidebar/geometry/plane_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.addChild(heightSegments);

        container.addChild(heightSegmentsRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new PlaneGeometry(
                width.getValue(),
                height.getValue(),
                widthSegments.getValue(),
                heightSegments.getValue()
            )));
        }

        return container;
    }
}