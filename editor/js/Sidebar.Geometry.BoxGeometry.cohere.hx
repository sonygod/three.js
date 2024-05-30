import js.three.BoxGeometry;
import js.three.Object3D;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UINumber;
import js.UIInteger;

class SetGeometryCommand {
	public function new(editor:Editor, object:Object3D, geometry:BoxGeometry) {
		// ...
	}
}

class GeometryParametersPanel {
	public function new(editor:Editor, object:Object3D) {
		var container = new UIDiv();
		var geometry = object.geometry;
		var parameters = geometry.parameters;

		var widthRow = new UIRow();
		var width = new UINumber().setPrecision(3).setValue(parameters.width);
		width.onChange(function() update());

		widthRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/width')).setClass('Label'));
		widthRow.add(width);

		container.add(widthRow);

		var heightRow = new UIRow();
		var height = new UINumber().setPrecision(3).setValue(parameters.height);
		height.onChange(function() update());

		heightRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/height')).setClass('Label'));
		heightRow.add(height);

		container.add(heightRow);

		var depthRow = new UIRow();
		var depth = new UINumber().setPrecision(3).setValue(parameters.depth);
		depth.onChange(function() update());

		depthRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/depth')).setClass('Label'));
		depthRow.add(depth);

		container.add(depthRow);

		var widthSegmentsRow = new UIRow();
		var widthSegments = new UIInteger(parameters.widthSegments);
		widthSegments.setRange(1, Int.posInfinity);
		widthSegments.onChange(function() update());

		widthSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/widthseg')).setClass('Label'));
		widthSegmentsRow.add(widthSegments);

		container.add(widthSegmentsRow);

		var heightSegmentsRow = new UIRow();
		var heightSegments = new UIInteger(parameters.heightSegments);
		heightSegments.setRange(1, Int.posInfinity);
		heightSegments.onChange(function() update());

		heightSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/heightseg')).setClass('Label'));
		heightSegmentsRow.add(heightSegments);

		container.add(heightSegmentsRow);

		var depthSegmentsRow = new UIRow();
		var depthSegments = new UIInteger(parameters.depthSegments);
		depthSegments.setRange(1, Int.posInfinity);
		depthSegments.onChange(function() update());

		depthSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/box_geometry/depthseg')).setClass('Label'));
		depthSegmentsRow.add(depthSegments);

		container.add(depthSegmentsRow);

		function update() {
			var widthValue = width.getValue();
			var heightValue = height.getValue();
			var depthValue = depth.getValue();
			var widthSegmentsValue = widthSegments.getValue();
			var heightSegmentsValue = heightSegments.getValue();
			var depthSegmentsValue = depthSegments.getValue();

			var newGeometry = new BoxGeometry(widthValue, heightValue, depthValue, widthSegmentsValue, heightSegmentsValue, depthSegmentsValue);
			editor.execute(new SetGeometryCommand(editor, object, newGeometry));
		}

		return container;
	}
}