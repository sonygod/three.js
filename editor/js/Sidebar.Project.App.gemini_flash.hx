import three.THREE;
import three.loaders.FileLoader;
import three.loaders.LoadingManager;
import js.lib.ZipSync;
import js.lib.StrToU8;
import ui.UIButton;
import ui.UICheckbox;
import ui.UIPanel;
import ui.UIInput;
import ui.UIRow;
import ui.UIText;

class SidebarProjectApp {

	static function create(editor:THREE.Editor):UIPanel {
		var config = editor.config;
		var signals = editor.signals;
		var strings = editor.strings;

		var container = new UIPanel();
		container.setId('app');

		var headerRow = new UIRow();
		headerRow.add(new UIText(strings.getKey('sidebar/project/app').toUpperCase()));
		container.add(headerRow);

		// Title

		var titleRow = new UIRow();
		var title = new UIInput(config.getKey('project/title')).setLeft('100px').setWidth('150px').onChange(function(_) {
			config.setKey('project/title', title.getValue());
		});

		titleRow.add(new UIText(strings.getKey('sidebar/project/app/title')).setClass('Label'));
		titleRow.add(title);

		container.add(titleRow);

		// Editable

		var editableRow = new UIRow();
		var editable = new UICheckbox(config.getKey('project/editable')).setLeft('100px').onChange(function(_) {
			config.setKey('project/editable', editable.getValue());
		});

		editableRow.add(new UIText(strings.getKey('sidebar/project/app/editable')).setClass('Label'));
		editableRow.add(editable);

		container.add(editableRow);

		// Play/Stop

		var isPlaying = false;

		var playButton = new UIButton(strings.getKey('sidebar/project/app/play'));
		playButton.setWidth('170px');
		playButton.setMarginLeft('120px');
		playButton.setMarginBottom('10px');
		playButton.onClick(function(_) {
			if (isPlaying == false) {
				isPlaying = true;
				playButton.setTextContent(strings.getKey('sidebar/project/app/stop'));
				signals.startPlayer.dispatch();
			} else {
				isPlaying = false;
				playButton.setTextContent(strings.getKey('sidebar/project/app/play'));
				signals.stopPlayer.dispatch();
			}
		});

		container.add(playButton);

		// Publish

		var publishButton = new UIButton(strings.getKey('sidebar/project/app/publish'));
		publishButton.setWidth('170px');
		publishButton.setMarginLeft('120px');
		publishButton.setMarginBottom('10px');
		publishButton.onClick(function(_) {

			var toZip = new Map<String, js.lib.Uint8Array>();

			var output = editor.toJSON();
			output.metadata.type = 'App';
			delete output.history;

			var outputString = JSON.stringify(output, null, '\t');
			outputString = ~/([\n\t]+)([\d\.e\-\[\]]+)/g.replace(outputString, '$2');

			toZip.set('app.json', StrToU8(outputString));

			var title = config.getKey('project/title');

			var manager = new LoadingManager(function(_) {
				var zipped = ZipSync(toZip, { level : 9 });
				var blob = new js.html.Blob([zipped.buffer], { type : 'application/zip'});
				editor.utils.save(blob, (title != '' ? title : 'untitled') + '.zip');
			});

			var loader = new FileLoader(manager);

			loader.load('js/libs/app/index.html', function(content:String) {
				var contentString = content;
				contentString = ~/<!-- title -->/g.replace(contentString, title);

				var includes = [];

				contentString = ~/<!-- includes -->/g.replace(contentString, includes.join('\n\t\t'));

				var editButton = '';

				if (config.getKey('project/editable')) {
					editButton = [
						'			let button = document.createElement( \'a\' );',
						'			button.href = \'https://threejs.org/editor/#file=\' + location.href.split( \'/\' ).slice( 0, - 1 ).join( \'/\' ) + \'/app.json\';',
						'			button.style.cssText = \'position: absolute; bottom: 20px; right: 20px; padding: 10px 16px; color: #fff; border: 1px solid #fff; border-radius: 20px; text-decoration: none;\';',
						'			button.target = \'_blank\';',
						'			button.textContent = \'EDIT\';',
						'			document.body.appendChild( button );'
					].join('\n');
				}

				contentString = ~/\t\t\t\/\* edit button \*\//g.replace(contentString, editButton);

				toZip.set('index.html', StrToU8(contentString));
			});

			loader.load('js/libs/app.js', function(content:String) {
				toZip.set('js/app.js', StrToU8(content));
			});

			loader.load('../build/three.module.js', function(content:String) {
				toZip.set('js/three.module.js', StrToU8(content));
			});

		});
		container.add(publishButton);

		// Signals

		signals.editorCleared.add(function(_) {
			title.setValue('');
			config.setKey('project/title', '');
		});

		return container;
	}

}