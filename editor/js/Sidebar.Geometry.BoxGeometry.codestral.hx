import js.three.THREE;
import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UINumber;
import ui.UIInteger;
import commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Editor, object:Object) {
        var strings:Strings = editor.strings;

        var container:UIDiv = new UIDiv();

        var geometry:Geometry = object.geometry;
        var parameters:Dynamic = geometry.parameters;

        // width
        var widthRow:UIRow = new UIRow();
        var width:UINumber = new UINumber().setPrecision(3).setValue(parameters.width).onChange(update);

        widthRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/width')).setClass('Label'));
        widthRow.add(width);

        container.add(widthRow);

        // height
        var heightRow:UIRow = new UIRow();
        var height:UINumber = new UINumber().setPrecision(3).setValue(parameters.height).onChange(update);

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        // depth
        var depthRow:UIRow = new UIRow();
        var depth:UINumber = new UINumber().setPrecision(3).setValue(parameters.depth).onChange(update);

        depthRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/depth')).setClass('Label'));
        depthRow.add(depth);

        container.add(depthRow);

        // widthSegments
        var widthSegmentsRow:UIRow = new UIRow();
        var widthSegments:UIInteger = new UIInteger(parameters.widthSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(update);

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/widthseg')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments
        var heightSegmentsRow:UIRow = new UIRow();
        var heightSegments:UIInteger = new UIInteger(parameters.heightSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(update);

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/heightseg')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        // depthSegments
        var depthSegmentsRow:UIRow = new UIRow();
        var depthSegments:UIInteger = new UIInteger(parameters.depthSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(update);

        depthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/box_geometry/depthseg')).setClass('Label'));
        depthSegmentsRow.add(depthSegments);

        container.add(depthSegmentsRow);

        //
        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.BoxGeometry(
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