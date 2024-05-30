import js.THREE.CylinderGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UICheckbox;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        var radiusTopRow = new UIRow();
        var radiusTop = new UINumber(parameters.radiusTop).onChange(update);

        radiusTopRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radiustop')).setClass('Label'));
        radiusTopRow.add(radiusTop);

        container.add(radiusTopRow);

        var radiusBottomRow = new UIRow();
        var radiusBottom = new UINumber(parameters.radiusBottom).onChange(update);

        radiusBottomRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radiusbottom')).setClass('Label'));
        radiusBottomRow.add(radiusBottom);

        container.add(radiusBottomRow);

        var heightRow = new UIRow();
        var height = new UINumber(parameters.height).onChange(update);

        heightRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/height')).setClass('Label'));
        heightRow.add(height);

        container.add(heightRow);

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        var openEndedRow = new UIRow();
        var openEnded = new UICheckbox(parameters.openEnded).onChange(update);

        openEndedRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/openended')).setClass('Label'));
        openEndedRow.add(openEnded);

        container.add(openEndedRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new CylinderGeometry(
                radiusTop.getValue(),
                radiusBottom.getValue(),
                height.getValue(),
                radialSegments.getValue(),
                heightSegments.getValue(),
                openEnded.getValue()
            )));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:CylinderGeometry) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }
}