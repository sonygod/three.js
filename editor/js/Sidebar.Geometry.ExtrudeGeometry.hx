Here is the converted Haxe code:
```
package three.js.editor.js;

import three.js.*;

import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UICheckbox;
import js.ui.UIButton;
import js.ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    private var editor:Editor;
    private var object:Object3D;

    public function new(editor:Editor, object:Object3D) {
        this.editor = editor;
        this.object = object;

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;
        var options = parameters.options;
        options.curveSegments = if (options.curveSegments != null) options.curveSegments else 12;
        options.steps = if (options.steps != null) options.steps else 1;
        options.depth = if (options.depth != null) options.depth else 1;
        var bevelThickness = if (options.bevelThickness != null) options.bevelThickness else 0.2;
        options.bevelThickness = bevelThickness;
        options.bevelSize = if (options.bevelSize != null) options.bevelSize else bevelThickness - 0.1;
        options.bevelOffset = if (options.bevelOffset != null) options.bevelOffset else 0;
        options.bevelSegments = if (options.bevelSegments != null) options.bevelSegments else 3;

        // curveSegments

        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(options.curveSegments).onChange(update).setRange(1, Math.POSITIVE_INFINITY);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // steps

        var stepsRow = new UIRow();
        var steps = new UIInteger(options.steps).onChange(update).setRange(1, Math.POSITIVE_INFINITY);

        stepsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/steps')).setClass('Label'));
        stepsRow.add(steps);

        container.add(stepsRow);

        // depth

        var depthRow = new UIRow();
        var depth = new UINumber(options.depth).onChange(update).setRange(1, Math.POSITIVE_INFINITY);

        depthRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/depth')).setClass('Label'));
        depthRow.add(depth);

        container.add(depthRow);

        // enabled

        var enabledRow = new UIRow();
        var enabled = new UICheckbox(options.bevelEnabled).onChange(update);

        enabledRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelEnabled')).setClass('Label'));
        enabledRow.add(enabled);

        container.add(enabledRow);

        // thickness

        var thicknessRow = new UIRow();
        var thickness = new UINumber(options.bevelThickness).onChange(update);

        thicknessRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelThickness')).setClass('Label'));
        thicknessRow.add(thickness);

        container.add(thicknessRow);

        // size

        var sizeRow = new UIRow();
        var size = new UINumber(options.bevelSize).onChange(update);

        sizeRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelSize')).setClass('Label'));
        sizeRow.add(size);

        container.add(sizeRow);

        // offset

        var offsetRow = new UIRow();
        var offset = new UINumber(options.bevelOffset).onChange(update);

        offsetRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelOffset')).setClass('Label'));
        offsetRow.add(offset);

        container.add(offsetRow);

        // segments

        var segmentsRow = new UIRow();
        var segments = new UIInteger(options.bevelSegments).onChange(update).setRange(0, Math.POSITIVE_INFINITY);

        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/extrude_geometry/bevelSegments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        updateBevelRow(options.bevelEnabled);

        var button = new UIButton(strings.getKey('sidebar/geometry/extrude_geometry/shape')).onClick(toShape).setClass('Label').setMarginLeft('120px');
        container.add(button);

        //

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

            editor.execute(new SetGeometryCommand(editor, object, new ExtrudeGeometry(
                parameters.shapes,
                {
                    curveSegments: curveSegments.getValue(),
                    steps: steps.getValue(),
                    depth: depth.getValue(),
                    bevelEnabled: enabled.getValue(),
                    bevelThickness: thickness != null ? thickness.getValue() : options.bevelThickness,
                    bevelSize: size != null ? size.getValue() : options.bevelSize,
                    bevelOffset: offset != null ? offset.getValue() : options.bevelOffset,
                    bevelSegments: segments != null ? segments.getValue() : options.bevelSegments
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
```