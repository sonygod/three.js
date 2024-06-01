import js.Lib;
import ui.UIButton;
import ui.UIRow;
import ui.UIText;

class SidebarMaterialProgram {

	public function new(editor:Dynamic, property:String) {

		var signals = editor.signals;
		var strings = editor.strings;

		var object:Dynamic = null;
		var materialSlot:Int = 0;
		var material:Dynamic = null;

		var container = new UIRow();
		container.add( new UIText( strings.getKey( 'sidebar/material/program' ) ).setClass( 'Label' ) );

		var programInfo = new UIButton( strings.getKey( 'sidebar/material/info' ) );
		programInfo.setMarginRight( '4px' );
		programInfo.onClick( function(_) {

			signals.editScript.dispatch( object, 'programInfo' );

		} );
		container.add( programInfo );

		var programVertex = new UIButton( strings.getKey( 'sidebar/material/vertex' ) );
		programVertex.setMarginRight( '4px' );
		programVertex.onClick( function(_) {

			signals.editScript.dispatch( object, 'vertexShader' );

		} );
		container.add( programVertex );

		var programFragment = new UIButton( strings.getKey( 'sidebar/material/fragment' ) );
		programFragment.setMarginRight( '4px' );
		programFragment.onClick( function(_) {

			signals.editScript.dispatch( object, 'fragmentShader' );

		} );
		container.add( programFragment );

		function update( currentObject:Dynamic, currentMaterialSlot:Int = 0 ):Void {

			object = currentObject;
			materialSlot = currentMaterialSlot;

			if ( object == null ) return;
			if ( !Reflect.hasField(object, "material") ) return;

			material = editor.getObjectMaterial( object, materialSlot );

			if ( Reflect.hasField(material, property) ) {

				container.setDisplay( '' );

			} else {

				container.setDisplay( 'none' );

			}

		}

		//

		signals.objectSelected.add( update );
		signals.materialChanged.add( update );

		return container;

	}

}