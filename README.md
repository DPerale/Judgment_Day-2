The system can do a comparison between EDF an RM algorithms in a real world processor using Ravenscar profile by Ada. We used the Gnat Community 2018 version, downloadable in the ada core site https://www.adacore.com/download/more . For linux the software name is "gnat-community-2018-20180524-arm-elf-linux64-bin". For the board we choice the STM32F429I-DISC1, one of the board that is supported by gnat. To connect the board with Linux is needed "stlink" downloadable here: https://github.com/texane/stlink . The full tutorial for the connections, other boards supported and what to use in Windows environment consult https://docs.adacore.com/gnat_ugx-docs/html/gnat_ugx/gnat_ugx/arm-elf_topics_and_tutorial.html .

The Judgment day 2 is divided in 8 parts:

edf-ravenscar-arm:
	the Ada code for EDF. In the <gnat installation folder>/arm-eabi/lib/gnat/ravenscar-full-stm32f429disco we have all the base code used for ours board. For the EDF version we modified some library to let work the board with a EDF algoritm for the  scheduling and for the strumentation to keep some data. If you don't use the board in the <gnat installation folder>/arm-eabi/lib/gnat/ folder there are other implementations. Here you could need some work if you want change the board. First you need to list all the ads and adb Ada file that there are in edf-ravenscar-arm folder. Now you have to compare all  the adb and ads Ada files listed before that are present in <gnat installation folder>/arm-eabi/lib/gnat/ravenscar-full-stm32f429disco folder with your board folder. If they are equal you don't need modifications (normal case), if not you need to modify the file keeping my modification for the EDF part and the strumentation part.
	In cyclic_task.adb and log_reporter_task.adb the Synchronization variable depend on your board, you have to keep attention if the tick of the clock is every some times (in our case the tick is every 1ms, so we had to phasing all the events depending on the tick, like the alarm clocks). In our case the number 180000 is the clock frequency in 1/ms (So 180MHz).
	In cyclic_tasks.ads and log_reporter_task.ads the pragma Storage_Size is used in order to set the memory usage of every tasks. This value is very important, and you need to set it depending from the task memory need and how much tasks you need on the entire systems.
	In system_time.ads we have the Task_Activation_delay a value that will set the 0 logic of our system, at this time all the tasks need to be ready to start.

fps-ravenscar-arm:
	the Ada code for FPS-RM. For this part we needed only the strumentation to keep the data, but as the EDF part you need to do the same work if you want use another board.

 
mast:
	we need this tool for the generation of the tasksets.

python-taskset-execution:
	
	It's the script fot the experiments. Here we create the Ada code for the taskset and we execute the code in the board, retrieving the final data. The script is subdivided in 3 parts, the version of python is 3.6.9
	
		main-experiments
			The main to execute, here you have to modify the code for your own tests. We left a couple of explanatory experiments.
		compile_flash_run
			It is a script that care about compiling the Ada code, flash it into the board, and execute it in debug mode, saving the data we need. Here you need to change the path for the compile command, and if you change the board you need to pay attention to the debugger, the output may change and the consequence is that you need to change the code.
		file_management
			Here we have some support functions that import the taskset data from a file, create the Ada file for the taskset (pay attention to Ada comments, you may need a modification in the code basing on your board) and save a file with the final data.

python-taskset-generator:
	It's the script for generating taskset files for the python-taskset-execution. It is subdivided in 5 parts, the version of python is 3.6.9
		main-generated
			The main to execute, here you have to modify the code for your own tests. We left a couple of explanatory experiments.
		taskset_generator
			We used some algorithms to create our tasksets. Here you can find them and use them if you need, or create your owns.
		support_functions
			Some algorithms to support the creation of the tasksets, use it if you need.
		MAST_analysis
			We use the tool MAST for some offline tests of schedulability		
		file_management
			Here we create the files for MAST analisys and the file for saving the tasksets

R-script
	We used R to create some graphs, we left a couple to example if you need.

taskset-experiments
	Here we save all the final data of the experiments, we left a couple of experiments as examples.

taskset-generated
	Here we save all the tasksets files, we left a couple of experiments as examples.
			
	





