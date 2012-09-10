#include <iostream>
#include <cstdlib>

#define DEBUG

#include "ndame.h"

NDame::NDame(int n) {
	this->n = n;
	this->row = 0;
	this->col = 0;

	for (int i = 0; i < n; i++) {
		set.push_back(-1); // noch keine Dame wurde in diese Zeile gesetzt
		for (int j = 0; j < n; j++) {
			std::vector<int> temp(n, 0);
			locked.push_back(temp);
		}
	}
}

void NDame::Run() {
#ifdef DEBUG
	int sol_count = 0;
#endif /* DEBUG */

	while (row < n) {
		while (col < n) {
			if (Check(row, col) && col > set[row]) {
				Set(row, col);

#ifdef DEBUG
				Show(&set);
#endif /* DEBUG */

				break;
			} else {
				col++;

#ifdef DEBUG
				std::cout << "col++" << std::endl;
#endif /* DEBUG */

			}
		}

		if (col == n) {
			if (set[row - 1] >= n-1 && row == 0) {
				break;
			}
			else {
				Backtrack();
			}
		}
		else {
			row++;
			col = 0;

			if (row == n) {
#ifdef DEBUG
				std::cout << "New Solution: Nr. " << sol_count++ << std::endl;
#endif /* DEBUG */

				solutions.push_back(set);
				Backtrack();
			}

#ifdef DEBUG
			std::cout << "row++; col = 0;" << std::endl;
#endif /* DEBUG */

		}
	}
}

void NDame::Backtrack() {
#ifdef DEBUG
	std::cout << "Backtrack: we will reject dame " << row - 1 << "|" << set[row - 1] << std::endl;
#endif /* DEBUG */

	col = set[row - 1] + 1;
	UnSet(row - 1, set[row - 1]);

#ifdef DEBUG
	Show(&set);
#endif /* DEBUG */

	row--;
}

bool NDame::Check(int row, int col) {
	bool check;
	check = (locked[row][col] > 0) ? false : true;

#ifdef DEBUG
	std::cout << "Check: " << row << "|" << col << " " << check << std::endl;
#endif /* DEBUG */

	return check;
}

void NDame::Set(int row, int col) {
	for (int i = 0; i < n; i++)
		locked[row][i]++; // Vertikal

	for (int j = 0; j < n; j++)
		locked[j][col]++; // Horizontal

	for (int k = 0; k < n; k++)
		if ((col - row + k) < n && (col - row + k) >= 0)
			locked[k][col - row + k]++; // Diagonal oben links -> unten rechts

	for (int l = 0; l < n; l++)
		if ((row + col - l) < n && (row + col - l) >= 0)
			locked[l][row + col - l]++; // Diagonal unten links -> oben rechts

	set[row] = col;

#ifdef DEBUG
	std::cout << "Neue Dame: " << row << "|" << col << std::endl;
#endif /* DEBUG */

}

void NDame::UnSet(int row, int col) {
	for (int i = 0; i < n; i++)
		locked[row][i]--; // Vertikal

	for (int j = 0; j < n; j++)
		locked[j][col]--; // Horizontal

	for (int k = 0; k < n; k++)
		if ((col - row + k) < n && (col - row + k) >= 0)
			locked[k][col - row + k]--; // Diagonal oben links -> unten rechts

	for (int l = 0; l < n; l++)
		if ((row + col - l) < n && (row + col - l) >= 0)
			locked[l][row + col - l]--; // Diagonal unten links -> oben rechts

	set[row] = -1;

#ifdef DEBUG
	std::cout << "Dame entfernt: " << row << "|" << col << std::endl;
#endif /* DEBUG */

}

void NDame::Show(const std::vector<int> *p) {
	std::cout << "  ||";
	for (int l = 0; l < n; l++)
		std::cout << l << "|";
	std::cout << std::endl;

	for (int i = 0; i < n; i++) {
		std::cout << ((i < 10) ? " " : "") << i << "||";
		for (int j = 0; j < n; j++)
			std::cout << ((p->at(i) == j) ? 'X' : ' ') << "|";

		std::cout << "  " << p->at(i) << std::endl;
	}
}

int main(int argc, char* argv[]) {
	if (argc >= 2) {

#ifdef DEBUG
		std::cout << "Berechne das n-Damenproblem für " << argv[1] << " Damen" << std::endl;
#endif /* DEBUG */

		NDame dame(atoi(argv[1]));
		dame.Run();

		dame.ShowSolutions();

#ifdef DEBUG
		std::cout << dame.solutions.size() << " Lösungen" << std::endl;
#endif /* DEBUG */

		if (argc == 3) {
			dame.Show(&dame.solutions.at(atoi(argv[2]) - 1));
		}
	} else {
		std::cout << "Bitte geben Sie einen Paramenter an!" << std::endl;
	}
}

void NDame::ShowSolutions() {
	for (std::vector<std::vector<int> >::iterator i = solutions.begin(); i
			!= solutions.end(); i++) {
		for (std::vector<int>::iterator p = i->begin(); p != i->end(); p++)
			std::cout << *p + 1 << ((*p != i->back()) ? "|" : "");
		if (*i != solutions.back())
			std::cout << std::endl;
	}
}
