#!/bin/bash
echo "Hello, welcome to ElasticSim."
echo  "Enter your options to start the sumulation:"
echo  "1. Analyze historical workload to decide on reserver instances"
echo  "2. Start prediction service to generate forecasting"
echo  "3. Start running AppElastic scaling algorithm on workload" 
read option
echo $option



#R --vanilla predictionforworkload.r
