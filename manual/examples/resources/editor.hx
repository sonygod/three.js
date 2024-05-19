import haxe.ds.StringMap;
import js.Browser;
import js.Node;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.IFrameElement;
import js.html.InputElement;

class LessonEditor {
    static var rootScriptInfo:ScriptInfo;
    static var scriptInfos:StringMap<ScriptInfo>;
    static var html:String;
    
    static function getQuery(s:String):StringMap<String> {
        s = s === undefined ? Browser.window.location.search : s;
        if (s[0] === '?') {
            s = s.substring(1);
        }
        var query:StringMap<String> = {};
        s.split('&').forEach(function(pair:String) {
            var parts:Array<String> = pair.split('=');
            query[parts[0]] = Std.parseInt(parts[1]);
        });
        return query;
    }
    
    static function getSearch(url:String):StringMap<String> {
        // yea I know this is not perfect but whatever
        var s:String = url.indexOf('?');
        return s < 0 ? {} : getQuery(url.substring(s));
    }

    static function getFQUrl(path:String, baseUrl:String = Browser.window.location.href):String {
        var url = Url.create(path, baseUrl);
        return url.href;
    }

    static async function getHTML(url:String):String {
        var req = await fetch(url);
        return await req.text();
    }

    static function getPrefix(url:String):String {
        var u = Url.create(url, Browser.window.location.href);
        var prefix = u.origin + dirname(u.pathname);
        return prefix;
    }

    static function fixCSSLinks(url:String, source:String):String {
        var cssUrlRE1 = /(url\(')(.*?)('\))/g;
        var cssUrlRE2 = /(url\()(.*?)(\))/g;
        var prefix = getPrefix(url);

        function addPrefix(url:String):String {
            return url.indexOf('://') < 0 && url.startsWith('data:') ? `${prefix}/${url}` : url;
        }

        function makeFQ(match:String, prefix:String, url:String, suffix:String):String {
            return `${prefix}${addPrefix(url)}${suffix}`;
        }

        source = source.replace(cssUrlRE1, makeFQ);
        source = source.replace(cssUrlRE2, makeFQ);
        return source;
    }

    // hack: scriptInfo is undefined for html and css
    // should try to include html and css in scriptInfos
    static function addSource(type:String, name:String, source:String, scriptInfo:ScriptInfo) {
        htmlParts[type].sources.push( { source, name, scriptInfo } );
    }

    static function safeStr(s:String):String {
        return s === undefined ? '' : s;
    }

    static async function parseHTML(url:String, html:String) {
        html = fixSourceLinks(url, html);

        html = html.replace(/<div class="description">[^]*?<\/div>/, '');

        var styleRE = /<style>([^]*?)<\/style>/i;
        var titleRE = /<title>([^]*?)<\/title>/i;
        var bodyRE = /<body>([^]*?)<\/body>/i;
        var inlineScriptRE = /<script>([^]*?)<\/script>/i;
        var inlineModuleScriptRE = /<script type="module">([^]*?)<\/script>/i;
        var externalScriptRE = /(<!--(?:(?!-->)[\s\S])*?-->\n){0,1}<script\s+([^>]*?)(type="module"\s+)?src\s*=\s*"(.*?)