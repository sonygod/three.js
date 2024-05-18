package three.js.examples.jm.utils;

import js.html.webgl.GL;
import js.html.webgl.extensions.EXT_disjoint_timer_query_webgl2;
import three.js.libs.Stats.Panel;

class GPUStatsPanel extends Panel {
    private var context:GL;
    private var extension:EXT_disjoint_timer_query_webgl2;
    private var maxTime:Float = 30;
    private var activeQueries:Int = 0;

    public function new(context:GL, ?name:String = 'GPU MS') {
        super(name, '#f90', '#210');
        this.context = context;
        this.extension = context.getExtension('EXT_disjoint_timer_query_webgl2');

        if (this.extension == null) {
            js.Browser.console.warn('GPUStatsPanel: disjoint_time_query extension not available.');
        }
    }

    private function startQuery():Void {
        if (this.extension == null) return;

        var query:webgl.Query = this.context.createQuery();
        this.context.beginQuery(this.extension.TIME_ELAPSED_EXT, query);
        this.activeQueries++;

        var checkQuery:Void->Void = function():Void {
            var available:Bool = this.context.getQueryParameter(query, this.context.QUERY_RESULT_AVAILABLE);
            var disjoint:Bool = this.context.getParameter(this.extension.GPU_DISJOINT_EXT);
            var ns:Int = this.context.getQueryParameter(query, this.context.QUERY_RESULT);
            var ms:Float = ns * 1e-6;

            if (available) {
                if (!disjoint) {
                    this.update(ms, this.maxTime);
                }
                this.activeQueries--;
            } else if (!this.context.isContextLost()) {
                js.Browser.window.requestAnimationFrame(checkQuery);
            }
        };
        js.Browser.window.requestAnimationFrame(checkQuery);
    }

    private function endQuery():Void {
        if (this.extension == null) return;
        this.context.endQuery(this.extension.TIME_ELAPSED_EXT);
    }
}