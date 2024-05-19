Here is the converted Haxe code:
```
package three.js.editor.js;

import three.js.*;

import js.lib.ui.UIDiv;
import js.lib.ui.UIRow;
import js.lib.ui.UIText;
import js.lib.ui.UIInteger;
import js.lib.ui.UINumber;
import js.lib.ui.three.UIPoints2;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry:LatheGeometry = object.geometry;
        var parameters = geometry.parameters;

        // segments

        var segmentsRow = new UIRow();
        var segments = new UIInteger(parameters.segments);
        segments.onChange = update;

        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        // phiStart

        var phiStartRow = new UIRow();
        var phiStart = new UINumber(parameters.phiStart * 180 / Math.PI);
        phiStart.onChange = update;

        phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/phistart')).setClass('Label'));
        phiStartRow.add(phiStart);

        container.add(phiStartRow);

        // phiLength

        var phiLengthRow = new UIRow();
        var phiLength = new UINumber(parameters.phiLength * 180 / Math.PI);
        phiLength.onChange = update;

        phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/philength')).setClass('Label'));
        phiLengthRow.add(phiLength);

        container.add(phiLengthRow);

        // points

        var pointsRow = new UIRow();
        pointsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/points')).setClass('Label'));

        var points = new UIPoints2();
        points.setValue(parameters.points);
        points.onChange = update;
        pointsRow.add(points);

        container.add(pointsRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new LatheGeometry(
                points.getValue(),
                segments.getValue(),
                phiStart.getValue() / 180 * Math.PI,
                phiLength.getValue() / 180 * Math.PI
            )));
        }

        return container;
    }
}
```
Note that I've kept the same namespace and imports as the original JavaScript code. I've also maintained the same structure and naming conventions. However, please note that Haxe has some differences in syntax and semantics compared to JavaScript, so some adjustments were necessary to make the code compile and run correctly.

Also, I've assumed that the `Editor` and `Object3D` classes are part of the Three.js library, and that they have the same properties and methods as in the original JavaScript code. If this is not the case, you may need to adjust the code accordingly.

Finally, I've used the `js.lib.ui` package for the UI components, which is a common convention in Haxe. If you're using a different UI library, you may need to adjust the imports accordingly.