#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

#include <cmath>
#include <ncurses.h>
#include <stdlib.h>
#include <sys/select.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/joystick.h>

#include <string>
#include <iostream>
#include <vector>
#include <algorithm>

#define JOY_DEV "/dev/input/js0"

namespace fs = boost::filesystem;

int main(int argc, char* argv[]) {
	fs::path full_path(fs::initial_path<fs::path>());
	int joy_fd;

	/*if (argc> 1)
	full_path = fs::system_complete(fs::path(argv[1], fs::native));
	else
	std::cout << "usage:   romsel [path]" << std::endl;

	if (!fs::exists(full_path)) {
		std::cerr << "\nNot found: " << full_path.native_file_string() << std::endl;
		return -1;
	}*/
	
	if ((joy_fd = open(JOY_DEV, O_RDONLY)) == -1) {
		std::cerr << "\nCouldn't open joystick" << std::endl;
		return -1;
	}
	
	if (argc > 1) {
		int start = 0, end, count = 0;
		std::vector<std::string> roms;
		
		initscr();
		start_color();
		noecho();
		cbreak();
		keypad(stdscr, TRUE);
		init_pair(1, COLOR_BLACK, COLOR_WHITE);
		curs_set(0);
		
		/*fs::directory_iterator end_iter;
		for (fs::directory_iterator dir_itr(full_path); dir_itr != end_iter; ++dir_itr) {
			if (dir_itr->path().extension() ==  ".smc") {
				roms.push_back(dir_itr->filename());
			}
		}*/
		
		for (int i = 1; i < argc; i++) {
			roms.push_back(std::string(argv[i]));
		}
		
		std::sort(roms.begin(), roms.end());
		
		end = roms.size() - 1;
		
		while (end != start) {
			int disp_start = start,
				disp_end = end,
				nls_before = 0,
				middle = start + ((end -start) / 2);

			fd_set rfds;
			
			FD_ZERO(&rfds);
			FD_SET(0, &rfds);
			FD_SET(joy_fd, &rfds);
			
			if (end - start + 1 > LINES - 2) { // Ausschnitt anzeigen
				disp_start = middle - LINES / 2;
				disp_end = middle + LINES / 2;
			}
			else { // Leerzeilen einfügen
				nls_before = (LINES - ((LINES % 2 == 1) ? 3 : 2)) / 2 - (end -start + 1) / 2;
			}
			
			clear();
			for (int i = 0; i < nls_before; i++) addstr("\n\r");
			for (int i = disp_start; i <= disp_end; i++) {
				printw("%d: %s\n\r", i + 1, roms.at(i).c_str());
				if (i == middle) for (int p = 0; p < COLS; p++) addch('=');
			}
			attron(COLOR_PAIR(1) | A_BOLD);
			mvprintw(LINES - 1, 0, "Einträge: %d | Mitte: %d | Start: %d | Ende: %d | %d/%d Entscheidungen | nls_before: %d | %d %d", roms.size(), middle, start, end, count, static_cast<int>(ceil(log(static_cast<double>(roms.size()))/log(2.0))), nls_before, disp_start, disp_end);
			attroff(COLOR_PAIR(1) | A_BOLD);
			refresh();
				
			select(joy_fd + 1, &rfds, NULL, NULL, NULL);
			if (FD_ISSET(0, &rfds)) {
				int c = getch();
				switch (c) {
					case 259: // KEY_UP
						end = middle;
						count++;
						break;
					case 258: // KEY_DOWN
						start = middle + 1;
						count++;
						break;
					case 'q':
						endwin();
						return 0;
					default:
						break;
				}
			}
			if (FD_ISSET(joy_fd, &rfds)) {
				struct js_event js;
				read(joy_fd, &js, sizeof(struct js_event));
				if (js.type == 2 && js.number == 1 && js.value < 0) { end = middle; count++; }
				if (js.type == 2 && js.number == 1 && js.value > 0) { start = middle + 1; count++; }
			}
		}
		
		endwin();
		
		std::cout << roms[start] << std::endl;
	}
	
	return 0;
}

