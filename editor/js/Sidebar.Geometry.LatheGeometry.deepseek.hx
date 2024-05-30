import three.THREE;
import js.Browser.window;

import three.editor.js.libs.ui.UIDiv;
import three.editor.js.libs.ui.UIRow;
import three.editor.js.libs.ui.UIText;
import three.editor.js.libs.ui.UIInteger;
import three.editor.js.libs.ui.UINumber;
import three.editor.js.libs.ui.three.UIPoints2;

import three.editor.js.commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // segments

        var segmentsRow = new UIRow();
        var segments = new UIInteger(parameters.segments).onChange(update);

        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);

        container.add(segmentsRow);

        // phiStart

        var phiStartRow = new UIRow();
        var phiStart = new UINumber(parameters.phiStart * 180 / Math.PI).onChange(update);

        phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/phistart')).setClass('Label'));
        phiStartRow.add(phiStart);

        container.add(phiStartRow);

        // phiLength

        var phiLengthRow = new UIRow();
        var phiLength = new UINumber(parameters.phiLength * 180 / Math.PI).onChange(update);

        phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/philength')).setClass('Label'));
        phiLengthRow.add(phiLength);

        container.add(phiLengthRow);

        // points

        var pointsRow = new UIRow();
        pointsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/points')).setClass('Label'));

        var points = new UIPoints2().setValue(parameters.points).onChange(update);
        pointsRow.add(points);

        container.add(pointsRow);

        function update() {

            editor.execute(new SetGeometryCommand(editor, object, new THREE.LatheGeometry(
                points.getValue(),
                segments.getValue(),
                phiStart.getValue() / 180 * Math.PI,
                phiLength.getValue() / 180 * Math.PI
            )));

        }

        return container;

    }

}