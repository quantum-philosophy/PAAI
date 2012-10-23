#include <time.h>
#include <string>

#include <Storage/File.h>

#include "Problem.h"

#define PROCESSOR_INDEX 0
#define TIME_DIVISION 2

Problem::Problem(
	const System::Schedule &_schedule,
	const System::Power &_power,
	const Temperature::Analysis &_temperature,
	const Algebra::NaturalVector &_task_index,
	const Algebra::Vector &_task_deviation,
	int max_level, double epsilon) :

	AdaptiveSparseGrid(_task_index.size(), max_level, epsilon, 0),
	schedule(_schedule), power(_power), temperature(_temperature),
	task_index(_task_index), task_deviation(_task_deviation),

	_execution_time(_schedule.execution_time)
{
    NumberToStore = (power.step_count - 1) / TIME_DIVISION + 1;
    DofPerNode = 2;
    TotalDof = NumberToStore * DofPerNode;

    surplus = new double[TotalDof];
}

void Problem::solve()
{
    double t1, t2;

    t1 = MPI_Wtime();
    BuildAdaptiveSparseGrid();
    t2 = MPI_Wtime();

    int NoPoint = NumberOfPoints();

    if (rank == 0) {
        printf("Construction time: %.4f s\n", t2 - t1);
        printf("Number of points:  %d\n", NoPoint);
        printf("Depth of the grid: %d\n\n", InterpolationLevel());
    }

    ComputeMeanAndVar("result.plt");
    if (dim <= 3) PlotSparseGrid("grid.plt");
}

void Problem::EvaluateFunctionAtThisPoint(AdaptiveARRAY<double> *x)
{
	size_t i;
	unsigned int tid;

	/* Update the execution time of the tasks */
    for (i = 0; i < dim; i++) {
		tid = task_index[i];
		_execution_time[tid] = schedule.execution_time[tid] +
			task_deviation[i] * x->pData[i];
	}

	/* Perform the computations */
	System::Schedule new_schedule(schedule, _execution_time);
	power.compute(new_schedule, _power_profile);
	temperature.perform(_power_profile, _temperature_profile);

	size_t processor_count = power.processor_count;

	const double *T = _temperature_profile;
	double *S = surplus;

	/* Copy the result */
    for (i = 0; i < NumberToStore; i++) {
		*S = T[PROCESSOR_INDEX];
		S++;

		*S = T[PROCESSOR_INDEX] * T[PROCESSOR_INDEX];
		S++;

		T += processor_count * TIME_DIVISION;
	}
}

void Problem::StoreMeanAndVar(double *T, char *filename)
{
	Algebra::Matrix result(NumberToStore, 2);

    for (size_t i = 0; i < NumberToStore; i++) {
		result[i][0] = *T;
		T++;

		result[i][1] = *T;
		T++;
	}

	Storage::File::store(result, filename);
}

int Problem::IsRefine(double *value,
	AdaptiveARRAY<int> *ix, AdaptiveARRAY<int> *iy)
{
	double maximum = 0.0;

	for (size_t i = 0; i < TotalDof; i++)
		if (fabs(value[i]) > maximum)
			maximum = fabs(value[i]);

	if (maximum >= epsilon) return 1;
	else return 0;
}
