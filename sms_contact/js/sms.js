String.prototype.ltrim = function (clist) {
	if (clist) return this.replace(new RegExp ('^[' + clist + ']+'), '');
	return this.replace(/^\s+/, '');
}

String.prototype.rtrim = function (clist) {
	if (clist) return this.replace(new RegExp ('[' + clist + ']+$'), '');
	return this.replace(/\s+$/, '');
}

String.prototype.trim = function (clist) {
	if (clist) return this.ltrim(clist).rtrim(clist);
	return this.ltrim().rtrim();
};

function update_length(msg) {
	document.getElementById('length').innerHTML = msg.value.trim().length;
	document.getElementById('left').innerHTML = 160 - msg.value.trim().length;
	document.getElementById('left').style.color = (msg.value.trim().length > 160) ? 'red' : 'green';
}

function send(frm) {
	frm.message.value = frm.message.value.trim()
	frm.antispam.value = hex_md5(frm.message.value);
	
	if (frm.message.value.length > 160) {
		alert('Message is too long!');
		return false;
	}
	else {
		return true;
	}
}
