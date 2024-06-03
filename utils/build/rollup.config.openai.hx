package three.js.utils.build;

import haxe.Json;
import MagicString;

class RollupConfig {
  static function glsl():{ transform: (code: String, id: String) -> { code: String, map: Dynamic } } {
    return {
      transform: function(code: String, id: String):{ code: String, map: Dynamic } {
        if (!~/\.glsl\.js$/.match(id)) return null;
        code = new MagicString(code);
        code.replace ~/\/\* glsl \*\/\`(.*?)\`/sg, function(match: EReg, p1: String):String {
          return Json.stringify(
            p1
              .trim()
              .replace(~/\r/g, '')
              .replace(~/[ \t]*\/\/.*\n/g, '')
              .replace(~/[ \t]*\/\*[\s\S]*?\*\//g, '')
              .replace(~/\n{2,}/g, '\n')
          );
        };
        return { code: code.toString(), map: code.generateMap() };
      }
    };
  }

  static function header():{ renderChunk: (code: String) -> { code: String, map: Dynamic } } {
    return {
      renderChunk: function(code: String):{ code: String, map: Dynamic } {
        code = new MagicString(code);
        code.prepend('/**\n * @license\n * Copyright 2010-2024 Three.js Authors\n * SPDX-License-Identifier: MIT\n */\n');
        return { code: code.toString(), map: code.generateMap() };
      }
    };
  }

  static var builds:Array<Dynamic> = [
    {
      input: 'src/Three.js',
      plugins: [glsl(), header()],
      output: [
        {
          format: 'esm',
          file: 'build/three.module.js'
        }
      ]
    },
    {
      input: 'src/Three.js',
      plugins: [glsl(), header(), terser()],
      output: [
        {
          format: 'esm',
          file: 'build/three.module.min.js'
        }
      ]
    },
    {
      input: 'src/Three.js',
      plugins: [glsl(), header()],
      output: [
        {
          format: 'cjs',
          name: 'THREE',
          file: 'build/three.cjs',
          indent: '\t'
        }
      ]
    }
  ];

  static function main(args: Dynamic):Dynamic {
    return args.configOnlyModule ? builds[0] : builds;
  }
}