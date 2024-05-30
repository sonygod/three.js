import js.Browser.window;
import js.Lib.Stats;

class GPUStatsPanel extends Stats.Panel {

    var context:Dynamic;
    var extension:Dynamic;
    var maxTime:Float;
    var activeQueries:Int;

    public function new(context:Dynamic, name:String = 'GPU MS') {
        super(name, '#f90', '#210');

        var extension = context.getExtension('EXT_disjoint_timer_query_webgl2');

        if (extension === null) {
            trace('GPUStatsPanel: disjoint_time_query extension not available.');
        }

        this.context = context;
        this.extension = extension;
        this.maxTime = 30;
        this.activeQueries = 0;

        this.startQuery = function () {
            var gl = this.context;
            var ext = this.extension;

            if (ext === null) {
                return;
            }

            var query = gl.createQuery();
            gl.beginQuery(ext.TIME_ELAPSED_EXT, query);

            this.activeQueries++;

            var checkQuery = function () {
                var available = gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE);
                var disjoint = gl.getParameter(ext.GPU_DISJOINT_EXT);
                var ns = gl.getQueryParameter(query, gl.QUERY_RESULT);

                var ms = ns * 1e-6;

                if (available) {
                    if (!disjoint) {
                        this.update(ms, this.maxTime);
                    }

                    this.activeQueries--;
                } else if (gl.isContextLost() === false) {
                    window.requestAnimationFrame(checkQuery);
                }
            };

            window.requestAnimationFrame(checkQuery);
        };

        this.endQuery = function () {
            var ext = this.extension;
            var gl = this.context;

            if (ext === null) {
                return;
            }

            gl.endQuery(ext.TIME_ELAPSED_EXT);
        };
    }
}