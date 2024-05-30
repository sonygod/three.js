import js.THREE.CapsuleGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UINumber;
import js.UIInteger;

class GeometryParametersPanel {
    static public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange(function() -> update());

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        var lengthRow = new UIRow();
        var length = new UINumber(parameters.length);
        length.onChange(function() -> update());

        lengthRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/length')).setClass('Label'));
        lengthRow.add(length);

        container.add(lengthRow);

        var capSegmentsRow = new UIRow();
        var capSegments = new UINumber(parameters.capSegments);
        capSegments.onChange(function() -> update());

        capSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/capseg')).setClass('Label'));
        capSegmentsRow.add(capSegments);

        container.add(capSegmentsRow);

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments);
        radialSegments.setRange(1, Int.MaxValue);
        radialSegments.onChange(function() -> update());

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radialseg')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        function update() {
            var cmd = new SetGeometryCommand(editor, object, new CapsuleGeometry(
                radius.getValue(),
                length.getValue(),
                capSegments.getValue(),
                radialSegments.getValue()
            ));
            editor.execute(cmd);
        }

        return container;
    }
}

class SetGeometryCommand {
    var editor:Editor;
    var object:Dynamic;
    var geometry:Dynamic;

    public function new(editor:Editor, object:Dynamic, geometry:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }

    public function execute() {
        untyped this.object.geometry = this.geometry;
        this.editor.select(this.object);
    }

    public function undo() {
        this.execute();
    }
}