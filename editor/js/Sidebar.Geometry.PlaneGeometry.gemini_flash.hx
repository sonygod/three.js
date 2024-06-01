import three.THREE;
import three.geometries.PlaneGeometry;

import js.Lib;

class GeometryParametersPanel {

    public function new(editor, object) {

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // width

        var widthRow = new UIRow();
        var width = new UINumber(parameters.width).onChange(update);

        widthRow.add(new UIText(editor.strings.getKey('sidebar/geometry/plane_geometry/width')).setClass('Label'));
        widthRow.add(width);

        container.add(widthRow);

        // height

        var heightRow = new UIRow();
        var height = new UINumber(parameters.height).onChange(update);

        heightRow.add(new UIText(editor.strings.getKey('sidebar/geometry/plane_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        // widthSegments

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Math.POSITIVE_INFINITY).onChange(update);

        widthSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/plane_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Math.POSITIVE_INFINITY).onChange(update);

        heightSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/plane_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        //

        function update(_) {

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