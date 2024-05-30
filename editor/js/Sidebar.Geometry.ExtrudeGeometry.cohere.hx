import js.THREE.ExtrudeGeometry;
import js.THREE.ShapeGeometry;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = js.browser.window.UIDiv_create();

        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;
        var options = untyped parameters.options;
        options.curveSegments = options.curveSegments != null ? options.curveSegments : 12;
        options.steps = options.steps != null ? options.steps : 1;
        options.depth = options.depth != null ? options.depth : 1;
        var bevelThickness = options.bevelThickness != null ? options.bevelThickness : 0.2;
        options.bevelThickness = bevelThickness;
        options.bevelSize = options.bevelSize != null ? options.bevelSize : bevelThickness - 0.1;
        options.bevelOffset = options.bevelOffset != null ? options.bevelOffset : 0;
        options.bevelSegments = options.bevelSegments != null ? options.bevelSegments : 3;

        // curveSegments
        var curveSegmentsRow = js.browser.window.UIRow_create();
        var curveSegments = js.browser.window.UIInteger_create(options.curveSegments).setRange(1, Int.positiveInfinity).onChange(update);

        curveSegmentsRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // steps
        var stepsRow = js.browser.window.UIRow_create();
        var steps = js.browser.window.UIInteger_create(options.steps).setRange(1, Int.positiveInfinity).onChange(update);

        stepsRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/steps')).setClass('Label'));
        stepsRow.add(steps);

        container.add(stepsRow);

        // depth
        var depthRow = js.browser.window.UIRow_create();
        var depth = js.browser.window.UINumber_create(options.depth).setRange(1, Int.positiveInfinity).onChange(update);

        depthRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/depth')).setClass('Label'));
        depthRow.add(depth);

        container.add(depthRow);

        // enabled
        var enabledRow = js.browser.window.UIRow_create();
        var enabled = js.browser.window.UICheckbox_create(options.bevelEnabled != null).onChange(update);

        enabledRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/bevelEnabled')).setClass('Label'));
        enabledRow.add(enabled);

        container.add(enabledRow);

        // thickness
        var thicknessRow = js.browser.window.UIRow_create();
        var thickness = js.browser.window.UINumber_create(options.bevelThickness).onChange(update);

        thicknessRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/bevelThickness')).setClass('Label'));
        thicknessRow.add(thickness);

        container.add(thicknessRow);

        // size
        var sizeRow = js.browser.window.UIRow_create();
        var size = js.browser.window.UINumber_create(options.bevelSize).onChange(update);

        sizeRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/bevelSize')).setClass('Label'));
        sizeRow.add(size);

        container.add(sizeRow);

        // offset
        var offsetRow = js.browser.window.UIRow_create();
        var offset = js.browser.window.UINumber_create(options.bevelOffset).onChange(update);

        offsetRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/bevelOffset')).setClass('Label'));
        offsetRow.add(offset);

        container.add(offsetRow);

        // segments
        var segmentsRow = js.browser.window.UIRow_create();
        var segments = js.browser.window.UIInteger_create(options.bevelSegments).setRange(0, Int.positiveInfinity).onChange(update);

        segmentsRow.add(js.browser.window.UIText_create(strings.getKey('sidebar/geometry/extrude_geometry/bevelSegments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        updateBevelRow(options.bevelEnabled != null);

        var button = js.browser.window.UIButton_create(strings.getKey('sidebar/geometry/extrude_geometry/shape')).onClick(toShape).setClass('Label').setMarginLeft('120px');
        container.add(button);

        function updateBevelRow(enabled:Bool) {
            if (enabled) {
                thicknessRow.setDisplay('');
                sizeRow.setDisplay('');
                offsetRow.setDisplay('');
                segmentsRow.setDisplay('');
            } else {
                thicknessRow.setDisplay('none');
                sizeRow.setDisplay('none');
                offsetRow.setDisplay('none');
                segmentsRow.setDisplay('none');
            }
        }

        function update() {
            updateBevelRow(enabled.getValue());
            editor.execute(SetGeometryCommand.create(editor, object, ExtrudeGeometry.create(
                untyped parameters.shapes,
                {
                    curveSegments: curveSegments.getValue(),
                    steps: steps.getValue(),
                    depth: depth.getValue(),
                    bevelEnabled: enabled.getValue(),
                    bevelThickness: if (thickness != null) thickness.getValue() else options.bevelThickness,
                    bevelSize: if (size != null) size.getValue() else options.bevelSize,
                    bevelOffset: if (offset != null) offset.getValue() else options.bevelOffset,
                    bevelSegments: if (segments != null) segments.getValue() else options.bevelSegments
                }
            )));
        }

        function toShape() {
            editor.execute(SetGeometryCommand.create(editor, object, ShapeGeometry.create(
                untyped parameters.shapes,
                options.curveSegments
            )));
        }

        return container;
    }
}