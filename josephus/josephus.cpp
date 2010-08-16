#include <iostream>
#include <cstdlib>

#include "josephus.h"

int main(int argc, char *argv[]) {
	std::cout << "Berechne das Jospehus Problem mit " << atoi(argv[1]) << " Personen und einer Schrittweite von " << atoi(argv[2]) << std::endl;
	
	Josephus josephus(atoi(argv[1]), atoi(argv[2]));
	std::cout << "Überlebender: " << josephus.surviver() << std::endl;
	
	return EXIT_SUCCESS;
}

Josephus::Josephus(int n, int k) {
	if (n >= 2)
		this->n = n;
	else
		exit(1);
	
	if (k >= 2)
		this->k = k;
	else
		exit(1);
	
	for (int i = 0; i < n; i++)
		people.push_back(i + 1);
	
}

int Josephus::surviver() {
	int i = 0;
	while (people.size() > 1) {
		int temp = people[0];
		people.pop_front();
		i++;
		
		if (i >= k) {
			i = 0;
		}
		else {
			people.push_back(temp);
		}
	}
	
	return people[0];
}
