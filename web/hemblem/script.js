var solution = new Array(new Array(false,	true,	false),
					new Array(false,	false,	true),
					new Array(true,		true,	true));
					
var checked = new Array(new Array(false,	false,	false),
					new Array(false,	false,	false),
					new Array(false,	false,	false));

window.onkeypress = keypress;

function keypress (event) {
	switch (event.which) {
		case 55:
			x = 0;
			y = 0;
			break;
		case 56:
			x = 1;
			y = 0;
			break;
		case 57:
			x = 2;
			y = 0;
			break;
			
		case 52:
			x = 0;
			y = 1;
			break;
		case 53:
			x = 1;
			y = 1;
			break;
		case 54:
			x = 2;
			y = 1;
			break;
			
		case 49:
			x = 0;
			y = 2;
			break;
		case 50:
			x = 1;
			y = 2;
			break;
		case 51:
			x = 2;
			y = 2;
			break;
		default:
			x = -1;
			y = -1;
			break;
	}
	
	if (x + y >= 0) {
		toggle(x, y)
	}
}

function toggle(x, y) {
	if (checked[y][x] == false)
		set(x ,y);
	else
		clear(x, y);
	
	check();
}

function set(x, y) {
	elm = document.getElementById('glider').rows[y].cells[x];
	elm.style.backgroundImage = 'url(bcrcl.gif)';
	checked[y][x] = true;
}

function clear(x, y) {
	elm = document.getElementById('glider').rows[y].cells[x];
	elm.style.backgroundImage = '';
	checked[y][x] = false;
}

function check() {
	for(iy = 0; iy < 3; iy++) {
		for(ix = 0; ix < 3; ix++) {
			if (checked[iy][ix] != solution[iy][ix])
				return;
		}
	}
	
	alert('Alright! Welcome on board!');
	window.location.href = 'https://www.steffenvogel.de';
}

function intro(step) {
	if (step < 7) {
		for (var x = 0; x < 3; x++) {
			for (var y = 0; y < 3; y++) {
				if (Math.random() > 0.7)
					set(x, y);
				else
					clear(x, y);
			}
		}
		window.setTimeout('intro(' + (step+1) + ')', 200);
	}
	else {
		for (var x = 0; x < 3; x++) {
			for (var y = 0; y < 3; y++) {
				clear(x, y);
			}
		}
	}
}

function blink(x, y, dur) {
	set(x, y);
	window.setTimeout('clear(' + x + ', ' + y + ')', dur);
}