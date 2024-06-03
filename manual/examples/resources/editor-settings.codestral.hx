class EditorSettings {
    static function dirname(path:String):String {
        var ndx = path.lastIndexOf('/');
        return path.substring(0, ndx + 1);
    }

    static function getPrefix(url:String):String {
        var u = js.Browser.document.createElement("a");
        u.href = url;
        var prefix = u.origin + EditorSettings.dirname(u.pathname);
        return prefix;
    }

    static function getRootPrefix(url:String):String {
        var u = js.Browser.document.createElement("a");
        u.href = url;
        return u.origin;
    }

    static function removeDotDotSlash(url:String):String {
        var parts = url.split('/');
        var dotDotNdx = -1;
        while ((dotDotNdx = parts.indexOf('..')) != -1) {
            parts.splice(dotDotNdx - 1, 2);
        }
        var newUrl = parts.join('/');
        return newUrl;
    }

    static function fixSourceLinks(url:String, source:String):String {
        var srcRE = new EReg( "(src=)(\")(.*?)(\")()", "g" );
        var linkRE = new EReg( "(href=)(\")(.*?)(\")()", "g" );
        var imageSrcRE = new EReg( "((?:image|img)\\.src = )(\")(.*?)(\")()", "g" );
        var loaderLoadRE = new EReg( "(loader\\.load[a-z]*\\s*\\(\\s*)('|\")(.*?)('|\")", "ig" );
        var loaderArrayLoadRE = new EReg( "(loader\\.load[a-z]*\\(\[)([\\s\\S]*?)(\\])", "ig" );
        var loadFileRE = new EReg( "(loadFile\\s*\\(\\s*)('|\")(.*?)('|\")", "ig" );
        var threejsUrlRE = new EReg( "(.*?)('|\")([^'\"]*?)('|\")([^'\"]*?)(\\/\\*\\s+threejs.org:\\s+url\\s+\\*\\/)", "ig" );
        var arrayLineRE = new EReg( "^(\\s*[\"|'])([\\s\\S]*?)([\"|']*$)", "" );
        var urlPropRE = new EReg( "(url:\\s*)('|\")(.*?)('|\")", "g" );
        var workerRE = new EReg( "(new\\s+Worker\\s*\\(\\s*)('|\")(.*?)('|\")", "g" );
        var importScriptsRE = new EReg( "(importScripts\\s*\\(\\s*)('|\")(.*?)('|\")", "g" );
        var moduleRE = new EReg( "(import.*?)('|\")(.*?)('|\")", "g" );
        var prefix = EditorSettings.getPrefix(url);
        var rootPrefix = EditorSettings.getRootPrefix(url);

        function addCorrectPrefix(url:String):String {
            return (url.startsWith('/'))
                ? rootPrefix + url
                : EditorSettings.removeDotDotSlash((prefix + url).replace(new EReg("/.//g", ""), "/"));
        }

        function addPrefix(url:String):String {
            return url.indexOf('://') < 0 && !url.startsWith('data:') && url[0] != '?'
                ? EditorSettings.removeDotDotSlash(addCorrectPrefix(url))
                : url;
        }

        function makeLinkFDedQuotes(match:ERegMatch, fn:String, q1:String, url:String, q2:String):String {
            return fn + q1 + addPrefix(url) + q2;
        }

        function makeTaggedFDedQuotes(match:ERegMatch, start:String, q1:String, url:String, q2:String, suffix:String):String {
            return start + q1 + addPrefix(url) + q2 + suffix;
        }

        function makeFDedQuotesModule(match:ERegMatch, start:String, q1:String, url:String, q2:String):String {
            return start + q1 + (url.startsWith('.') ? addPrefix(url) : url) + q2;
        }

        function makeArrayLinksFDed(match:ERegMatch, prefix:String, arrayStr:String, suffix:String):String {
            var lines = arrayStr.split(',').map((line:String) => {
                var m = arrayLineRE.match(line);
                return m != null
                    ? m[1] + addPrefix(m[2]) + m[3]
                    : line;
            });
            return prefix + lines.join(',') + suffix;
        }

        source = source.replace(srcRE, makeTaggedFDedQuotes);
        source = source.replace(linkRE, makeTaggedFDedQuotes);
        source = source.replace(imageSrcRE, makeTaggedFDedQuotes);
        source = source.replace(urlPropRE, makeLinkFDedQuotes);
        source = source.replace(loadFileRE, makeLinkFDedQuotes);
        source = source.replace(loaderLoadRE, makeLinkFDedQuotes);
        source = source.replace(workerRE, makeLinkFDedQuotes);
        source = source.replace(importScriptsRE, makeLinkFDedQuotes);
        source = source.replace(loaderArrayLoadRE, makeArrayLinksFDed);
        source = source.replace(threejsUrlRE, makeTaggedFDedQuotes);
        source = source.replace(moduleRE, makeFDedQuotesModule);

        return source;
    }

    static function extraHTMLParsing(html:String):String {
        return html;
    }

    static var version:String;

    static async function fixJSForCodeSite(js:String):Promise<String> {
        var moduleRE = new EReg("(import.*?)('|\")(.*?)('|\")", "g");

        if (version == null) {
            try {
                var res = await js.Browser.window.fetch('https://raw.githubusercontent.com/mrdoob/three.js/master/package.json');
                var json = await res.json();
                version = json.version;
            } catch (e:Dynamic) {
                js.console.error(e);
            }
        }

        function addVersion(href:String):String {
            if (href.startsWith(js.Browser.window.location.origin)) {
                if (href.includes('/build/three.module.js')) {
                    return 'https://cdn.jsdelivr.net/npm/three@' + version;
                } else if (href.includes('/examples/jsm/')) {
                    var url = new js.lib.URL.URL(href);
                    return 'https://cdn.jsdelivr.net/npm/three@' + version + url.pathname + url.search + url.hash;
                }
            }
            return href;
        }

        function addVersionToURL(match:ERegMatch, start:String, q1:String, url:String, q2:String):String {
            return start + q1 + addVersion(url) + q2;
        }

        if (version != null) {
            js = js.replace(moduleRE, addVersionToURL);
        }

        return js;
    }
}

var lessonEditorSettings = {
    extraHTMLParsing: EditorSettings.extraHTMLParsing,
    fixSourceLinks: EditorSettings.fixSourceLinks,
    fixJSForCodeSite: EditorSettings.fixJSForCodeSite,
    runOnResize: false,
    lessonSettings: {
        glDebug: false,
    },
    tags: ['three.js'],
    name: 'three.js',
    icon: '/files/icon.svg',
};