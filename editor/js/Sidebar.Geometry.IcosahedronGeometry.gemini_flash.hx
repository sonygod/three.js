import three.THREE;
import three.geometries.IcosahedronGeometry;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel extends UIDiv {

	public function new(editor, object) {
		super();

		var strings = editor.strings;
		var signals = editor.signals;

		var geometry = object.geometry;
		var parameters = geometry.parameters;

		// radius

		var radiusRow = new UIRow();
		var radius = new UINumber(parameters.radius).onChange(update);

		radiusRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
		radiusRow.add(radius);

		add(radiusRow);

		// detail

		var detailRow = new UIRow();
		var detail = new UIInteger(parameters.detail).setRange(0, Math.POSITIVE_INFINITY).onChange(update);

		detailRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
		detailRow.add(detail);

		add(detailRow);

		//

		function update(_) {
			editor.execute(new SetGeometryCommand(editor, object, new IcosahedronGeometry(
				radius.getValue(),
				detail.getValue()
			)));

			signals.objectChanged.dispatch(object);
		}
	}

}