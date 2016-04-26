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

function update_length(elm) {
	var msg = encode_msg(elm.value);
	
	document.getElementById('length').innerHTML = msg.length;
	document.getElementById('left').innerHTML = 160 - msg.length;
	document.getElementById('left').style.color = (msg.length > 160) ? 'red' : 'green';
	document.getElementById('send_btn').disabled = msg.length > 160 || msg.length == 0;
}

function send(frm) {
	var delta_t = 1000*5*60; // vadility of hash in seconds
	var msg = encode_msg(frm.message.value);
	
	frm.antispam.value = hex_md5(msg + Math.ceil(new Date().getTime() / delta_t));
	
	if (msg == 'Deine Nachricht') {
		alert('Der Standart ist doch langweilig!');
		return false;
	}
	
	if (msg.length > 160) {
		alert('Deine Nachricht ist zu lang!');
		return false;
	}
	else {
		return true;
	}
}

function encode_msg(msg) {
	return msg.trim().replace(/\r?\n/gm, "\\n");
}
