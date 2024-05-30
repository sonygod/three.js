import js.Browser.window;
import js.Lib.three.editor.js.libs.ui.UIPanel;
import js.Lib.three.editor.js.libs.ui.UIRow;
import js.Lib.three.editor.js.libs.ui.UISelect;
import js.Lib.three.editor.js.libs.ui.UISpan;
import js.Lib.three.editor.js.libs.ui.UIText;
import js.Lib.three.editor.js.Sidebar.Settings.Shortcuts.SidebarSettingsShortcuts;
import js.Lib.three.editor.js.Sidebar.Settings.History.SidebarSettingsHistory;

class SidebarSettings {

    public function new(editor:Dynamic) {

        var config = editor.config;
        var strings = editor.strings;

        var container = new UISpan();

        var settings = new UIPanel();
        settings.setBorderTop('0');
        settings.setPaddingTop('20px');
        container.add(settings);

        // language

        var options = {
            en: 'English',
            fr: 'Français',
            zh: '中文',
            ja: '日本語',
        };

        var languageRow = new UIRow();
        var language = new UISelect().setWidth('150px');
        language.setOptions(options);

        if (config.getKey('language') !== undefined) {

            language.setValue(config.getKey('language'));

        }

        language.onChange(function () {

            var value = this.getValue();

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