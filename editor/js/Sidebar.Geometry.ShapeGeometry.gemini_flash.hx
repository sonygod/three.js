import three.THREE;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UIButton;

import commands.SetGeometryCommand;

class GeometryParametersPanel {

	public function new(editor, object) {

		var strings = editor.strings;

		var container = new UIDiv();

		var geometry = object.geometry;
		var parameters = geometry.parameters;

		// curveSegments

		var curveSegmentsRow = new UIRow();
		var curveSegments = new UIInteger( parameters.curveSegments != null ? parameters.curveSegments : 12 ).onChange(changeShape).setRange(1, Math.POSITIVE_INFINITY);

		curveSegmentsRow.add( new UIText( strings.getKey( 'sidebar/geometry/shape_geometry/curveSegments' ) ).setClass( 'Label' ) );
		curveSegmentsRow.add( curveSegments );

		container.add( curveSegmentsRow );

		// to extrude
		var button = new UIButton( strings.getKey( 'sidebar/geometry/shape_geometry/extrude' ) ).onClick( toExtrude ).setClass( 'Label' ).setMarginLeft( '120px' );
		container.add( button );

		//

		function changeShape(_) {

			editor.execute( new SetGeometryCommand( editor, object, new THREE.ShapeGeometry(
				parameters.shapes,
				curveSegments.getValue()
			) ) );

		}

		function toExtrude(_) {

			editor.execute( new SetGeometryCommand( editor, object, new THREE.ExtrudeGeometry(
				parameters.shapes, {
					curveSegments: curveSegments.getValue()
				}
			) ) );

		}

		return container;

	}

}