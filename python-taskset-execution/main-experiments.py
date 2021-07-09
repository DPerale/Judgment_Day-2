import csv
from compile_flash_run import compile_and_flash_into_board, debug_and_read_data
from file_management import make_adb_file, save_data, import_taskset


# experiments of Buttazzo method 1 and 2, with possible repetition of periods
def buttazzo_experiments_preemptions ():
    for i in range(1,19001):
        taskset = []
        taskset, utilization, EDF_busy_period, FPS_busy_period, EDF_first_DM, EDF_schedulable, \
            FPS_schedulable, hyperperiod = import_taskset(taskset, i, "buttazzo_preemptions.csv")
        make_adb_file(taskset, hyperperiod)
        EDF_data = []
        FPS_data = []
        for j in range(2):
            compile_and_flash_into_board(j)
            if (j==0):
                EDF_data = debug_and_read_data(taskset, j)
            else:
                FPS_data = debug_and_read_data(taskset, j)
        if i<9001:
            save_data(taskset, EDF_data, FPS_data, "Buttazzo-First-Preemptions/Buttazzo-First-Preemptions", i, hyperperiod)
        else:
            save_data(taskset, EDF_data, FPS_data, "Buttazzo-Second-Preemptions/Buttazzo-Second-Preemptions", i-9000, hyperperiod)


# experiments with utilization greater than 1
def U_100_hyper_113400000_10_100_full():

    # first we make the experiment at hyperperiod
    for i in range(1, 501):
        taskset = []
        taskset, utilization, EDF_busy_period, FPS_busy_period, EDF_first_DM, EDF_schedulable, FPS_schedulable, \
            hyperperiod = import_taskset(taskset, i, "U_100_hyper_113400000_10_100.csv")
        make_adb_file(taskset, hyperperiod)
        EDF_data = []
        FPS_data = []
        for j in range(2):
            compile_and_flash_into_board(j)
            if (j == 0):
                EDF_data = debug_and_read_data(taskset, j)
            else:
                FPS_data = debug_and_read_data(taskset, j)
        save_data(taskset, EDF_data, FPS_data, "U_100_hyper_113400000_10_100/U_100_hyper_113400000_10_100", i, hyperperiod)
    # now we know the overheads and we can make the experiment at t = hyperperiod * U
    for i in range(1, 501):
        good = False
        retry = 0
        taskset = []
        taskset, utilization, EDF_busy_period, FPS_busy_period, EDF_first_DM, EDF_schedulable, FPS_schedulable, \
            hyperperiod = import_taskset(taskset, i, "U_100_hyper_113400000_10_100.csv")
        base_hyperperiod = int(hyperperiod)
        while not good:
            if retry == 0:
                with open('../taskset-experiments/U_100_hyper_113400000_10_100/U_100_hyper_113400000_10_100_'+str(i)+'.csv') as csv_file:
                    csv_reader = csv.reader(csv_file, delimiter=';')
                    numrow = 0
                    for row in csv_reader:
                        if numrow > 0 and numrow <= 20:
                            print(row[10])
                            print(int(base_hyperperiod/int(row[2])))
                            if int (row[10]) < int(base_hyperperiod/int(row[2])):
                                hyperperiod = int(hyperperiod) + int(float(row[2]) * float(row[12]))
                                print(hyperperiod)
                        numrow = numrow + 1
                make_adb_file(taskset, hyperperiod)
                EDF_data = []
                FPS_data = []
                for j in range(2):
                    compile_and_flash_into_board(j)
                    if (j == 0):
                        EDF_data = debug_and_read_data(taskset, j)
                    else:
                        FPS_data = debug_and_read_data(taskset, j)
                save_data(taskset, EDF_data, FPS_data,
                          "U_100_hyper_113400000_10_100_full/U_100_hyper_113400000_10_100_full", i, hyperperiod)
            else:
                with open('../taskset-experiments/U_100_hyper_113400000_10_100_full/U_100_hyper_113400000_10_100_full_' + str(i)+'.csv') as csv_file:
                    csv_reader = csv.reader(csv_file, delimiter=';')
                    good = True
                    numrow = 0
                    for row in csv_reader:
                        if numrow > 0 and numrow <= 20:
                            if int(row[10]) > int(base_hyperperiod/int(row[2])):
                                hyperperiod = int(hyperperiod) - int(float(row[2]) * float(row[12])) - 10
                                good = False
                        numrow = numrow+1
                if not good:
                    make_adb_file(taskset, hyperperiod)
                    EDF_data = []
                    FPS_data = []
                    for j in range(2):
                        compile_and_flash_into_board(j)
                        if (j == 0):
                            EDF_data = debug_and_read_data(taskset, j)
                        else:
                            FPS_data = debug_and_read_data(taskset, j)
                    save_data(taskset, EDF_data, FPS_data,
                              "U_100_hyper_113400000_10_100_full/U_100_hyper_113400000_10_100_full", i, hyperperiod)
            retry = retry + 1

# use a function here
#U_100_hyper_113400000_10_100_full()

