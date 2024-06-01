import three.THREE;
import three.geometries.CircleGeometry;
import three.math.MathUtils;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {

	public function new(editor, object) {

		var strings = editor.strings;

		var container = new UIDiv();

		var geometry = object.geometry;
		var parameters = geometry.parameters;

		// radius

		var radiusRow = new UIRow();
		var radius = new UINumber(parameters.radius).onChange(update);

		radiusRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/radius')).setClass('Label'));
		radiusRow.add(radius);

		container.add(radiusRow);

		// segments

		var segmentsRow = new UIRow();
		var segments = new UIInteger(parameters.segments).setRange(3, Math.POSITIVE_INFINITY).onChange(update);

		segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/segments')).setClass('Label'));
		segmentsRow.add(segments);

		container.add(segmentsRow);

		// thetaStart

		var thetaStartRow = new UIRow();
		var thetaStart = new UINumber(parameters.thetaStart * MathUtils.RAD2DEG).setStep(10).onChange(update);

		thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetastart')).setClass('Label'));
		thetaStartRow.add(thetaStart);

		container.add(thetaStartRow);

		// thetaLength

		var thetaLengthRow = new UIRow();
		var thetaLength = new UINumber(parameters.thetaLength * MathUtils.RAD2DEG).setStep(10).onChange(update);

		thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetalength')).setClass('Label'));
		thetaLengthRow.add(thetaLength);

		container.add(thetaLengthRow);

		//

		function update(_) {

			editor.execute(new SetGeometryCommand(editor, object, new CircleGeometry(
				radius.getValue(),
				segments.getValue(),
				thetaStart.getValue() * MathUtils.DEG2RAD,
				thetaLength.getValue() * MathUtils.DEG2RAD
			)));

		}

		return container;

	}

}