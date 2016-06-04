#!/bin/bash
echo "Hello, welcome to ElasticSim."
echo  "Enter your options to start the sumulation:"
echo  "1. Start prediction service to generate forecasting"
echo  "2. Analyze historical workload to decide on reserved instances"
echo  "3. Start running AppElastic scaling algorithm on workload with reserved instances" 
echo  "4. Run AppElastic scaling algorithm as demo" 
read option

case $option in
	1)
		R CMD BATCH r_scripts/forecastworkload.r
		R CMD BATCH r_scripts/forecastworkload_graph.r
		open r_scripts/ActualForecast.pdf
		;;

	2)
		javac AppElastic.java
		java AppElastic 2
		R CMD BATCH r_scripts/cost_graphs.r
		open r_scripts/cost_graphs.pdf
		;;
	3)
		javac AppElastic.java
		java AppElastic 3
		R CMD BATCH r_scripts/simulation_graphs_with_ri.r
		open r_scripts/simulation_ri_graphs.pdf
		;;
	4) 
		javac AppElastic.java
		java AppElastic 1
		R CMD BATCH r_scripts/simulation_graphs.r
		open r_scripts/simulation_graphs.pdf
		;;
	*)
		exit 1
esac


