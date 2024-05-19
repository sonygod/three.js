package three.js.test;

import path.Path;
import rollup.nodeResolve.RollupNodeResolve;
import rollup.filesize.RollupFileSize;
import rollup.terser.RollupTerser;
import rollup.visualizer.RollupVisualizer;
import utils.build.RollupConfig.Glsl;
import chalk.Chalk;

class RollupTreeshakeConfig {
    static var statsFile:String = Path.resolve('test/treeshake/stats.html');

    static function logStatsFile():Dynamic {
        return {
            writeBundle: function() {
                trace();
                trace('Open the following url in a browser to analyze the tree-shaken bundle.');
                trace(Chalk.blue.bold.underline(statsFile));
                trace();
            }
        };
    }

    static function main():Array<Dynamic> {
        return [
            {
                input: 'test/treeshake/index.js',
                plugins: [RollupNodeResolve.create()],
                output: [
                    {
                        format: 'esm',
                        file: 'test/treeshake/index.bundle.js'
                    }
                ]
            },
            {
                input: 'test/treeshake/index.js',
                plugins: [RollupNodeResolve.create(), RollupTerser.create()],
                output: [
                    {
                        format: 'esm',
                        file: 'test/treeshake/index.bundle.min.js'
                    }
                ]
            },
            {
                input: 'test/treeshake/index-src.js',
                plugins: [Glsl.create(), RollupTerser.create(), RollupVisualizer.create({ filename: statsFile }), logStatsFile()],
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