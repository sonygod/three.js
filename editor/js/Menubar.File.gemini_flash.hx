import three.FileLoader;
import three.exports.DRACOExporter;
import three.exports.GLTFExporter;
import three.exports.OBJExporter;
import three.exports.PLYExporter;
import three.exports.STLExporter;
import three.exports.USDZExporter;
import js.Browser;
import three.AnimationClip;

import ui.UIPanel;
import ui.UIRow;
import ui.UIHorizontalRule;

class MenubarFile {

	public static function create( editor : Editor ) : UIPanel {

		var strings = editor.strings;

		var container = new UIPanel();
		container.setClass( 'menu' );

		var title = new UIPanel();
		title.setClass( 'title' );
		title.setTextContent( strings.getKey( 'menubar/file' ) );
		container.add( title );

		var options = new UIPanel();
		options.setClass( 'options' );
		container.add( options );

		// New Project

		var newProjectSubmenuTitle = new UIRow().setTextContent( strings.getKey( 'menubar/file/newProject' ) ).addClass( 'option' ).addClass( 'submenu-title' );
		newProjectSubmenuTitle.onMouseOver( function (_) {

			var top = this.dom.getBoundingClientRect().top;
			var right = this.dom.getBoundingClientRect().right;
			var paddingTop =  Std.parseFloat( Browser.window.getComputedStyle(this.dom).paddingTop );
			newProjectSubmenu.setLeft( '${right}px' );
			newProjectSubmenu.setTop( '${top - paddingTop}px' );
			newProjectSubmenu.setDisplay( 'block' );

		} );
		newProjectSubmenuTitle.onMouseOut( function (_) {

			newProjectSubmenu.setDisplay( 'none' );

		} );
		options.add( newProjectSubmenuTitle );

		var newProjectSubmenu = new UIPanel().setPosition( 'fixed' ).addClass( 'options' ).setDisplay( 'none' );
		newProjectSubmenuTitle.add( newProjectSubmenu );

		// New Project / Empty

		var option = new UIRow().setTextContent( strings.getKey( 'menubar/file/newProject/empty' ) ).setClass( 'option' );
		option.onClick( function (_) {

			if ( Browser.window.confirm( strings.getKey( 'prompt/file/open' ) ) ) {

				editor.clear();

			}

		} );
		newProjectSubmenu.add( option );

		//

		newProjectSubmenu.add( new UIHorizontalRule() );

		// New Project / ...

		var examples = [
			{ title: 'menubar/file/newProject/Arkanoid', file: 'arkanoid.app.json' },
			{ title: 'menubar/file/newProject/Camera', file: 'camera.app.json' },
			{ title: 'menubar/file/newProject/Particles', file: 'particles.app.json' },
			{ title: 'menubar/file/newProject/Pong', file: 'pong.app.json' },
			{ title: 'menubar/file/newProject/Shaders', file: 'shaders.app.json' }
		];

		var loader = new FileLoader();

		for ( i in 0...examples.length ) {

			var example = examples[ i ];

			var option = new UIRow();
			option.setClass( 'option' );
			option.setTextContent( strings.getKey( example.title ) );
			option.onClick( function (_ ) {

				if ( Browser.window.confirm( strings.getKey( 'prompt/file/open' ) ) ) {

					loader.load( 'examples/${example.file}', function ( text ) {

						editor.clear();
						editor.fromJSON( JSON.parse( text ) );

					} );

				}

			} );
			newProjectSubmenu.add( option );

		}


		// Save

		option = new UIRow()
			.addClass( 'option' )
			.setTextContent( strings.getKey( 'menubar/file/save' ) )
			.onClick( function (_) {

				var json = editor.toJSON();
				var blob = new Blob( [ JSON.stringify( json ) ], { type: 'application/json' } );
				editor.utils.save( blob, 'project.json' );

			} );

		options.add( option );

		// Open

		var openProjectForm = Browser.document.createElement("form");
		openProjectForm.style.display = 'none';
		Browser.document.body.appendChild(openProjectForm);

		var openProjectInput = Browser.document.createElement("input");
		openProjectInput.multiple = false;
		openProjectInput.type = 'file';
		openProjectInput.accept = '.json';
		openProjectInput.addEventListener( 'change', function (_) {

			var file = openProjectInput.files[ 0 ];

			if ( file == null ) return;

			var fileReader = new FileReader();

			fileReader.onload = function(e) {

				var json = JSON.parse(e.target.result);

				var onEditorCleared = function(_) {

					editor.fromJSON( json );

					editor.signals.editorCleared.remove( onEditorCleared );

				};

				editor.signals.editorCleared.add( onEditorCleared );

				editor.clear();

			};

			fileReader.onerror = function(_) {

				Browser.window.alert( strings.getKey( 'prompt/file/failedToOpenProject' ) );

			};

			fileReader.readAsText(file);

		} );
		openProjectForm.appendChild( openProjectInput );

		option = new UIRow()
			.addClass( 'option' )
			.setTextContent( strings.getKey( 'menubar/file/open' ) )
			.onClick( function (_) {

				if ( Browser.window.confirm( strings.getKey( 'prompt/file/open' ) ) ) {

					openProjectInput.click();

				}

			} );

		options.add( option );

		//

		options.add( new UIHorizontalRule() );

		// Import

		var form = Browser.document.createElement("form");
		form.style.display = 'none';
		Browser.document.body.appendChild(form);

		var fileInput = Browser.document.createElement("input");
		fileInput.multiple = true;
		fileInput.type = 'file';
		fileInput.addEventListener( 'change', function (_) {

			editor.loader.loadFiles( fileInput.files );
			form.reset();

		} );
		form.appendChild( fileInput );

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( strings.getKey( 'menubar/file/import' ) );
		option.onClick( function (_) {

			fileInput.click();

		} );
		options.add( option );

		// Export

		var fileExportSubmenuTitle = new UIRow().setTextContent( strings.getKey( 'menubar/file/export' ) ).addClass( 'option' ).addClass( 'submenu-title' );
		fileExportSubmenuTitle.onMouseOver( function (_) {

			var top = this.dom.getBoundingClientRect().top;
			var right = this.dom.getBoundingClientRect().right;
			var paddingTop =  Std.parseFloat( Browser.window.getComputedStyle(this.dom).paddingTop );
			fileExportSubmenu.setLeft( '${right}px' );
			fileExportSubmenu.setTop( '${top - paddingTop}px' );
			fileExportSubmenu.setDisplay( 'block' );

		} );
		fileExportSubmenuTitle.onMouseOut( function (_) {

			fileExportSubmenu.setDisplay( 'none' );

		} );
		options.add( fileExportSubmenuTitle );

		var fileExportSubmenu = new UIPanel().setPosition( 'fixed' ).addClass( 'options' ).setDisplay( 'none' );
		fileExportSubmenuTitle.add( fileExportSubmenu );

		// Export DRC

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'DRC' );
		option.onClick( function (_) {

			var object = editor.selected;

			if ( object == null || ! Std.isOfType(object, three.Mesh) ) {

				Browser.window.alert( strings.getKey( 'prompt/file/export/noMeshSelected' ) );
				return;

			}

			var exporter = new DRACOExporter();

			var options = {
				decodeSpeed: 5,
				encodeSpeed: 5,
				encoderMethod: DRACOExporter.MESH_EDGEBREAKER_ENCODING,
				quantization: [ 16, 8, 8, 8, 8 ],
				exportUvs: true,
				exportNormals: true,
				exportColor: untyped object.geometry.hasAttribute( 'color' )
			};

			// TODO: Change to DRACOExporter's parse( geometry, onParse )?
			var result = exporter.parse( object, options );
			editor.utils.saveArrayBuffer( result, 'model.drc' );

		} );
		fileExportSubmenu.add( option );

		// Export GLB

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'GLB' );
		option.onClick( function (_) {

			var scene = editor.scene;
			var animations = getAnimations( scene );

			var optimizedAnimations = [];

			for ( animation in animations ) {

				optimizedAnimations.push( animation.clone().optimize() );

			}

			var exporter = new GLTFExporter();

			exporter.parse( scene, function ( result ) {

				editor.utils.saveArrayBuffer( result, 'scene.glb' );

			}, { binary: true, animations: optimizedAnimations } );

		} );
		fileExportSubmenu.add( option );

		// Export GLTF

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'GLTF' );
		option.onClick( function (_)  {

			var scene = editor.scene;
			var animations = getAnimations( scene );

			var optimizedAnimations = [];

			for ( animation in animations ) {

				optimizedAnimations.push( animation.clone().optimize() );

			}

			var exporter = new GLTFExporter();

			exporter.parse( scene, function ( result ) {

				editor.utils.saveString( JSON.stringify( result, null, 2 ), 'scene.gltf' );

			}, { animations: optimizedAnimations } );


		} );
		fileExportSubmenu.add( option );

		// Export OBJ

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'OBJ' );
		option.onClick( function (_) {

			var object = editor.selected;

			if ( object == null ) {

				Browser.window.alert( strings.getKey( 'prompt/file/export/noObjectSelected' ) );
				return;

			}

			var exporter = new OBJExporter();

			editor.utils.saveString( exporter.parse( object ), 'model.obj' );

		} );
		fileExportSubmenu.add( option );

		// Export PLY (ASCII)

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'PLY' );
		option.onClick( function (_) {

			var exporter = new PLYExporter();

			exporter.parse( editor.scene, function ( result ) {

				editor.utils.saveArrayBuffer( result, 'model.ply' );

			} );

		} );
		fileExportSubmenu.add( option );

		// Export PLY (BINARY)

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'PLY (BINARY)' );
		option.onClick( function (_) {

			var exporter = new PLYExporter();

			exporter.parse( editor.scene, function ( result ) {

				editor.utils.saveArrayBuffer( result, 'model-binary.ply' );

			}, { binary: true } );

		} );
		fileExportSubmenu.add( option );

		// Export STL (ASCII)

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'STL' );
		option.onClick( function (_)  {

			var exporter = new STLExporter();

			editor.utils.saveString( exporter.parse( editor.scene ), 'model.stl' );

		} );
		fileExportSubmenu.add( option );

		// Export STL (BINARY)

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'STL (BINARY)' );
		option.onClick( function (_)  {

			var exporter = new STLExporter();

			editor.utils.saveArrayBuffer( exporter.parse( editor.scene, { binary: true } ), 'model-binary.stl' );

		} );
		fileExportSubmenu.add( option );

		// Export USDZ

		option = new UIRow();
		option.setClass( 'option' );
		option.setTextContent( 'USDZ' );
		option.onClick( async function (_)  {

			var exporter = new USDZExporter();

			editor.utils.saveArrayBuffer( await exporter.parseAsync( editor.scene ), 'model.usdz' );

		} );
		fileExportSubmenu.add( option );

		return container;

	}

	static function getAnimations( scene : three.Scene) : Array<AnimationClip> {

		var animations = [];

		scene.traverse( function ( object ) {

			if ( object.animations != null) {
				animations = animations.concat(object.animations);
			}

		} );

		return animations;

	}

}