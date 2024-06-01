import three.THREE;
import three.geometries.CapsuleGeometry;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UINumber;
import ui.UIInteger;

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

		radiusRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radius')).setClass('Label'));
		radiusRow.add(radius);

		container.add(radiusRow);

		// length

		var lengthRow = new UIRow();
		var length = new UINumber(parameters.length).onChange(update);

		lengthRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/length')).setClass('Label'));
		lengthRow.add(length);

		container.add(lengthRow);

		// capSegments

		var capSegmentsRow = new UIRow();
		var capSegments = new UINumber(parameters.capSegments).onChange(update);

		capSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/capseg')).setClass('Label'));
		capSegmentsRow.add(capSegments);

		container.add(capSegmentsRow);

		// radialSegments

		var radialSegmentsRow = new UIRow();
		var radialSegments = new UIInteger(parameters.radialSegments).setRange(1, Math.POSITIVE_INFINITY).onChange(update);

		radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/capsule_geometry/radialseg')).setClass('Label'));
		radialSegmentsRow.add(radialSegments);

		container.add(radialSegmentsRow);

		//

		function update(_) {

			editor.execute(new SetGeometryCommand(editor, object, new CapsuleGeometry(
				radius.getValue(),
				length.getValue(),
				Std.int(capSegments.getValue()),
				Std.int(radialSegments.getValue())
			)));

		}

		return container;

	}

}