jQuery(document).ready(function(){
	var spinnerVisible = false;
    function showProgress() {
        if (!spinnerVisible) {
            // $("div#spinner").fadeIn("fast");
            $("div#spinner").show();
            spinnerVisible = true;
        }
    };
    function hideProgress() {
        if (spinnerVisible) {
            var spinner = $("div#spinner");
            spinner.stop();
            spinner.fadeOut("fast");
            spinnerVisible = false;
        }
    };
	function doXML(url2data){
		showProgress();
		var xml = Sarissa.getDomDocument();
		xml.async = false;
		xml.load(url2data);
		var myxsl = Sarissa.getDomDocument();
		myxsl.async = false;
		myxsl.load('corpus.xsl?1');
		//Now create a new xslt processor
		var processor = new XSLTProcessor();
		processor.importStylesheet(myxsl);
		var mydom = processor.transformToDocument(xml);
		// rateResult.innerHTML = Sarissa.serialize(ratesHTML);
		var mydomhtml  = new XMLSerializer().serializeToString(mydom);  
		jQuery('#response').html(mydomhtml);
		hideProgress();
	};
	function doSearch(term){
		if (term){
			$('#re').removeAttr('checked');
			jQuery("#term").val(term);
		} else {
			term = jQuery("#term").val();
		}
		if (term === '') {
				alert('Search term is NOT set!')
		} else {
			var url = "corpus.pl"
				+ "?mode=text;text=1"
				+ ";term="	+ term
				+ ";right="	+ jQuery("#right").val()
				+ ";left="	+ jQuery("#left").val()
				+ (jQuery("#re").is(':checked')?'&re=re':'');
				doXML(url);
		}
	};
	jQuery('#corpus').load('texts.pl', function(){jQuery('#control').removeClass('hidden')});
	
	$(document).on('click', "span.token", function() {
		doSearch($(this).attr("data-form"));
	});
	
	jQuery("#get").click(function(){
		doSearch();
	});
	
	jQuery("#freq").click(function(){
		var url = "corpus.pl" + "?mode=freq" + ";text="	+ '1';
		doXML(url);
	});	
});