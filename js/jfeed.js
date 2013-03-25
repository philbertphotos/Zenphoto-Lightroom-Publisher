/*
 * jfeed v2.0
 * RSS/ATOM Feed Parser 
 *
 * Copyright 2011, Gianrocco Giaquinta
 * http://www.jscripts.info/
 *
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 */


function get_feed_json(url) {

	if (window.XMLHttpRequest)
  		objXml = new XMLHttpRequest();
	else
  		objXml = new ActiveXObject("Microsoft.XMLHTTP");

    objXml.open("GET","load.php?url="+url,false);
    objXml.send(null);
  	
	var src=objXml.responseText;
	src = src.replace(/\n/g, "");
	return gfj_parse_feed(src);
}

function gfj_parse_feed(src) {
	
	var fa = src.match(/(<[^!](.*?)>)|(!(.*?)\]\])|([^\s<][^<>]+)/ig);  
	var str="", last = [], sta="", initem=false, cseq=false, lclosest=false; 
	
	for (var i=0; i<fa.length; i++) {	
		
		$("#debug").append(fa[i].replace(/</g, "&lt;").replace(/>/g, "&gt;")+"<br>");
		
		var li = "" + /[^<> ]+/.exec(fa[i]);
		
		if ( fa[i].substr(0,1) == "<" ) {
			
			if ( li.substr(0,1) == "/" ) {
				var tl = last.pop();
				if (cseq) str += '""'; cseq=false; 
				if (tl == sta) 	str += " }";
				sta = last[last.length-1];
				if (initem) {
					if ( li == "/item" && /[^<> ]+/.exec(fa[i+1]) != "item" ) {str += "] "; initem=false;}
					if ( li == "/entry" && /[^<> ]+/.exec(fa[i+1]) != "entry" ) {str += "] "; initem=false;}
				}
				
			} else
			{	
				if (li.substr(0,1) != "?") {
					
				lta = last[last.length-1]; cseq=true;
				
				if (lta != sta) { str += "{ "; } else { str += ", "; }
								
				if ( !/\/[\s]?>$/.test(fa[i]) )
				{					
				  if (li == "item" || li == "entry") {  
					if (!initem) {
						str += "\""+li+"\" : ["; initem=true; 
					}
				  } else str += "\""+li+"\" : ";
				
				  last.push(li);  
				
				} else {
					sta = last[last.length-1];				
					var tag = fa[i].match(/[\s]+(.*?)\s*=\s*(("[^"]*")|('[^']*'))/ig);
					
					str += "\""+li+"\" : ";
					lclosest=true;
					var intag = "";
					for (var xi in tag) {
						x = tag[xi].split("=");
						x[0] = /[^\s]+/i.exec(x[0]); x[1]=x[1].replace(/^\s\s*/, '').replace(/\s\s*$/, '').replace(/^[\"\']/,"").replace(/[\"\']$/,"");
						intag += "\""+x[0]+"\" : \""+x[1]+"\", ";
					}
					intag = intag.replace(/,\s$/,"");
					if (intag) str += "{ "+intag+ "} "; else str += '""';
					cseq = false;
				}
				}
			}
		}
		else
		{
			cseq = false;
			if (li.substr(0,3) != "!--" ) {
				var cont = fa[i]; cont = cont.replace( /(\!\[CDATA\[)/i,"").replace( /(\]\])/i,"").replace(/&lt;/g,"<").replace(/&gt;/g,">");
				str += "\""+cont.replace(/\"/g, "\\\"")+"\"";
			}
		}
		 
	} str += "} ";
	
	return str;		
	
}