#ifndef JOSPEHUS_H_
#define JOSPEHUS_H_

#include <deque>

class Josephus {
public:
	Josephus(int n, int k);
	
	int n;
	int k;
		
	std::deque<int> people;
		
	int surviver();
};

#endif /*JOSPEHUS_H_*/
