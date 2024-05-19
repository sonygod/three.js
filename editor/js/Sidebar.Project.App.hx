package three.js.editor.js;

import three.*;

using three.addons.libs.fflate.Fflate;

class SidebarProjectApp {
	function new(editor:Editor) {
		var config = editor.config;
		var signals = editor.signals;
		var strings = editor.strings;
		var save = editor.utils.save;

		var container = new UIPanel();
		container.setId('app');

		var headerRow = new UIRow();
		headerRow.add(new UIText(strings.getKey('sidebar/project/app').toUpperCase()));
		container.add(headerRow);

		// Title

		var titleRow = new UIRow();
		var title = new UIInput(config.getKey('project/title')).setLeft('100px').setWidth('150px');
		title.onChange(function() {
			config.setKey('project/title', title.getValue());
		});
		titleRow.add(new UIText(strings.getKey('sidebar/project/app/title')).setClass('Label'));
		titleRow.add(title);
		container.add(titleRow);

		// Editable

		var editableRow = new UIRow();
		var editable = new UICheckbox(config.getKey('project/editable')).setLeft('100px');
		editable.onChange(function() {
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
		playButton.onClick(function() {
			if (!isPlaying) {
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
		publishButton.onClick(function() {
			var toZip = {};

			var output = editor.toJSON();
			output.metadata.type = 'App';
			delete output.history;

			output = haxe.Json.stringify(output, null, '\t');
			output = output.replace(new EReg('[\n\t]+([\\d\\.e\\-\\[\\]]+)', 'g'), '$1');

			toZip['app.json'] = strToU8(output);

			var title = config.getKey('project/title');

			var manager = new THREE.LoadingManager(function() {
				var zipped = zipSync(toZip, { level: 9 });

				var blob = new Blob([zipped.buffer], { type: 'application/zip' });

				save(blob, (title != '' ? title : 'untitled') + '.zip');
			});

			var loader = new THREE.FileLoader(manager);
			loader.load('js/libs/app/index.html', function(content) {
				content = content.replace('<!-- title -->', title);

				var includes = [];

				content = content.replace('<!-- includes -->', includes.join('\n\t\t'));

				var editButton = '';

				if (config.getKey('project/editable')) {
					editButton = [
						'			let button = document.createElement( \'a\' );',
						'			button.href = \'https://threejs.org/editor/#file=\' + location.href.split( \'/\' ).slice( 0, -1 ).join( \'/\' ) + \'/app.json\';',
						'			button.style.cssText = \'position: absolute; bottom: 20px; right: 20px; padding: 10px 16px; color: #fff; border: 1px solid #fff; border-radius: 20px; text-decoration: none;\';',
						'			button.target = \'_blank\';',
						'			button.textContent = \'EDIT\';',
						'			document.body.appendChild( button );',
					].join('\n');
				}

				content = content.replace('\t\t\t/* edit button */', editButton);

				toZip['index.html'] = strToU8(content);
			});
			loader.load('js/libs/app.js', function(content) {
				toZip['js/app.js'] = strToU8(content);
			});
			loader.load('../build/three.module.js', function(content) {
				toZip['js/three.module.js'] = strToU8(content);
			});
		});
		container.add(publishButton);

		// Signals

		signals.editorCleared.add(function() {
			title.setValue('');
			config.setKey('project/title', '');
		});

		return container;
	}
}