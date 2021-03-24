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
		var processor = new XSLTProcessor();
		
		// I had to manually write AJAX queries to fight Firefox treating of XML
		var xhr = new XMLHttpRequest();
		xhr.open("GET", "corpus.xsl", true);
		xhr.overrideMimeType("text/html");
		xhr.onreadystatechange = function()
		{
			if (xhr.readyState == 4) {
				var xslDoc = (new DOMParser()).parseFromString(xhr.responseText, "text/xml");
				processor.importStylesheet(xslDoc);
				var xhr2 = new XMLHttpRequest();
				xhr2.open("GET", url2data, true);
				xhr2.overrideMimeType("text/html");
				xhr2.onreadystatechange = function()
				{
					if (xhr2.readyState == 4) {
						var xmlDoc  = (new DOMParser()).parseFromString(xhr2.responseText, "text/xml");
						var mydom = processor.transformToDocument(xmlDoc);
						var mydomhtml  = new XMLSerializer().serializeToString(mydom);  
						// console.log(mydomhtml);
						jQuery('#response').html(mydomhtml);
						hideProgress();
						
					}
				}
				xhr2.send();
						
				
			}
		}
		xhr.send();
		
		
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