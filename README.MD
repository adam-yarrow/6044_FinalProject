## Read Me
This repository is for our ASEN6044 Final Project on debris tracking using reflected GPS 
signals.

# Dependencies
MATLAB Parallel Computing Toolbox

# How to Execute Code
Before running anything within the repository, run Startup.m

The repository runs the following different tasks:
1. To run a full orbit tracking example:
	- Run "TrackingExample.m"
	- This first runs 50 seconds of NLS to warm start our particle filter.
	- The particle filter will then run for one whole orbit (takes approximately 3 hrs)
2. To test the our particle filter:
	- Run "PF_Test.m"
	- When running this script the params can be edited to trial different test cases
	  (typically just for changing the run time).
	- If KS testing is desired this can be enabled at the bottom of this script.
3. To perform NEES testing of the particle filter:
	- Run "PF_NEES_Testing.m"
	- Run time can be adjusted in the params struct, recommend less than 50 seconds due to
	  computational cost.
4. To test the NLS code:
	- Run "NLS_Test.m"
5. To run a NEES test of the NLS algorithm:
	- Run "NLS_NEES.m"
		
# Folder Structure
- Filtering:
	Contains the filtering algorithms and supporting infrastructure used in this project.
- Jacobians:
	Contains Jacobians used for NLS
- Plotting:
	Pretty self explanatory
- SavedData:
	Contains some plots and .mat files that were saved and used within the report/were 
	representative of good runs.
- Simulation:
	Contains the orbital dynamics model.
- Testing:	
	Mainly deprecated and used for early testing.

# Major Files of Relevance
- ModelParams.m
	Contains the master source of truth for all parameters in the project.
- Simulation.m
	Core physics engine that calls out to relevant sub-funcitons and classes.
- measurementModel.m
	Contains the measurement model implementation
- Receiver.m
	Class that contains the Rx model
- GPS.m 
	Class that contains the GPS model
- Debris.m 
	Class that contains the debris model
- OrbitalDynamics.m 	
	Contains the nonlinear equations of motion that govern the dynamics of the GPS and debris
- Run_PF.m 
	Runs the particle filter algorithm over the dataset
- RPF.m
	Regularized particle filter implementation
- SIR_PF.m 
	Sequential importance resampling particle filter implementation (taken from H/W)
- pYgivenX.m 
	Likelihood function
- PF_KS_Test.m 
	Contains the KS test implementation
- NLS.m
	Contains the NLS algorithm (taken from H/W).
