import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UINumber};
import js.Lib.commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // width

        var widthRow = new UIRow();
        var width = new UINumber(parameters.width).onChange(update);

        widthRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/width')).setClass('Label'));
        widthRow.add(width);

        container.add(widthRow);

        // height

        var heightRow = new UIRow();
        var height = new UINumber(parameters.height).onChange(update);

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        // widthSegments

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Infinity).onChange(update);

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Infinity).onChange(update);

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/plane_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        function update() {

            editor.execute(new SetGeometryCommand(editor, object, new THREE.PlaneGeometry(
                width.getValue(),
                height.getValue(),
                widthSegments.getValue(),
                heightSegments.getValue()
            )));

        }

        return container;

    }

}