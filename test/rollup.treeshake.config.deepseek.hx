import js.Lib;
import js.Node.Path;
import js.Node.Chalk;
import rollup.Plugin;
import rollup.Plugin.NodeResolve;
import rollup.Plugin.Filesize;
import rollup.Plugin.Terser;
import rollup.Plugin.Visualizer;
import rollup.Plugin.Glsl;

class Main {
    static function main() {
        var statsFile = Path.resolve('test/treeshake/stats.html');

        var logStatsFile = function(): Plugin {
            return {
                writeBundle: function() {
                    Sys.println();
                    Sys.println('Open the following url in a browser to analyze the tree-shaken bundle.');
                    Sys.println(Chalk.blue.bold.underline(statsFile));
                    Sys.println();
                }
            };
        };

        var config = [
            {
                input: 'test/treeshake/index.js',
                plugins: [
                    NodeResolve.create(),
                ],
                output: [
                    {
                        format: 'esm',
                        file: 'test/treeshake/index.bundle.js'
                    }
                ]
            },
            {
                input: 'test/treeshake/index.js',
                plugins: [
                    NodeResolve.create(),
                    Terser.create(),
                    Filesize.create({
                        showMinifiedSize: false,
                    }),
                ],
                output: [
                    {
                        format: 'esm',
                        file: 'test/treeshake/index.bundle.min.js'
                    }
                ]
            },
            {
                input: 'test/treeshake/index-src.js',
                plugins: [
                    Glsl.create(),
                    Terser.create(),
                    Visualizer.create({
                        filename: statsFile,
                    }),
                    logStatsFile(),
                ],
                output: [
                    {
                        format: 'esm',
                        file: 'test/treeshake/index-src.bundle.min.js'
                    }
                ]
            },
        ];

        // Do something with config...
    }
}