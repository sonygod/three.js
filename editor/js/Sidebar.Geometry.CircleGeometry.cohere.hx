import js.THREE.CircleGeometry;
import js.THREE.MathUtils;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var container = js.UIDiv_construct();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var radiusRow = js.UIRow_construct();
        var radius = js.UINumber_construct(parameters.radius);
        radius.onChange(update);

        radiusRow.add(js.UIText_construct(editor.strings.getKey('sidebar/geometry/circle_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        var segmentsRow = js.UIRow_construct();
        var segments = js.UIInteger_construct(parameters.segments);
        segments.setRange(3, Int.POSITIVE_INFINITY);
        segments.onChange(update);

        segmentsRow.add(js.UIText_construct(editor.strings.getKey('sidebar/geometry/circle_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        var thetaStartRow = js.UIRow_construct();
        var thetaStart = js.UINumber_construct(parameters.thetaStart * js.THREE.MathUtils.RAD2DEG);
        thetaStart.setStep(10);
        thetaStart.onChange(update);

        thetaStartRow.add(js.UIText_construct(editor.strings.getKey('sidebar/geometry/circle_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);

        container.add(thetaStartRow);

        var thetaLengthRow = js.UIRow_construct();
        var thetaLength = js.UINumber_construct(parameters.thetaLength * js.THREE.MathUtils.RAD2DEG);
        thetaLength.setStep(10);
        thetaLength.onChange(update);

        thetaLengthRow.add(js.UIText_construct(editor.strings.getKey('sidebar/geometry/circle_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);

        container.add(thetaLengthRow);

        function update() {
            var newGeometry = js.THREE.CircleGeometry_construct(
                radius.getValue(),
                segments.getValue(),
                thetaStart.getValue() * js.THREE.MathUtils.DEG2RAD,
                thetaLength.getValue() * js.THREE.MathUtils.DEG2RAD
            );
            editor.execute(SetGeometryCommand(editor, object, newGeometry));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }

    public function execute():Bool {
        var geometry = untyped this.geometry;
        untyped this.object.geometry = geometry;
        return true;
    }

    public function undo():Bool {
        var object = untyped this.object;
        var geometry = untyped object.geometry;
        untyped this.object.geometry = geometry;
        return true;
    }

    public var editor:Editor;
    public var object:Dynamic;
    public var geometry:Dynamic;
}