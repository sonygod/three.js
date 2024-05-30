import js.three.WebGLRenderer;
import js.three.Constants;

class SidebarProjectRenderer {
    static public function new(editor:Editor) {
        var config = editor.config;
        var signals = editor.signals;
        var strings = editor.strings;

        var currentRenderer = null;

        var container = UIPanel.create();
        container.setBorderTop('0px');

        // Antialias
        var antialiasRow = UIRow.create();
        container.add(antialiasRow);

        antialiasRow.add(UIText.create(strings.getKey('sidebar/project/antialias')).setClass('Label'));

        var antialiasBoolean = UIBoolean.create(config.getKey('project/renderer/antialias')).onChange(createRenderer);
        antialiasRow.add(antialiasBoolean);

        // Shadows
        var shadowsRow = UIRow.create();
        container.add(shadowsRow);

        shadowsRow.add(UIText.create(strings.getKey('sidebar/project/shadows')).setClass('Label'));

        var shadowsBoolean = UIBoolean.create(config.getKey('project/renderer/shadows')).onChange(updateShadows);
        shadowsRow.add(shadowsBoolean);

        var shadowTypeSelect = UISelect.create().setOptions({
            '0': 'Basic',
            '1': 'PCF',
            '2': 'PCF Soft',
            // '3': 'VSM'
        }).setWidth('125px').onChange(updateShadows);
        shadowTypeSelect.setValue(Std.string(config.getKey('project/renderer/shadowType')));
        shadowsRow.add(shadowTypeSelect);

        function updateShadows() {
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = $if (shadowTypeSelect.getValue() == '0')
                $then(Constants.BasicShadowMap)
                $else $if (shadowTypeSelect.getValue() == '1')
                    $then(Constants.PCFShadowMap)
                    $else (Constants.PCFSoftShadowMap);

            signals.rendererUpdated.dispatch();
        }

        // Tonemapping
        var toneMappingRow = UIRow.create();
        container.add(toneMappingRow);

        toneMappingRow.add(UIText.create(strings.getKey('sidebar/project/toneMapping')).setClass('Label'));

        var toneMappingSelect = UISelect.create().setOptions({
            '0': 'No',
            '1': 'Linear',
            '2': 'Reinhard',
            '3': 'Cineon',
            '4': 'ACESFilmic',
            '6': 'AgX',
            '7': 'Neutral'
        }).setWidth('120px').onChange(updateToneMapping);
        toneMappingSelect.setValue(Std.string(config.getKey('project/renderer/toneMapping')));
        toneMappingRow.add(toneMappingSelect);

        var toneMappingExposure = UINumber.create(config.getKey('project/renderer/toneMappingExposure'));
        toneMappingExposure.setDisplay(toneMappingSelect.getValue() == '0' ? 'none' : '');
        toneMappingExposure.setWidth('30px').setMarginLeft('10px');
        toneMappingExposure.setRange(0, 10);
        toneMappingExposure.onChange(updateToneMapping);
        toneMappingRow.add(toneMappingExposure);

        function updateToneMapping() {
            toneMappingExposure.setDisplay(toneMappingSelect.getValue() == '0' ? 'none' : '');

            currentRenderer.toneMapping = $if (toneMappingSelect.getValue() == '0')
                $then(Constants.NoToneMapping)
                $else $if (toneMappingSelect.getValue() == '1')
                    $then(Constants.LinearToneMapping)
                    $else $if (toneMappingSelect.getValue() == '2')
                        $then(Constants.ReinhardToneMapping)
                        $else $if (toneMappingSelect.getValue() == '3')
                            $then(Constants.CineonToneMapping)
                            $else $if (toneMappingSelect.getValue() == '4')
                                $then(Constants.ACESFilmicToneMapping)
                                $else $if (toneMappingSelect.getValue() == '6')
                                    $then(Constants.AgxToneMapping)
                                    $else (Constants.Uncharted2ToneMapping);

            currentRenderer.toneMappingExposure = toneMappingExposure.getValue();
            signals.rendererUpdated.dispatch();
        }

        // Create renderer
        function createRenderer() {
            currentRenderer = WebGLRenderer.create({ antialias: antialiasBoolean.getValue() });
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = $if (shadowTypeSelect.getValue() == '0')
                $then(Constants.BasicShadowMap)
                $else $if (shadowTypeSelect.getValue() == '1')
                    $then(Constants.PCFShadowMap)
                    $else (Constants.PCFSoftShadowMap);
            currentRenderer.toneMapping = $if (toneMappingSelect.getValue() == '0')
                $then(Constants.NoToneMapping)
                $else $if (toneMappingSelect.getValue() == '1')
                    $then(Constants.LinearToneMapping)
                    $else $if (toneMappingSelect.getValue() == '2')
                        $then(Constants.ReinhardToneMapping)
                        $else $if (toneMappingSelect.getValue() == '3')
                            $then(Constants.CineonToneMapping)
                            $else $if (toneMappingSelect.getValue() == '4')
                                $then(Constants.ACESFilmicToneMapping)
                                $else $if (toneMappingSelect.getValue() == '6')
                                    $then(Constants.AgxToneMapping)
                                    $else (Constants.Uncharted2ToneMapping);
            currentRenderer.toneMappingExposure = toneMappingExposure.getValue();

            signals.rendererCreated.dispatch(currentRenderer);
            signals.rendererUpdated.dispatch();
        }

        createRenderer();

        // Signals
        signals.editorCleared.add(function() {
            currentRenderer.shadowMap.enabled = true;
            currentRenderer.shadowMap.type = Constants.PCFShadowMap;
            currentRenderer.toneMapping = Constants.NoToneMapping;
            currentRenderer.toneMappingExposure = 1;

            shadowsBoolean.setValue(currentRenderer.shadowMap.enabled);
            shadowTypeSelect.setValue('1'); // PCF
            toneMappingSelect.setValue('0'); // No
            toneMappingExposure.setValue(currentRenderer.toneMappingExposure);
            toneMappingExposure.setDisplay(currentRenderer.toneMapping == Constants.NoToneMapping ? 'none' : '');

            signals.rendererUpdated.dispatch();
        });

        signals.rendererUpdated.add(function() {
            config.setKey('project/renderer/antialias', antialiasBoolean.getValue());
            config.setKey('project/renderer/shadows', shadowsBoolean.getValue());
            config.setKey('project/renderer/shadowType', shadowTypeSelect.getValue());
            config.setKey('project/renderer/toneMapping', toneMappingSelect.getValue());
            config.setKey('project/renderer/toneMappingExposure', toneMappingExposure.getValue());
        });

        return container;
    }
}