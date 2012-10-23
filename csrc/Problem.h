#ifndef __PROBLEM_H__
#define __PROBLEM_H__

#include <System/Platform.h>
#include <System/Application.h>
#include <System/Schedule.h>
#include <System/Power.h>
#include <Temperature/TransientAnalysis.h>

#include <SparseGrid.h>

using namespace Alpha;

class Problem: public AdaptiveSparseGrid
{
	public:

	const System::Schedule &schedule;
	const System::Power &power;
	const Temperature::Analysis &temperature;

	const Algebra::NaturalVector task_index;
	const Algebra::Vector task_deviation;

	private:

	Algebra::Matrix _power_profile;
	Algebra::Matrix _temperature_profile;
	Algebra::Vector _execution_time;

    public:

    Problem(const System::Schedule &_schedule,
		const System::Power &_power,
		const Temperature::Analysis &_temperature,
		const Algebra::NaturalVector &_task_index,
		const Algebra::Vector &_task_deviation,
		int max_level, double epsilon);

    virtual void solve();
    virtual void EvaluateFunctionAtThisPoint(AdaptiveARRAY<double> *x);
    virtual void StoreMeanAndVar(double *stats,char *filename);
	virtual int IsRefine(double *value,
		AdaptiveARRAY<int> *ix, AdaptiveARRAY<int> *iy);
};

#endif
