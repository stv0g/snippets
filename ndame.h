#ifndef NDAME_H_
#define NDAME_H_

#include <vector>

class NDame {
public:
	NDame(int n);
	
	int n;
	int row;
	int col;
	
	std::vector<std::vector<int> > solutions; 
	std::vector<std::vector<int> > locked;
	std::vector<int> set;
	
	void Run();
	void Show(const std::vector<int> *p);
	void ShowSolutions();
	void Set(int row, int col);
	void UnSet(int row, int col);
	void Backtrack();
	bool Check(int row, int col);
	
private:

};

#endif /*NDAME_H_*/
