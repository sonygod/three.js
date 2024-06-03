import js.html.WebGLRenderingContext;
import Stats from 'js.html.Stats';

class GPUStatsPanel {

    public var context: WebGLRenderingContext;
    public var extension: dynamic;
    public var maxTime: Float = 30.0;
    public var activeQueries: Int = 0;

    public function new(context: WebGLRenderingContext, name: String = 'GPU MS') {

        super(name, '#f90', '#210');

        this.context = context;
        this.extension = context.getExtension('EXT_disjoint_timer_query_webgl2');

        if (this.extension == null) {

            trace('GPUStatsPanel: disjoint_time_query extension not available.');

        }

    }

    public function startQuery(): Void {

        if (this.extension == null) {

            return;

        }

        var query = this.context.createQuery();
        this.context.beginQuery(this.extension.TIME_ELAPSED_EXT, query);

        this.activeQueries++;

        var checkQuery = function() {

            var available = this.context.getQueryParameter(query, this.context.QUERY_RESULT_AVAILABLE);
            var disjoint = this.context.getParameter(this.extension.GPU_DISJOINT_EXT);
            var ns = this.context.getQueryParameter(query, this.context.QUERY_RESULT);

            var ms = ns * 1e-6;

            if (available) {

                if (!disjoint) {

                    this.update(ms, this.maxTime);

                }

                this.activeQueries--;

            } else if (!this.context.isContextLost()) {

                js.Browser.window.requestAnimationFrame(checkQuery);

            }

        }

        js.Browser.window.requestAnimationFrame(checkQuery);

    }

    public function endQuery(): Void {

        if (this.extension == null) {

            return;

        }

        this.context.endQuery(this.extension.TIME_ELAPSED_EXT);

    }

}