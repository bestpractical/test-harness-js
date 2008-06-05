function ghetto_lightbox (content) {
	var background = jQuery('<div id="lightbox"></div>');
	jQuery('body').append(background).fadeIn(750);
	var baa = jQuery('<div id="lightbox-content">'+content+'</div>');
	var boxdox = jQuery('<div id="lightbox-docs">(Double-click to close)</div>');
	background.append(baa);
	background.append(boxdox);
	jQuery('body').bind('dblclick', function (x) {
	jQuery('#lightbox').fadeOut(750);
	jQuery('#lightbox').replaceWith('');
	
});

}


function lorzy_remove_ast_node(node) {
                   var target_after =  jQuery(node).next('.lorzy-target')[0];
                    if(target_after) {
                        target_after.remove();
                    }

                    
                   var target_before =  jQuery(node).prev('.lorzy-target')[0];
                    if(target_before) {
                        target_before.remove();
                    }

                    node.replaceWith(lorzy_make_empty_drop_target());
}


var lorzy_draggable_opts = { revert: true, activeClass: 'draggable-active', opacity: '0.6'};
var lorzy_droppable_opts = {
            accept: '.lorzy-expression, .lorzy-expression-proto',
            greedy: 'true',
            activeClass: 'droppable-active',
            hoverClass: 'droppable-hover',
            tolerance: 'pointer',
            drop: function(ev, ui) { 
                var orig = jQuery(ui.draggable); 
                var newitem = jQuery(ui.draggable).clone();
                newitem.removeClass('lorzy-expression-proto')
                  .attr({style: 'display: block'})
                  .draggable(lorzy_draggable_opts)
                  .droppable(lorzy_droppable_opts)
                  .insertAfter(this);

                if (!orig.parent().hasClass('library')) {
                    lorzy_remove_ast_node(orig);

                    jQuery(this).replaceWith('');
                }

                lorzy_wrap_in_drop_targets(newitem);

                // use livequery or something
                jQuery('.lorzy-expression', newitem).droppable(lorzy_droppable_opts);
                jQuery('.lorzy-target', newitem).droppable(lorzy_droppable_opts);
	        make_elements_editable(jQuery('.lorzy-expression.lorzy-const.string', newitem));
                return true;

}};

var trashable_args = {
            accept: '#wrapper .lorzy-expression',
            greedy: 'true',
            hover: 'pointer',
            activeClass: 'droppable-active',
            hoverClass: 'droppable-hover',
            tolerance: 'pointer',
            drop: function(ev, ui) { 
                      var orig = jQuery(ui.draggable); 
                      if (!orig.parent().hasClass('library')) {
                        lorzy_remove_ast_node(orig);
                   } 
                    }
};







function lorzy_make_empty_drop_target (){
      var x =  jQuery('<div class="lorzy-target"></div>');
      x.droppable(lorzy_droppable_opts);
      return(x);
}
function lorzy_wrap_in_drop_targets(node) {
   
    var myNode = jQuery(node);

    if(! myNode.prev().hasClass('lorzy-target')){
        jQuery(lorzy_make_empty_drop_target()).insertBefore(node);
        } 

    if(!myNode.next().hasClass('lorzy-target')){
         jQuery(lorzy_make_empty_drop_target()).insertAfter(node);
    }
}




function lorzy_show_expression_str(str, parent) {
    jQuery(parent).replaceWith(lorzy_make_expression_str(str));
}

function lorzy_make_expression_str(str) {
    var string =  jQuery('<div class="lorzy-expression lorzy-const string">'+str+'</div>');
    return string;

}

function lorzy_show_exression_progn(expr, parent) {
        jQuery.each(expr.nodes, function () { lorzy_show_expression(parent) });

}

function lorzy_show_expression(parent, add_event) {
    if( this.name == 'progn') {
        lorzy_show_expression_progn(this, parent);
        return;
    }

    var ret = parent.createAppend('div', { className: this.name });
    ret.addClass('lorzy-expression')
    ret.addClass('lorzy-code');
    lorzy_wrap_in_drop_targets(ret);
    var that = this;
    jQuery(ret).createAppend('div', { className: 'name'} , [this.name]);


    var codeargs = lorzy_show_expression_args(this.args);
    jQuery(ret).append(codeargs);

    };

    function lorzy_show_expression_args(args) {
        var codeargs = jQuery('<div class="lorzy-code-args">');
        

    jQuery.each(args, function(name, exp) {
        var entry = codeargs.createAppend('div', { className: 'lorzy-code-arg' });
        entry.createAppend('div', { className: 'name'}, [ name]);
        var value = entry.createAppend('div', { className: 'value'});
        
        if (typeof(exp) == 'string') {
            var valcontent= value.createAppend('div', { className: 'lorzy-expression'});
            lorzy_wrap_in_drop_targets(valcontent);
            lorzy_show_expression_str(exp, valcontent);
        } else if (exp) {
            lorzy_show_expression.apply(exp, [value]); //[entry]);
        } 


    });

    return codeargs;
}


function lorzy_show_symbols(struct) {
        jQuery.each(struct, function(item, arg_list) {

        var expression = jQuery('.library').createAppend('div', {className: 'lorzy-code lorzy-expression lorzy-expression-proto'});
        expression.createAppend('div',{className: 'name'},[item]);
        if(arg_list) {
        var args_hook = expression.createAppend('div',{className: 'lorzy-code-args'});


        jQuery.each(arg_list, function(attr)  { 
                    var arg = args_hook.createAppend('div', {className: 'lorzy-code-arg'});
                    arg.createAppend('div', {className: 'name'}, [attr]);
                    var value = arg.createAppend('div', {className: 'value'});
                   if (arg_list[attr].type == 'PIE::Expression') {
                        value.append( lorzy_make_empty_drop_target() );
                    } if (arg_list[attr].type == 'Str') {
                        value.append(lorzy_make_expression_str('(click me to edit)'));
                    } else {
                        value.append('What should I do with '+arg_list[attr].type);
                    }
                    //args_hook.createAppend('div', {className: 'type'}, [attr.type]);
                 
        
        });

        }
    });
    jQuery('.library .lorzy-expression').draggable(lorzy_draggable_opts);
}

function lorzy_show(ops) {
    jQuery(ops).each(
        function() {
            lorzy_show_expression.apply(this, [jQuery('#wrapper'), true]);
            
        });


    jQuery('.lorzy-expression .lorzy-expression').draggable(lorzy_draggable_opts);

    var tools = jQuery('<div class="lorzy-tools"></div>');
    jQuery('#wrapper').after(tools);




    tools.createAppend('div', { id: 'clicky'}, ['Serialize']);
    tools.createAppend('div', { id: 'testy'}, ['Run on server']);
    jQuery('#wrapper .lorzy-expression').droppable(lorzy_droppable_opts);
    jQuery('#wrapper .lorzy-target').droppable(lorzy_droppable_opts);


    var drop_targets = jQuery('<div class="lorzy-drop-targets"></div>');
    jQuery('#wrapper').after(drop_targets);
    drop_targets.createAppend('div', { id: 'trashy'} , ['Trash']);
    jQuery('#trashy').droppable(trashable_args);



    jQuery('#testy').click(function () {
        jQuery.ajax({
    'url': '/=/action/Pie.Plate.Action.RunL.json',
    'datatype': 'text/json',
    'type': 'post',
    'success': function(json) { 
            json = json.split(",").join(",\n");
            ghetto_lightbox('<pre>'+json+'</pre>');
}, 
    'data': 'struct='+lorzy_generate_struct('#wrapper').toJSON()
})


    });

    jQuery('#clicky').click(function () { 
        var x =  lorzy_generate_struct('#wrapper').toJSON().split(",").join(",\n");
        ghetto_lightbox('<pre>'+x+'</pre>');
   
    });

    make_elements_editable(jQuery('#wrapper .lorzy-expression.lorzy-const.string'));
    return true;
};

function make_elements_editable (elements) {
        elements.bind('dblclick', function (x) { make_editable.apply(x.target)});



    
    
    function make_editable() {
                var noneditable = this;
                var content = jQuery(noneditable).html();
                var editable =  jQuery('<input type="text" class="lorzy-const lorzy-expression editable" value="'+content+'"/>');
                 function blur_edit () {
                    jQuery(noneditable).text( this.value); 
                    jQuery(noneditable).bind('dblclick', function(x) { make_editable.apply(x.target)});
                    jQuery(this).replaceWith(noneditable);
                    }

                editable.bind('blur', blur_edit)
                        
                        .bind('keypress', 
                    
                                // xxx icky. code duplication
                                function (event) { if(event.keyCode == '13') { 
                    jQuery(noneditable).text( this.value); 
                    jQuery(noneditable).bind('dblclick', function(x) { make_editable.apply(x.target)});
                    jQuery(this).replaceWith(noneditable);
                            event.stopPropagation (true);
                        }

                        }
                        );
                        
                    
                
                jQuery(this).replaceWith( editable);
                
            };

}



function lorzy_generate_struct(parent) {
    var ops = jQuery(parent).children();
    var tree=   jQuery.grep( 
        jQuery.map(ops, function (op) { return lorzy_generate_op(jQuery(op)); }),

        function(element, index) {
            return (element && !jQuery(element).hasClass('lorzy-target'))
        }
    );
   
    return tree;
}


function lorzy_generate_op (op) {
            if(op.hasClass('lorzy-target')) {
            // it's nothing. skip it
                return '';

                }
            if (op.hasClass('lorzy-const')) {            
               return op.text();
            } 
           else if( op.hasClass('lorzy-expression')) {
                var codeargs =  op.children('.lorzy-code-args').children();
                return { 'name': op.children('.name').text(), 'args': lorzy_generate_args_struct(codeargs)  };
            } 
            
            else if (op.hasClass('lorzy-progn')) {    
                return { 'progn':  lorzy_generate_progn(op)}; 
            }else  { 
            console.log("failed to find a class on " +op.attr('class'));
            }
}

function lorzy_generate_progn(op) {
        return lorzy_generate_struct(op);//.children('lorzy-expression'));

}


function lorzy_generate_args_struct(args) {

    var myArray = {};
     jQuery.map(args, function (op)  {  
               var values =  lorzy_generate_struct(jQuery(op).children('.value'));
               if (values.length < 1 ) {
                    myArray[ jQuery(op).children('.name').text() ]= null;
                }
               else if (values.length == 1) {
                myArray[ jQuery(op).children('.name').text() ] =   values[0] ;
               } else {
                myArray[ jQuery(op).children('.name').text() ] =  { 'progn': values} ;
               }
    });


    return myArray;
}

