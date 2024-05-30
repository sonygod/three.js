package three.js.test;

import sys.FileSystem;
import haxe.io.Path;
import rollup.PluginBuilder;
import rollup.Resolver;
import rollup.FileSize;
import rollup.Terser;
import rollup.Visualizer;
import three.js.utils.BuildConfig;

using chalk.ColoredString;

class RollupTreeshakeConfig {
  static var statsFile = Path.join(['test', 'treeshake', 'stats.html']);

  static function logStatsFile():PluginBuilder {
    return {
      writeBundle: function() {
        Sys.println('');
        Sys.println('Open the following url in a browser to analyze the tree-shaken bundle.');
        Sys.println(chalk.blue.bold.underline(statsFile));
        Sys.println('');
      }
    };
  }

  static function main() {
    var config:Array<PluginBuilder> = [
      {
        input: 'test/treeshake/index.js',
        plugins: [new Resolver()],
        output: [
          {
            format: 'esm',
            file: 'test/treeshake/index.bundle.js'
          }
        ]
      },
      {
        input: 'test/treeshake/index.js',
        plugins: [new Resolver(), new Terser(), new FileSize({ showMinifiedSize: false })],
        output: [
          {
            format: 'esm',
            file: 'test/treeshake/index.bundle.min.js'
          }
        ]
      },
      {
        input: 'test/treeshake/index-src.js',
        plugins: [new GLSL(), new Terser(), new Visualizer({ filename: statsFile }), logStatsFile()],
        output: [
          {
            format: 'esm',
            file: 'test/treeshake/index-src.bundle.min.js'
          }
        ]
      }
    ];
  }
}