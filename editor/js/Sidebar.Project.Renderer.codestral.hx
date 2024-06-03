import three.WebGLRenderer;
import three.PCFShadowMap;
import three.NoToneMapping;
import ui.UINumber;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import ui.UIBoolean;

class SidebarProjectRenderer {

    var editor: Editor;
    var config: Config;
    var signals: Signals;
    var strings: Strings;
    var currentRenderer: WebGLRenderer;
    var container: UIPanel;
    var antialiasBoolean: UIBoolean;
    var shadowsBoolean: UIBoolean;
    var shadowTypeSelect: UISelect;
    var toneMappingSelect: UISelect;
    var toneMappingExposure: UINumber;

    public function new(editor: Editor) {
        this.editor = editor;
        this.config = editor.config;
        this.signals = editor.signals;
        this.strings = editor.strings;

        this.container = new UIPanel();
        this.container.setBorderTop('0px');

        // Antialias
        var antialiasRow = new UIRow();
        this.container.add(antialiasRow);

        antialiasRow.add(new UIText(this.strings.getKey('sidebar/project/antialias')).setClass('Label'));

        this.antialiasBoolean = new UIBoolean(this.config.getKey('project/renderer/antialias')).onChange(createRenderer);
        antialiasRow.add(this.antialiasBoolean);

        // Shadows
        var shadowsRow = new UIRow();
        this.container.add(shadowsRow);

        shadowsRow.add(new UIText(this.strings.getKey('sidebar/project/shadows')).setClass('Label'));

        this.shadowsBoolean = new UIBoolean(this.config.getKey('project/renderer/shadows')).onChange(updateShadows);
        shadowsRow.add(this.shadowsBoolean);

        this.shadowTypeSelect = new UISelect().setOptions({
            '0': 'Basic',
            '1': 'PCF',
            '2': 'PCF Soft',
        }).setWidth('125px').onChange(updateShadows);
        this.shadowTypeSelect.setValue(this.config.getKey('project/renderer/shadowType'));
        shadowsRow.add(this.shadowTypeSelect);

        // Tonemapping
        var toneMappingRow = new UIRow();
        this.container.add(toneMappingRow);

        toneMappingRow.add(new UIText(this.strings.getKey('sidebar/project/toneMapping')).setClass('Label'));

        this.toneMappingSelect = new UISelect().setOptions({
            '0': 'No',
            '1': 'Linear',
            '2': 'Reinhard',
            '3': 'Cineon',
            '4': 'ACESFilmic',
            '6': 'AgX',
            '7': 'Neutral'
        }).setWidth('120px').onChange(updateToneMapping);
        this.toneMappingSelect.setValue(this.config.getKey('project/renderer/toneMapping'));
        toneMappingRow.add(this.toneMappingSelect);

        this.toneMappingExposure = new UINumber(this.config.getKey('project/renderer/toneMappingExposure'));
        this.toneMappingExposure.setDisplay(this.toneMappingSelect.getValue() === '0' ? 'none' : '');
        this.toneMappingExposure.setWidth('30px').setMarginLeft('10px');
        this.toneMappingExposure.setRange(0, 10);
        this.toneMappingExposure.onChange(updateToneMapping);
        toneMappingRow.add(this.toneMappingExposure);

        createRenderer();

        // Signals
        this.signals.editorCleared.add(function() {
            resetRendererSettings();
            updateUI();
            this.signals.rendererUpdated.dispatch();
        });

        this.signals.rendererUpdated.add(function() {
            updateConfig();
        });
    }

    private function createRenderer() {
        this.currentRenderer = new WebGLRenderer({ antialias: this.antialiasBoolean.getValue() });
        this.currentRenderer.shadowMap.enabled = this.shadowsBoolean.getValue();
        this.currentRenderer.shadowMap.type = Std.parseInt(this.shadowTypeSelect.getValue());
        this.currentRenderer.toneMapping = Std.parseInt(this.toneMappingSelect.getValue());
        this.currentRenderer.toneMappingExposure = this.toneMappingExposure.getValue();

        this.signals.rendererCreated.dispatch(this.currentRenderer);
        this.signals.rendererUpdated.dispatch();
    }

    private function updateShadows() {
        this.currentRenderer.shadowMap.enabled = this.shadowsBoolean.getValue();
        this.currentRenderer.shadowMap.type = Std.parseInt(this.shadowTypeSelect.getValue());
        this.signals.rendererUpdated.dispatch();
    }

    private function updateToneMapping() {
        this.toneMappingExposure.setDisplay(this.toneMappingSelect.getValue() === '0' ? 'none' : '');
        this.currentRenderer.toneMapping = Std.parseInt(this.toneMappingSelect.getValue());
        this.currentRenderer.toneMappingExposure = this.toneMappingExposure.getValue();
        this.signals.rendererUpdated.dispatch();
    }

    private function resetRendererSettings() {
        this.currentRenderer.shadowMap.enabled = true;
        this.currentRenderer.shadowMap.type = PCFShadowMap;
        this.currentRenderer.toneMapping = NoToneMapping;
        this.currentRenderer.toneMappingExposure = 1;
    }

    private function updateUI() {
        this.shadowsBoolean.setValue(this.currentRenderer.shadowMap.enabled);
        this.shadowTypeSelect.setValue(Std.string(this.currentRenderer.shadowMap.type));
        this.toneMappingSelect.setValue(Std.string(this.currentRenderer.toneMapping));
        this.toneMappingExposure.setValue(this.currentRenderer.toneMappingExposure);
        this.toneMappingExposure.setDisplay(this.currentRenderer.toneMapping === 0 ? 'none' : '');
    }

    private function updateConfig() {
        this.config.setKey(
            'project/renderer/antialias', this.antialiasBoolean.getValue(),
            'project/renderer/shadows', this.shadowsBoolean.getValue(),
            'project/renderer/shadowType', Std.parseInt(this.shadowTypeSelect.getValue()),
            'project/renderer/toneMapping', Std.parseInt(this.toneMappingSelect.getValue()),
            'project/renderer/toneMappingExposure', this.toneMappingExposure.getValue()
        );
    }
}