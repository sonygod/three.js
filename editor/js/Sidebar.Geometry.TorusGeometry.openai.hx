package three.js.editor.js;

import three.TorusGeometry;
import three.MathUtils;
import js.html.Element;

class GeometryParametersPanel {
	static function create(editor:Editor, object:Object):Element {
		var strings = editor.strings;
		var container = new UIDiv();

		var geometry = object.geometry;
		var parameters = geometry.parameters;

		// radius

		var radiusRow = new UIRow();
		var radiusInput = new UINumber(parameters.radius);
		radiusInput.onChange = update;
		radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radius')).setClass('Label'));
		radiusRow.add(radiusInput);

		container.add(radiusRow);

		// tube

		var tubeRow = new UIRow();
		var tubeInput = new UINumber(parameters.tube);
		tubeInput.onChange = update;
		tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tube')).setClass('Label'));
		tubeRow.add(tubeInput);

		container.add(tubeRow);

		// radialSegments

		var radialSegmentsRow = new UIRow();
		var radialSegmentsInput = new UIInteger(parameters.radialSegments);
		radialSegmentsInput.setRange(1, Math.POSITIVE_INFINITY);
		radialSegmentsInput.onChange = update;
		radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radialsegments')).setClass('Label'));
		radialSegmentsRow.add(radialSegmentsInput);

		container.add(radialSegmentsRow);

		// tubularSegments

		var tubularSegmentsRow = new UIRow();
		var tubularSegmentsInput = new UIInteger(parameters.tubularSegments);
		tubularSegmentsInput.setRange(1, Math.POSITIVE_INFINITY);
		tubularSegmentsInput.onChange = update;
		tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tubularsegments')).setClass('Label'));
		tubularSegmentsRow.add(tubularSegmentsInput);

		container.add(tubularSegmentsRow);

		// arc

		var arcRow = new UIRow();
		var arcInput = new UINumber(parameters.arc * MathUtils.RAD2DEG);
		arcInput.setStep(10);
		arcInput.onChange = update;
		arcRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/arc')).setClass('Label'));
		arcRow.add(arcInput);

		container.add(arcRow);

		function update() {
			editor.execute(new SetGeometryCommand(editor, object, new TorusGeometry(
				radiusInput.getValue(),
				tubeInput.getValue(),
				radialSegmentsInput.getValue(),
				tubularSegmentsInput.getValue(),
				arcInput.getValue() * MathUtils.DEG2RAD
			)));
		}

		return container;
	}
}