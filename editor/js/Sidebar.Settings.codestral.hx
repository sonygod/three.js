import js.Browser.document;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UISpan;
import ui.UIText;

class SidebarSettings {

    public function new(editor:Editor) {

        var config:Dynamic = editor.config;
        var strings:Dynamic = editor.strings;

        var container:UISpan = new UISpan();

        var settings:UIPanel = new UIPanel();
        settings.setBorderTop('0');
        settings.setPaddingTop('20px');
        container.add(settings);

        // language

        var options:haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();
        options.set('en', 'English');
        options.set('fr', 'Français');
        options.set('zh', '中文');
        options.set('ja', '日本語');

        var languageRow:UIRow = new UIRow();
        var language:UISelect = new UISelect().setWidth('150px');
        language.setOptions(options);

        if (config.getKey('language') != null) {
            language.setValue(config.getKey('language'));
        }

        language.onChange(function () {
            var value:String = this.getValue();
            editor.config.setKey('language', value);
        });

        languageRow.add(new UIText(strings.getKey('sidebar/settings/language')).setClass('Label'));
        languageRow.add(language);

        settings.add(languageRow);

        //

        container.add(new SidebarSettingsShortcuts(editor));
        container.add(new SidebarSettingsHistory(editor));

        return container;

    }
}