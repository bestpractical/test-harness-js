plan(16);
use_ok('json.js');
use_ok('jquery-1.2.3.js');
use_ok('jquery_patch.js');
use_ok('jquery_noconflict.js');
use_ok('jquery.superflydom.js');
use_ok('jquery.jeditable.js');
use_ok('jquery.dimensions.js');
use_ok('ui.core.js');
use_ok('ui.sortable.js');
use_ok('ui.selectable.js');
use_ok('ui.draggable.js');
use_ok('ui.droppable.js');
use_ok('pieui.js');

ok(1,"ok");
ok(1,"fail");
var t = lorzy_make_empty_drop_target();
ok(t.hasClass('lorzy-target'), "It has a target's class");
