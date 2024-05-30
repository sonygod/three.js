package three.js.examples.jm.utils;

import js.html.webgl(RenderingContext);
import js.html.webgl.ext.EXTDisjointTimerQueryWebGL2;

class GPUStatsPanel extends stats.Panel {
    private var context:RenderingContext;
    private var extension:EXTDisjointTimerQueryWebGL2;
    private var maxTime:Float;
    private var activeQueries:Int;
    private var startQueryCallback:Void->Void;
    private var endQueryCallback:Void->Void;

    public function new(context:RenderingContext, name:String = 'GPU MS') {
        super(name, '#f90', '#210');

        extension = context.getExtension('EXT_disjoint_timer_query_webgl2');
        if (extension == null) {
            console.warn('GPUStatsPanel: disjoint_time_query extension not available.');
        }

        this.context = context;
        this.extension = extension;
        maxTime = 30;
        activeQueries = 0;

        startQueryCallback = function() {
            if (extension == null) return;
            var query = context.createQuery();
            context.beginQuery(extension.TIME_ELAPSED_EXT, query);
            activeQueries++;
            checkQuery();
        }

        endQueryCallback = function() {
            if (extension == null) return;
            context.endQuery(extension.TIME_ELAPSED_EXT);
        }

        function checkQuery() {
            if (context.isContextLost()) return;
            var available = context.getQueryParameter(query, context.QUERY_RESULT_AVAILABLE);
            var disjoint = context.getParameter(extension.GPU_DISJOINT_EXT);
            var ns = context.getQueryParameter(query, context.QUERY_RESULT);
            var ms = ns * 1e-6;

            if (available) {
                if (!disjoint) {
                    update(ms, maxTime);
                }
                activeQueries--;
            } else {
                haxe.Timer.delay(checkQuery, 16); // 16ms = 60fps
            }
        }
    }

    public function update(ms:Float, maxValue:Float) {
        // override this method to update the display
    }
}