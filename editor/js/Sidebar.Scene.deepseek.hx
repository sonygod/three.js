import three.THREE;
import ui.UIPanel;
import ui.UIBreak;
import ui.UIRow;
import ui.UIColor;
import ui.UISelect;
import ui.UIText;
import ui.UINumber;
import ui.UIOutliner;
import ui.UITexture;

class SidebarScene {

	var signals:Dynamic;
	var strings:Dynamic;
	var editor:Dynamic;
	var nodeStates:WeakMap<Dynamic, Bool>;
	var outliner:UIOutliner;
	var backgroundType:UISelect;
	var backgroundColor:UIColor;
	var backgroundTexture:UITexture;
	var backgroundEquirectangularTexture:UITexture;
	var backgroundBlurriness:UINumber;
	var backgroundIntensity:UINumber;
	var backgroundRotation:UINumber;
	var environmentType:UISelect;
	var environmentEquirectangularTexture:UITexture;
	var fogType:UISelect;
	var fogColor:UIColor;
	var fogNear:UINumber;
	var fogFar:UINumber;
	var fogDensity:UINumber;
	var ignoreObjectSelectedSignal:Bool;

	public function new(editor:Dynamic) {
		this.editor = editor;
		this.signals = editor.signals;
		this.strings = editor.strings;
		this.nodeStates = new WeakMap();
		this.ignoreObjectSelectedSignal = false;
		this.initUI();
		this.refreshUI();
		this.initEvents();
	}

	private function initUI() {
		var container = new UIPanel();
		container.setBorderTop('0');
		container.setPaddingTop('20px');

		this.outliner = new UIOutliner(editor);
		this.outliner.setId('outliner');
		this.outliner.onChange(this.onOutlinerChange);
		this.outliner.onDblClick(this.onOutlinerDblClick);
		container.add(this.outliner);
		container.add(new UIBreak());

		this.backgroundType = new UISelect().setOptions({
			'None': '',
			'Color': 'Color',
			'Texture': 'Texture',
			'Equirectangular': 'Equirect'
		}).setWidth('150px');
		this.backgroundType.onChange(this.onBackgroundChanged);
		container.add(this.backgroundType);

		this.backgroundColor = new UIColor().setValue('#000000').setMarginLeft('8px').onInput(this.onBackgroundChanged);
		container.add(this.backgroundColor);

		this.backgroundTexture = new UITexture(editor).setMarginLeft('8px').onChange(this.onBackgroundChanged);
		this.backgroundTexture.setDisplay('none');
		container.add(this.backgroundTexture);

		this.backgroundEquirectangularTexture = new UITexture(editor).setMarginLeft('8px').onChange(this.onBackgroundChanged);
		this.backgroundEquirectangularTexture.setDisplay('none');
		container.add(this.backgroundEquirectangularTexture);

		this.backgroundBlurriness = new UINumber(0).setWidth('40px').setRange(0, 1).onChange(this.onBackgroundChanged);
		this.backgroundIntensity = new UINumber(1).setWidth('40px').setRange(0, Infinity).onChange(this.onBackgroundChanged);
		this.backgroundRotation = new UINumber(0).setWidth('40px').setRange(-180, 180).setStep(10).setNudge(0.1).setUnit('°').onChange(this.onBackgroundChanged);

		this.environmentType = new UISelect().setOptions({
			'None': '',
			'Background': 'Background',
			'Equirectangular': 'Equirect',
			'ModelViewer': 'ModelViewer'
		}).setWidth('150px');
		this.environmentType.onChange(this.onEnvironmentChanged);
		container.add(this.environmentType);

		this.environmentEquirectangularTexture = new UITexture(editor).setMarginLeft('8px').onChange(this.onEnvironmentChanged);
		this.environmentEquirectangularTexture.setDisplay('none');
		container.add(this.environmentEquirectangularTexture);

		this.fogType = new UISelect().setOptions({
			'None': '',
			'Fog': 'Linear',
			'FogExp2': 'Exponential'
		}).setWidth('150px');
		this.fogType.onChange(this.onFogChanged);
		container.add(this.fogType);

		this.fogColor = new UIColor().setValue('#aaaaaa').onInput(this.onFogSettingsChanged);
		container.add(this.fogColor);

		this.fogNear = new UINumber(0.1).setWidth('40px').setRange(0, Infinity).onChange(this.onFogSettingsChanged);
		container.add(this.fogNear);

		this.fogFar = new UINumber(50).setWidth('40px').setRange(0, Infinity).onChange(this.onFogSettingsChanged);
		container.add(this.fogFar);

		this.fogDensity = new UINumber(0.05).setWidth('40px').setRange(0, 0.1).setStep(0.001).setPrecision(3).onChange(this.onFogSettingsChanged);
	}

	private function onOutlinerChange() {
		this.ignoreObjectSelectedSignal = true;
		this.editor.selectById(Std.parseInt(this.outliner.getValue()));
		this.ignoreObjectSelectedSignal = false;
	}

	private function onOutlinerDblClick() {
		this.editor.focusById(Std.parseInt(this.outliner.getValue()));
	}

	private function onBackgroundChanged() {
		this.signals.sceneBackgroundChanged.dispatch(
			this.backgroundType.getValue(),
			this.backgroundColor.getHexValue(),
			this.backgroundTexture.getValue(),
			this.backgroundEquirectangularTexture.getValue(),
			this.backgroundBlurriness.getValue(),
			this.backgroundIntensity.getValue(),
			this.backgroundRotation.getValue()
		);
	}

	private function onEnvironmentChanged() {
		this.signals.sceneEnvironmentChanged.dispatch(
			this.environmentType.getValue(),
			this.environmentEquirectangularTexture.getValue()
		);
	}

	private function onFogChanged() {
		this.signals.sceneFogChanged.dispatch(
			this.fogType.getValue(),
			this.fogColor.getHexValue(),
			this.fogNear.getValue(),
			this.fogFar.getValue(),
			this.fogDensity.getValue()
		);
	}

	private function onFogSettingsChanged() {
		this.signals.sceneFogSettingsChanged.dispatch(
			this.fogType.getValue(),
			this.fogColor.getHexValue(),
			this.fogNear.getValue(),
			this.fogFar.getValue(),
			this.fogDensity.getValue()
		);
	}

	private function refreshUI() {
		// ...
	}

	private function initEvents() {
		// ...
	}
}