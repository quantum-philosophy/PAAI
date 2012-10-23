#include <iostream>
#include <sstream>
#include <iomanip>
#include <mpi.h>

#include <Storage/File.h>
#include <Helpers/Arguments.h>
#include <Helpers/Configuration.h>
#include <System/Platform.h>
#include <System/Application.h>
#include <System/Schedule.h>
#include <System/Power.h>
#include <Temperature/TransientAnalysis.h>

#include "Problem.h"

using namespace Alpha;
using namespace Alpha::Algebra;
using namespace Alpha::Helpers;
using namespace Alpha::Storage;

class MyArguments: public Arguments
{
	public:

	std::string system_config;
	std::string floorplan;
	std::string hotspot_config;
	double sampling_interval;
	bool pretend;

	MyArguments() : Arguments(),
		sampling_interval(1e-4), pretend(false) {}

	void usage() const
	{
		std::cout
			<< "Usage: vary <arguments>" << std::endl
			<< std::endl
			<< "Required arguments:" << std::endl
			<< "  -system,    -s <value>       -- the configuration file of the system." << std::endl
			<< "  -floorplan, -f <value>       -- the floorplan of the die," << std::endl
			<< "  -hotspot,   -h <value>       -- the configuration file of HotSpot," << std::endl
			<< std::endl
			<< "Optional arguments:" << std::endl
			<< "  -sample,    -i <value=1e-4>  -- the sampling interval of the power profile," << std::endl
			<< "  -pretend,   -0               -- display diagnostic information." << std::endl;
	}

	protected:

	void process(const std::string &name, const std::string &value)
	{
		if      (name == "system"    || name == "s") system_config = value;
		else if (name == "floorplan" || name == "f") floorplan = value;
		else if (name == "hotspot"   || name == "h") hotspot_config = value;
		else if (name == "sample"    || name == "i") std::istringstream(value) >> sampling_interval;
		else if (name == "pretend"   || name == "0") pretend = true;
	}

	void verify() const
	{
		if (system_config.empty())
			throw std::runtime_error("The system configuration file is not specified.");
		else if (!File::exist(system_config))
			throw std::runtime_error("The system configuration file does not exist.");

		if (floorplan.empty())
			throw std::runtime_error("The floorplan is not specified.");
		else if (!File::exist(floorplan))
			throw std::runtime_error("The floorplan does not exist.");

		if (hotspot_config.empty())
			throw std::runtime_error("The configuration file of HotSpot is not specified.");
		else if (!File::exist(hotspot_config))
			throw std::runtime_error("The configuration file of HotSpot does not exist.");
	}
};

int main(int argc, char **argv)
{
	MPI_Init(&argc, &argv);

	MyArguments arguments;

	try {
		arguments.parse(argc, (const char **)argv);

		Configuration config(arguments.system_config);

		NaturalVector types;
		BitMatrix links;
		Matrix dynamic_power, execution_time;

		size_t size = config.size();

		for (size_t i = 0; i < size; i++) {
			const Parameter &param = config[i];

			if (param.name == "types") {
				param.to_vector(types);
			}
			else if (param.name == "links") {
				param.to_matrix(links);
			}
			else if (param.name == "dynamic_power") {
				param.to_matrix(dynamic_power);
			}
			else if (param.name == "execution_time") {
				param.to_matrix(execution_time);
			}
		}

		System::Platform platform(dynamic_power, execution_time);
		System::Application application(types, links);

		if (arguments.pretend)
			std::cout << platform << std::endl
				<< application << std::endl;

		System::Schedule schedule(platform, application);

		if (arguments.pretend)
			std::cout << schedule;

		System::Power power(platform, application,
			schedule.duration, arguments.sampling_interval);

		Temperature::HotSpot hotspot(
			arguments.floorplan, arguments.hotspot_config);

		Temperature::TransientAnalysis temperature(hotspot);

		if (~arguments.pretend) {
			const int dimension_count = 4;
			const double deviation = 0.7;

			NaturalVector task_index(dimension_count);
			task_index[0] = 0;
			task_index[1] = 1;
			task_index[2] = 3;
			task_index[3] = 6;

			Vector task_deviation(dimension_count);
			for (size_t i = 0; i < dimension_count; i++)
				task_deviation[i] = deviation * schedule.execution_time[i];

			int max_level = 10;
			double tolerance = 1e-4;

			Problem problem(schedule, power, temperature,
				task_index, task_deviation, max_level, tolerance);

			problem.solve();
		}
	}
	catch (std::exception &e) {
		std::cerr << e.what() << std::endl << std::endl;
		arguments.usage();
		return EXIT_FAILURE;
	}

	MPI_Finalize();

    return 0;
}
