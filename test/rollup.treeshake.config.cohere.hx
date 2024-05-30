import path.Path;
import resolve.NodeResolve;
import filesize.Filesize;
import terser.Terser;
import visualizer.Visualizer;

class LogStatsFile {
    static function writeBundle() {
        trace('');
        trace('Open the following url in a browser to analyze the tree-shaken bundle.');
        trace(chalk.blue('test/treeshake/stats.html'));
        trace('');
    }
}

class Config {
    static var configs = [
        {
            input: 'test/treeshake/index.js',
            plugins: [
                NodeResolve()
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
                NodeResolve(),
                Terser(),
                Filesize({ showMinifiedSize: false })
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
                GLSLLiteral(),
                Terser(),
                Visualizer({ filename: 'test/treeshake/stats.html' }),
                LogStatsFile
            ],
            output: [
                {
                    format: 'esm',
                    file: 'test/treeshake/index-src.bundle.min.js'
                }
            ]
        }
    ];
}

// 导入所需的类
import path;
import resolve;
import filesize;
import terser;
import visualizer;
import chalk;

// 定义常量
const statsFile = 'test/treeshake/stats.html';

// 定义 LogStatsFile 类
class LogStatsFile {
    static function writeBundle() {
        trace('');
        trace('Open the following url in a browser to analyze the tree-shaken bundle.');
        trace(chalk.blue(statsFile));
        trace('');
    }
}

// 定义配置类
class Config {
    static var configs = [
        {
            input: 'test/treeshake/index.js',
            plugins: [
                resolve.NodeResolve()
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
                resolve.NodeResolve(),
                terser.Terser(),
                filesize.Filesize({ showMinifiedSize: false })
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
                glsl.GLSLLiteral(),
                terser.Terser(),
                visualizer.Visualizer({ filename: statsFile }),
                LogStatsFile
            ],
            output: [
                {
                    format: 'esm',
                    file: 'test/treeshake/index-src.bundle.min.js'
                }
            ]
        }
    ];
}