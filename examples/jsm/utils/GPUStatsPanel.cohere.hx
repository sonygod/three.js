import js.Browser.AnimationFrame;
import js.WebGL.WebGLRenderingContext;

class GPUStatsPanel {
    var context: WebGLRenderingContext;
    var extension: Extension;
    var maxTime: Float;
    var activeQueries: Int;

    public function new(context: WebGLRenderingContext, name: String) {
        this.context = context;
        this.extension = context.getExtension('EXT_disjoint_timer_query_webgl2');
        this.maxTime = 30.0;
        this.activeQueries = 0;

        if (extension == null) {
            trace('GPUStatsPanel: disjoint_time_query extension not available.');
        }

        this.startQuery = function() {
            if (extension == null) {
                return;
            }

            var gl = this.context;
            var query = gl.createQuery();
            gl.beginQuery(extension.TIME_ELAPSED_EXT, query);

            this.activeQueries++;

            var checkQuery = function() {
                var available = gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE);
                var disjoint = gl.getParameter(extension.GPU_DISJOINT_EXT);
                var ns = gl.getQueryParameter(query, gl.QUERY_RESULT);
                var ms = ns * 1e-6;

                if (available) {
                    if (!disjoint) {
                        this.update(ms, this.maxTime);
                    }

                    this.activeQueries--;
                } else if (!gl.isContextLost()) {
                    AnimationFrame.request(checkQuery);
                }
            };

            AnimationFrame.request(checkQuery);
        };

        this.endQuery = function() {
            if (extension == null) {
                return;
            }

            var gl = this.context;
            gl.endQuery(extension.TIME_ELAPSED_EXT);
        };
    }
}