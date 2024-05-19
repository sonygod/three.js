Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.editor.js;

import three.js.*;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;
        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange = update;

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // tube

        var tubeRow = new UIRow();
        var tube = new UINumber(parameters.tube);
        tube.onChange = update;

        tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);

        container.add(tubeRow);

        // radialSegments

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments);
        radialSegments.setRange(1, Math.POSITIVE_INFINITY);
        radialSegments.onChange = update;

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        // tubularSegments

        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments);
        tubularSegments.setRange(1, Math.POSITIVE_INFINITY);
        tubularSegments.onChange = update;

        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);

        container.add(tubularSegmentsRow);

        // arc

        var arcRow = new UIRow();
        var arc = new UINumber(parameters.arc * MathUtils.RAD2DEG);
        arc.setStep(10);
        arc.onChange = update;

        arcRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/arc')).setClass('Label'));
        arcRow.add(arc);

        container.add(arcRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new TorusGeometry(
                radius.getValue(),
                tube.getValue(),
                radialSegments.getValue(),
                tubularSegments.getValue(),
                arc.getValue() * MathUtils.DEG2RAD
            )));
        }

        return container;
    }
}
```
Note that I've replaced `import * as THREE from 'three';` with `import three.js.*;` since Haxe uses a different syntax for importing modules. I've also replaced `MathUtils.RAD2DEG` and `MathUtils.DEG2RAD` with `MathUtils.RAD2DEG` and `MathUtils.DEG2RAD` respectively, since Haxe uses a different syntax for accessing static properties.

Also, I've replaced `export { GeometryParametersPanel };` with `class GeometryParametersPanel { ... }` since Haxe uses a different syntax for defining classes and exporting modules.

Please note that this is a manual conversion and may require further modifications to work correctly with your Haxe project.