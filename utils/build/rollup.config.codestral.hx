import js.Browser.document;
import js.json.JSON;
import js.MagicString;

class Glsl {
    public static function transform(code: String, id: String): String {
        if (!id.match(/\.glsl.js$/)) return code;

        var ms = new MagicString(code);

        ms.replace(/\/\* glsl \*\/\`(.*?)\`/sg, function (match, p1) {
            var processed = p1
                .trim()
                .replace(/\r/g, '')
                .replace(/[ \t]*\/\/.*\n/g, '') // remove //
                .replace(/[ \t]*\/\*[\s\S]*?\*\//g, '') // remove /* */
                .replace(/\n{2,}/g, '\n'); // # \n+ to \n

            return JSON.stringify(processed);
        });

        return ms.toString();
    }
}

class Header {
    public static function renderChunk(code: String): String {
        var ms = new MagicString(code);

        ms.prepend(`/**
 * @license
 * Copyright 2010-2024 Three.js Authors
 * SPDX-License-Identifier: MIT
 */\n`);

        return ms.toString();
    }
}

class Builds {
    public static var builds: Array<Dynamic> = [
        {
            input: 'src/Three.js',
            plugins: [
                Glsl,
                Header
            ],
            output: [
                {
                    format: 'esm',
                    file: 'build/three.module.js'
                }
            ]
        },
        // Add other configurations as needed...
    ];

    public static function get(configOnlyModule: Bool): Dynamic {
        return configOnlyModule ? builds[0] : builds;
    }
}