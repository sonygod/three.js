import js.Browser.document;
import three.THREE;
import three.geometries.ExtrudeGeometry;
import three.geometries.ShapeGeometry;
import three.objects.Object3D;
import ui.*;
import commands.SetGeometryCommand;
import editor.Editor;
import editor.strings.Strings;

class GeometryParametersPanel {

    public function new(editor: Editor, object: Object3D) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;
        var options = parameters.options;
        options.curveSegments = options.curveSegments != null ? options.curveSegments : 12;
        options.steps = options.steps != null ? options.steps : 1;
        options.depth = options.depth != null ? options.depth : 1;
        var bevelThickness = options.bevelThickness != null ? options.bevelThickness : 0.2;
        options.bevelThickness = bevelThickness;
        options.bevelSize = options.bevelSize != null ? options.bevelSize : bevelThickness - 0.1;
        options.bevelOffset = options.bevelOffset != null ? options.bevelOffset : 0;
        options.bevelSegments = options.bevelSegments != null ? options.bevelSegments : 3;

        // curveSegments
        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(options.curveSegments);
        curveSegments.onChange(update);
        curveSegments.setRange(1, Float.POSITIVE_INFINITY);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // steps
        var stepsRow = new UIRow();
        var steps = new UIInteger(options.steps);
        steps.onChange(update);
        steps.setRange(1, Float.POSITIVE_INFINITY);

        stepsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/steps')).setClass('Label'));
        stepsRow.add(steps);

        container.add(stepsRow);

        // depth
        var depthRow = new UIRow();
        var depth = new UINumber(options.depth);
        depth.onChange(update);
        depth.setRange(1, Float.POSITIVE_INFINITY);

        depthRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/depth')).setClass('Label'));
        depthRow.add(depth);

        container.add(depthRow);

        // enabled
        var enabledRow = new UIRow();
        var enabled = new UICheckbox(options.bevelEnabled);
        enabled.onChange(update);

        enabledRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelEnabled')).setClass('Label'));
        enabledRow.add(enabled);

        container.add(enabledRow);

        // thickness
        var thicknessRow = new UIRow();
        var thickness = new UINumber(options.bevelThickness);
        thickness.onChange(update);

        thicknessRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelThickness')).setClass('Label'));
        thicknessRow.add(thickness);

        container.add(thicknessRow);

        // size
        var sizeRow = new UIRow();
        var size = new UINumber(options.bevelSize);
        size.onChange(update);

        sizeRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelSize')).setClass('Label'));
        sizeRow.add(size);

        container.add(sizeRow);

        // offset
        var offsetRow = new UIRow();
        var offset = new UINumber(options.bevelOffset);
        offset.onChange(update);

        offsetRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelOffset')).setClass('Label'));
        offsetRow.add(offset);

        container.add(offsetRow);

        // segments
        var segmentsRow = new UIRow();
        var segments = new UIInteger(options.bevelSegments);
        segments.onChange(update);
        segments.setRange(0, Float.POSITIVE_INFINITY);

        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelSegments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        updateBevelRow(options.bevelEnabled);

        var button = new UIButton(strings.getKey('sidebar/geometry/extrude_geometry/shape'));
        button.onClick(toShape);
        button.setClass('Label');
        button.setMarginLeft('120px');
        container.add(button);

        //

        function updateBevelRow(enabled: Bool) {
            if (enabled === true) {
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

            var bevelThicknessValue = thickness != null ? thickness.getValue() : options.bevelThickness;
            var bevelSizeValue = size != null ? size.getValue() : options.bevelSize;
            var bevelOffsetValue = offset != null ? offset.getValue() : options.bevelOffset;
            var bevelSegmentsValue = segments != null ? segments.getValue() : options.bevelSegments;

            editor.execute(new SetGeometryCommand(editor, object, new ExtrudeGeometry(
                parameters.shapes,
                {
                    curveSegments: curveSegments.getValue(),
                    steps: steps.getValue(),
                    depth: depth.getValue(),
                    bevelEnabled: enabled.getValue(),
                    bevelThickness: bevelThicknessValue,
                    bevelSize: bevelSizeValue,
                    bevelOffset: bevelOffsetValue,
                    bevelSegments: bevelSegmentsValue
                }
            )));
        }

        function toShape() {
            editor.execute(new SetGeometryCommand(editor, object, new ShapeGeometry(
                parameters.shapes,
                options.curveSegments
            )));
        }

        return container;
    }
}