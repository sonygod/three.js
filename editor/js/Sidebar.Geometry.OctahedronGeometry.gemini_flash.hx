import three.THREE;
import three.geometries.OctahedronGeometry;

import js.Lib;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel extends UIDiv {

	public function new(editor : Editor, object : three.core.Object3D) {
		super();

		var geometry = cast(object.geometry, three.core.BufferGeometry);
		var parameters = geometry.parameters;

		// radius

		var radiusRow = new UIRow();
		var radius = new UINumber(parameters.radius);
		radius.onChange.add(update);

		radiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/octahedron_geometry/radius')).setClass('Label'));
		radiusRow.add(radius);

		add(radiusRow);

		// detail

		var detailRow = new UIRow();
		var detail = new UIInteger(parameters.detail);
		detail.setRange(0, Math.POSITIVE_INFINITY);
		detail.onChange.add(update);

		detailRow.add(new UIText(editor.strings.getKey('sidebar/geometry/octahedron_geometry/detail')).setClass('Label'));
		detailRow.add(detail);

		add(detailRow);

		function update(_) {
			editor.execute(new SetGeometryCommand(editor, object, new OctahedronGeometry(
				radius.getValue(),
				Std.int(detail.getValue())
			)));

			editor.signals.objectChanged.dispatch(object);
		}
	}
}