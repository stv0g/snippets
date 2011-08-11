function addUploader()
{
  addHtmlProperly(document.getElementById("files"), '<br /><input type="file" name="contacts[]" />');
  
  var inputs = document.getElementsByTagName('input');
  inputs[inputs.length-2].focus();
}

function addTextArea()
{
  addHtmlProperly(document.getElementById("basestrings"),'<br /><br /><textarea name="base64[]" rows="10" style="width:100%"></textarea><br />Name (optional): <input name="names[]" type="text" size="30" />');
  
  var inputs = document.getElementsByTagName('textarea');
  inputs[inputs.length-1].focus();
}

function addHtmlProperly(element, html)
{
  var htmlarea = document.createElement("div");
  htmlarea.setAttribute('name', 'htmlarea');
  
  element.appendChild(htmlarea);
  
  var areas = document.getElementsByName('htmlarea');
  areas[areas.length-1].innerHTML = html;
}

window.onload = function()
{
  document.getElementById('focus').focus();
  
  document.getElementsByTagName('iframe')[0].style.height = 0;
  document.forms.base.onsubmit = checkFormFinished;
}

var ie = (navigator.appName.indexOf("Explorer") != -1) ? true : false;
var mousemoved = 0;
var fadestep = ie ? 5 : 0.05;
var destOpacity = ie ? 100 : 1;

window.onmousemove = function()
{
  mousemoved++;
  
  if (mousemoved > 5)
  {
    window.onmousemove = function() { };
    fadeIn(document.getElementsByTagName("footer")[0], 0);
  }
}

function fadeIn(element, opacity)
{
  if (opacity < destOpacity)
  {
    opacity += fadestep;
    ie ? element.style.filter = "alpha(opacity=" + opacity + ")" : element.style.opacity = opacity;
    
    window.setTimeout(function() { fadeIn(element, opacity); }, 50);
  }
}

function checkFormFinished()
{
  imgs = parent.ifr.document.getElementsByTagName('img');
  
  if (imgs.length == 0)
  {
    window.setTimeout("checkFormFinished()", 100);
  }
  else
  {
    document.getElementsByTagName('iframe')[0].style.height = imgs[0].clientHeight + 'px';
  }
}