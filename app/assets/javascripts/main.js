/**
 * Created by alwaysbollu on 4/14/16.
 */

$('#application-link').click(function(){
    $('#people-loading').show();
});

$('form#scenario-form').submit(function(){
    $('#looking-around').show();
});

rank_showing = false;

$('#ranking-header').find('a').click(function() {
    $('#ranking-table').slideToggle(1000);
    rank_showing = !rank_showing;
});

$('button#toggle-detail-ranking').click(function() {
    if(rank_showing) {
        $('#normal-table').toggle(0);
        $('#detailed-table').toggle(0);
    }
});

$('#history-header').find('a').click(function() {
    $('#historical-graph').slideToggle(1000);
})