import java.io.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.Properties;
import java.util.Enumeration;

class VmInstance implements Comparable {

    public long billingHourStartTime;
    public long billingHourEndTime;

    public long startOfActivePeriod;
    public long endOfActivePeriod;

    public boolean canExtend = true;

    public int machineID = 0;

    public VmInstance(int machineID, long billingHourStartTime, long billingHourEndTime, long startOfActivePeriod,
                      long endOfActivePeriod) {

        this.machineID = machineID;

        this.billingHourStartTime = billingHourStartTime;
        this.billingHourEndTime = billingHourEndTime;

        this.startOfActivePeriod = startOfActivePeriod;
        this.endOfActivePeriod = endOfActivePeriod;

    }

    @Override
    public int compareTo(Object o) {
        long startOfComp = ((VmInstance) o).billingHourEndTime;
        return (int) (this.billingHourEndTime - startOfComp);
    }
}

public class AppElastic {

    static final String CSV_DELIMITOR = ",";
    static long startTimeStamp;
    static ArrayList<VmInstance> runningInstance = new ArrayList<>();
    static int machineID = 0;
    static int machineIDWithRI = 0;
    static ArrayList<VmInstance> runningRiInstances = new ArrayList<>();
    static ArrayList<VmInstance> runningOdiInstances = new ArrayList<>();
    static int secondInMin = 60;

    static int numberOfUserPerInstance;
    static int timeTakenToActive;
    static int timetakenToShutdown;
    static int scaleUpLookAhead;
    static int scaleDownLookAhead;
    static int billingPeriod;
    static double riCost;
    static double odiCost;
    static int totalRI;
    static int workloadSize;
    static int peakWorkload;

    static String ACTUAL_WORKLOAD;
    static String SYSTEM_LOG ;
    static String SYSTEM_LOG_WITH_RI;
    static String VM_BILLING_HOURS_LOG;

    static String VM_BILLING_HOURS_ODI_ONLY_LOG;
    static String VM_BILLING_HOURS_RI_ONLY_LOG;
    static String COST_LOG;
    static String FORECAST_SCALEUP_WORKLOAD;
    static String FORECAST_SCALEDOWN_WORKLOAD;
    static String VM_BILLING_HOURS_WITH_RI_VERBOSE_LOG;
    static String VM_BILLING_HOURS_WITH_RI_LOG;
    static String HISTORICAL_WORKLOAD;
    static String VERBOSE_SYSTEM_LOG;
    static String VERBOSE_SYSTEM_LOG_WITH_RI;

    public static void main(String[] args) throws IOException, InterruptedException {
       int firstArg = 1;
        if (args.length > 0) {
            try {
                firstArg = Integer.parseInt(args[0]);
                if(firstArg>3) {
                    System.err.println("Value should be 1,2 or 3.");
                    System.exit(1);
                }
            } catch (NumberFormatException e) {
                System.err.println("Argument" + args[0] + " must be an integer.");
                System.exit(1);
            }
        }

        readConfigFile();

        switch (firstArg)
        {
            case 1:runAppElastic();
                    break;
            case 2:runAppElasticToCalculateInstanceType();
                break;
            case 3: runAppElasticWithRi();
                break;
            default: System.exit(1);
                break;
        }

    }

    public static void runAppElasticToCalculateInstanceType()
    {
        String line = "";
        BufferedReader br;
        long timeStampT = 0;
        String[] dataRow;
        try {
            br = new BufferedReader(new FileReader(ACTUAL_WORKLOAD));
            for (int i = 0; i < workloadSize; i++) {
                line = br.readLine();
                dataRow = line.split(CSV_DELIMITOR);
                timeStampT = Long.parseLong(dataRow[0]);
                if (i == 0) {
                    startTimeStamp = timeStampT;
                }

                scalingDecision(timeStampT);
            }
            br.close();

            // <editor-fold desc="Stop remaining machines at the end of the simulation">
            BufferedWriter bw1 = new BufferedWriter(new FileWriter(VM_BILLING_HOURS_LOG, true));
            for (int i = 0; i < runningInstance.size(); i++) {
                if(runningInstance.get(i).canExtend) {
                    StringBuilder sb = new StringBuilder().append(runningInstance.get(i).machineID)
                            .append(",")
                            .append(new Date(runningInstance.get(i).billingHourStartTime * 1000))
                            .append(",").append(new Date(runningInstance.get(i).billingHourEndTime * 1000))
                            .append(",").append(new Date(runningInstance.get(i).startOfActivePeriod * 1000))
                            .append(",").append(new Date(runningInstance.get(i).endOfActivePeriod * 1000))
                            .append(",").append((runningInstance.get(i).billingHourEndTime
                                    - runningInstance.get(i).billingHourStartTime) / 60)
                            .append(",").append(odiCost * (((runningInstance.get(i).billingHourEndTime
                                    - runningInstance.get(i).billingHourStartTime) / 60)/60));
                    bw1.write(sb.toString());
                    bw1.newLine();
                    bw1.flush();
                }
            }
            bw1.close();
            //</editor-fold>

            double baseLineCost = calculateBaseLineCost();
            int totalInstancesNeeded = peakWorkload/numberOfUserPerInstance;
            //int totalInstancesNeeded = runningInstance.size();

            BufferedWriter bw;
            bw = new BufferedWriter(new FileWriter(COST_LOG));
            for (int i = 1; i < totalInstancesNeeded;
                 i++) {
                totalRI=i;
                runningOdiInstances.clear();
                runningRiInstances.clear();
                br = new BufferedReader(new FileReader(ACTUAL_WORKLOAD));
                for (int j = 0; j < workloadSize; j++) {
                    line = br.readLine();
                    dataRow = line.split(CSV_DELIMITOR);
                    timeStampT = Long.parseLong(dataRow[0]);
                    if (j == 0) {
                        startTimeStamp = timeStampT;
                    }
                    scalingDecisionWithRI(timeStampT);
                }
                br.close();
                // Calculate Cost of pure ODI.
                double totalRiCost = 0.0;
                totalRiCost += runningRiInstances.size() * (workloadSize / 60) * riCost;;

                double totalOdiCost = 0.0;
                for (int k = 0; k < runningOdiInstances.size(); k++) {

                    totalOdiCost += odiCost * (((runningOdiInstances.get(k).billingHourEndTime
                            - runningOdiInstances.get(k).billingHourStartTime) / 60)/60);
                }
                System.out.println("baseline:"+baseLineCost+" ricost:"+totalRiCost+" odicost:"+totalOdiCost
                +" total "+(totalOdiCost+totalRiCost));
                System.out.println("RI Count:" + runningRiInstances.size() +" ODI Count:" + runningOdiInstances.size());

                bw.write(baseLineCost+","+totalRiCost+","+totalOdiCost
                        +","+(totalOdiCost+totalRiCost) + "," + runningRiInstances.size()
                        +"," + runningOdiInstances.size());
                bw.newLine();

            }
            bw.close();


        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static double calculateBaseLineCost()
    {
        double baseLineCost =  (peakWorkload/numberOfUserPerInstance) * (workloadSize / 60) * riCost;
        //double baseLineCost =  runningInstance.size()  * (workloadSize / 60) * riCost ;
        return baseLineCost;
    }

    public static void runAppElastic()
    {
        String line = "";
        BufferedReader br;
        BufferedWriter bw,verbose_bw;
        long timeStampT = 0;
        int totalRequestAtT = 0;
        String[] dataRow;
        try {
            br = new BufferedReader(new FileReader(ACTUAL_WORKLOAD));
            bw = new BufferedWriter(new FileWriter(SYSTEM_LOG));
            verbose_bw = new BufferedWriter(new FileWriter(VERBOSE_SYSTEM_LOG));
            for (int i = 0; i < workloadSize; i++) {
                line = br.readLine();
                dataRow = line.split(CSV_DELIMITOR);
                timeStampT = Long.parseLong(dataRow[0]);
                totalRequestAtT = Integer.parseInt(dataRow[1]);
                if (i == 0) {
                    startTimeStamp = timeStampT;
                }

                scalingDecision(timeStampT);

                int countOfBilling = 0;
                for (int j = 0; j < runningInstance.size(); j++) {
                    if (timeStampT < runningInstance.get(j).billingHourEndTime)
                        countOfBilling += 1;
                }

                int countOfActive = 0;
                for (int j = 0; j < runningInstance.size(); j++) {
                    if (timeStampT >=  runningInstance.get(j).startOfActivePeriod && timeStampT <= runningInstance.get(j).endOfActivePeriod)
                        countOfActive += 1;
                }

                System.out.println("Stamp: " + timeStampT+ " Time: " + new Date(timeStampT * 1000) + " Users: " + totalRequestAtT + " Demand: "
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + " Active: " + countOfActive
                        + " Billing: " + countOfBilling);

                bw.write(timeStampT + "," + totalRequestAtT + ","
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + "," + countOfActive + ","
                        + countOfBilling);
                bw.newLine();

                verbose_bw.write(timeStampT + "," + new Date(timeStampT * 1000) + "," + totalRequestAtT + ","
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + "," + countOfActive + ","
                        + countOfBilling);
                verbose_bw.newLine();
            }

            bw.close();
            verbose_bw.close();
            // <editor-fold desc="Shutdown remaining ODI instances">
            BufferedWriter bw1 = new BufferedWriter(new FileWriter(VM_BILLING_HOURS_LOG, true));
            for (int i = 0; i < runningInstance.size(); i++) {
                if(runningInstance.get(i).canExtend) {
                    StringBuilder sb = new StringBuilder().append(runningInstance.get(i).machineID)
                            .append(",").append(runningInstance.get(i).billingHourStartTime )
                            .append(",").append(runningInstance.get(i).billingHourEndTime)
                            .append(",").append(runningInstance.get(i).startOfActivePeriod)
                            .append(",").append(runningInstance.get(i).endOfActivePeriod)
                            .append(",").append((runningInstance.get(i).billingHourEndTime
                                    - runningInstance.get(i).billingHourStartTime) / 60)
                            .append(",").append(odiCost * (((runningInstance.get(i).billingHourEndTime
                                    - runningInstance.get(i).billingHourStartTime) / 60)/60));
                    bw1.write(sb.toString());
                    bw1.newLine();
                    bw1.flush();
                }
            }
            bw1.close();
            // </editor-fold>

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public  static void runAppElasticWithRi()
    {
        String line = "";
        BufferedReader br;
        BufferedWriter bwRI, verbose_bwRI;
        long timeStampT = 0;
        int totalRequestAtT = 0;
        String[] dataRow;
        try {
            br = new BufferedReader(new FileReader(ACTUAL_WORKLOAD));
            bwRI = new BufferedWriter(new FileWriter(SYSTEM_LOG_WITH_RI));
            verbose_bwRI = new BufferedWriter(new FileWriter(VERBOSE_SYSTEM_LOG_WITH_RI));
            for (int i = 0; i < workloadSize; i++) {
                line = br.readLine();
                dataRow = line.split(CSV_DELIMITOR);
                timeStampT = Long.parseLong(dataRow[0]);
                totalRequestAtT = Integer.parseInt(dataRow[1]);
                if (i == 0) {
                    startTimeStamp = timeStampT;
                }

                scalingDecisionWithRI(timeStampT);

                // Count with RI.
                int countOfRiBilling = 0;
                for (int j = 0; j < runningRiInstances.size(); j++) {
                    if (timeStampT < runningRiInstances.get(j).billingHourEndTime)
                        countOfRiBilling += 1;
                }
                int countOfOdiBilling = 0;
                for (int j = 0; j < runningOdiInstances.size(); j++) {
                    if (timeStampT < runningOdiInstances.get(j).billingHourEndTime)
                        countOfOdiBilling += 1;
                }
                int countOfOdiActive = 0;
                for (int j = 0; j < runningOdiInstances.size(); j++) {
                    if (timeStampT >=  runningOdiInstances.get(j).startOfActivePeriod && timeStampT <= runningOdiInstances.get(j).endOfActivePeriod)
                        countOfOdiActive += 1;
                }

                System.out.println(timeStampT + "," + totalRequestAtT + ","
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + "," + countOfRiBilling + ","
                        + countOfOdiActive + "," + countOfOdiBilling);

                bwRI.write(timeStampT + "," + totalRequestAtT + ","
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + "," + countOfRiBilling + ","
                        + countOfOdiActive + "," + countOfOdiBilling);
                bwRI.newLine();

                verbose_bwRI.write(timeStampT + "," + new Date(timeStampT * 1000) + "," + totalRequestAtT + ","
                        + (int) Math.ceil((double)totalRequestAtT / numberOfUserPerInstance) + "," + countOfRiBilling + ","
                        + countOfOdiActive + "," + countOfOdiBilling);
                verbose_bwRI.newLine();
            }

            bwRI.close();
            verbose_bwRI.close();

            BufferedWriter bw1;
            bw1 = new BufferedWriter(new FileWriter(VM_BILLING_HOURS_WITH_RI_LOG, true));
            for (int i = 0; i < runningOdiInstances.size(); i++) {
                if(runningOdiInstances.get(i).canExtend) {
                    StringBuilder sb = new StringBuilder().append(runningOdiInstances.get(i).machineID)
                            .append(",").append(runningOdiInstances.get(i).billingHourStartTime)
                            .append(",").append(runningOdiInstances.get(i).billingHourEndTime)
                            .append(",").append(runningOdiInstances.get(i).startOfActivePeriod)
                            .append(",").append(runningOdiInstances.get(i).endOfActivePeriod)
                            .append(",").append((runningOdiInstances.get(i).billingHourEndTime
                                    - runningOdiInstances.get(i).billingHourStartTime) / 60)
                            .append(",").append((((runningOdiInstances.get(i).billingHourEndTime
                                    - runningOdiInstances.get(i).billingHourStartTime) / 60) / 60) * odiCost);
                    bw1.write(sb.toString());
                    bw1.newLine();
                    bw1.flush();
                }
            }

            // </editor-fold>

            // <editor-fold desc="Write RI data">

            for (int i = 0; i < runningRiInstances.size(); i++) {
                StringBuilder sb = new StringBuilder().append(runningRiInstances.get(i).machineID)
                        .append(",").append(runningRiInstances.get(i).billingHourStartTime)
                        .append(",").append(runningRiInstances.get(i).billingHourEndTime)
                        .append(",").append(runningRiInstances.get(i).startOfActivePeriod)
                        .append(",").append(runningRiInstances.get(i).endOfActivePeriod)
                        .append(",").append((runningRiInstances.get(i).billingHourEndTime
                                - runningRiInstances.get(i).billingHourStartTime) / 60)
                        .append(",").append((((runningRiInstances.get(i).billingHourEndTime
                                - runningRiInstances.get(i).billingHourStartTime) / 60)/60) * riCost);
                bw1.write(sb.toString());
                bw1.newLine();
                bw1.flush();

            }
            bw1.close();
            // </editor-fold>
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void scalingDecision(long timeStamp) throws IOException {


        //if(timeStamp == 1443112920) {
        //    System.out.println();
        //}

        // Get predicted load.
        // Check for scale up or down.

        ArrayList<Integer> userInInterval5 = getRequestCountsInTimeRange(timeStamp, timeStamp + scaleUpLookAhead,false);
        Collections.sort(userInInterval5);

            int maxUserInterval5 = userInInterval5.get(userInInterval5.size() - 1);
            int machineReq = (int) Math.ceil((double) maxUserInterval5 / numberOfUserPerInstance);

        if (timeStamp == startTimeStamp) {
            for (int i = 0; i < machineReq; i++) {
                // machine id
                // billingHourStartTime,
                // billingHourEndTime,
                // startOfActivePeriod,
                // endOfActivePeriod
                machineID += 1;
                runningInstance.add(new VmInstance(machineID, timeStamp, timeStamp + billingPeriod,
                        timeStamp + timeTakenToActive, (timeStamp + billingPeriod) - timetakenToShutdown));
            }
            return;
        }

        // Machines currently being billed
        int machineRunning = 0;

        for (int i = 0; i < runningInstance.size(); i++) {
            if(timeStamp <= runningInstance.get(i).endOfActivePeriod)
                machineRunning+=1;
        }

        if (machineReq > machineRunning) {
            int machinesToAdd = machineReq - machineRunning;
            for (int i = 0; i < machinesToAdd; i++) {
                // machine id
                // billingHourStartTime,
                // billingHourEndTime,
                // startOfActivePeriod,
                // endOfActivePeriod
                machineID += 1;
                runningInstance.add(new VmInstance(machineID, timeStamp, timeStamp + billingPeriod,
                        timeStamp + timeTakenToActive, (timeStamp + billingPeriod) - timetakenToShutdown));
            }
        }

        ArrayList<Integer> usersInInterval15 = getRequestCountsInTimeRange(timeStamp, timeStamp + scaleDownLookAhead,true);
        Collections.sort(usersInInterval15);
        int maxUserInterval15 = usersInInterval15.get(usersInInterval15.size() - 1);
        int newMachineReq15 = (int) Math.ceil((double)maxUserInterval15 / numberOfUserPerInstance);

        BufferedWriter bw = new BufferedWriter(new FileWriter(VM_BILLING_HOURS_LOG, true));

        if (machineRunning > newMachineReq15) {
            ArrayList<VmInstance> vmsEndingActivePeriod = new ArrayList<>();
            for (int i = 0; i < runningInstance.size(); i++) {
                if (runningInstance.get(i).endOfActivePeriod == timeStamp) {
                    vmsEndingActivePeriod.add(runningInstance.get(i));
                }
            }

            int totalVmToKill = machineRunning - newMachineReq15;

            if (vmsEndingActivePeriod.size() > 0) {
                // kill all vm's which are ending active period.
                if ( totalVmToKill >= vmsEndingActivePeriod.size() ) {
                    for (int j = 0; j < vmsEndingActivePeriod.size(); j++) {
                        for (int i = 0; i < runningInstance.size(); i++) {
                            if (runningInstance.get(i).machineID == vmsEndingActivePeriod.get(j).machineID) {
                                runningInstance.get(i).canExtend = false;
                                StringBuilder sb = new StringBuilder().append(runningInstance.get(i).machineID)
                                        .append(",").append(runningInstance.get(i).billingHourStartTime )
                                        .append(",").append(runningInstance.get(i).billingHourEndTime)
                                        .append(",").append(runningInstance.get(i).startOfActivePeriod)
                                        .append(",").append(runningInstance.get(i).endOfActivePeriod)
                                        .append(",").append((runningInstance.get(i).billingHourEndTime
                                                - runningInstance.get(i).billingHourStartTime) / 60)
                                        .append(",").append(odiCost * (((runningInstance.get(i).billingHourEndTime
                                                - runningInstance.get(i).billingHourStartTime) / 60)/60));
                                bw.write(sb.toString());
                                bw.newLine();
                                bw.flush();
                            }
                        }
                    }
                }
                // kill only subset of vm's ending active period.
                if (totalVmToKill < vmsEndingActivePeriod.size()) {
                    for (int j = 0; j < totalVmToKill; j++) {
                        for (int i = 0; i < runningInstance.size(); i++) {
                            if (runningInstance.get(i).machineID == vmsEndingActivePeriod.get(j).machineID) {
                                runningInstance.get(i).canExtend = false;
                                StringBuilder sb = new StringBuilder().append(runningInstance.get(i).machineID)
                                        .append(",").append(runningInstance.get(i).billingHourStartTime )
                                        .append(",").append(runningInstance.get(i).billingHourEndTime)
                                        .append(",").append(runningInstance.get(i).startOfActivePeriod)
                                        .append(",").append(runningInstance.get(i).endOfActivePeriod)
                                        .append(",").append((runningInstance.get(i).billingHourEndTime
                                                - runningInstance.get(i).billingHourStartTime) / 60)
                                        .append(",").append(odiCost * (((runningInstance.get(i).billingHourEndTime
                                                - runningInstance.get(i).billingHourStartTime) / 60)/60));
                                bw.write(sb.toString());
                                bw.newLine();
                                bw.flush();
                            }
                        }
                    }
                }
            }
        }

        for (int i = 0; i < runningInstance.size(); i++) {
            if (timeStamp == runningInstance.get(i).endOfActivePeriod && runningInstance.get(i).canExtend) {
                runningInstance.get(i).endOfActivePeriod += billingPeriod;
                runningInstance.get(i).billingHourEndTime += billingPeriod;
            }
        }
    }

    private static void scalingDecisionWithRI(long timeStamp) throws IOException {

        //if(timeStamp == 1432821000) {
        //    System.out.println();
        //}

        // Get predicted load.
        // Check for scale up or down.
        ArrayList<Integer> userInInterval5 = getRequestCountsInTimeRange(timeStamp, timeStamp + timeTakenToActive,false);
        Collections.sort(userInInterval5);
        int maxUserInterval5 = userInInterval5.get(userInInterval5.size() - 1);
        int machineReq = (int) Math.ceil((double)maxUserInterval5 / numberOfUserPerInstance);

        if (timeStamp == startTimeStamp) {
            for (int i = 0; i < totalRI; i++) {
                machineIDWithRI += 1;
                runningRiInstances.add(new VmInstance(machineIDWithRI, timeStamp, timeStamp + billingPeriod,
                        timeStamp, (timeStamp + billingPeriod)));
            }
            machineReq = machineReq - totalRI;
            for (int i = 0; i < machineReq; i++) {
                // machine id
                // billingHourStartTime,
                // billingHourEndTime,
                // startOfActivePeriod,
                // endOfActivePeriod
                machineIDWithRI += 1;
                    runningOdiInstances.add(new VmInstance(machineIDWithRI, timeStamp, timeStamp + billingPeriod,
                            timeStamp + timeTakenToActive, (timeStamp + billingPeriod) - timetakenToShutdown));
            }
            return;
        }

        // Machines currently being reserved.
        int machineRunning = runningRiInstances.size();

        // Machines running in ODI
        for (int i = 0; i < runningOdiInstances.size(); i++) {
            if(timeStamp <= runningOdiInstances.get(i).endOfActivePeriod)
                machineRunning+=1;
        }

        if (machineReq > machineRunning) {
            int machinesToAdd = machineReq - machineRunning;
            for (int i = 0; i < machinesToAdd; i++) {
                // machine id
                // billingHourStartTime,
                // billingHourEndTime,
                // startOfActivePeriod,
                // endOfActivePeriod
                machineIDWithRI += 1;
                    runningOdiInstances.add(new VmInstance(machineIDWithRI, timeStamp, timeStamp + billingPeriod,
                            timeStamp + timeTakenToActive, (timeStamp + billingPeriod) - timetakenToShutdown));

            }
        }

        ArrayList<Integer> usersInInterval15 = getRequestCountsInTimeRange(timeStamp, timeStamp + scaleDownLookAhead,true);
        Collections.sort(usersInInterval15);
        int maxUserInterval15 = usersInInterval15.get(usersInInterval15.size() - 1);
        int newMachineReq15 = (int) Math.ceil((double)maxUserInterval15 / numberOfUserPerInstance);

        BufferedWriter bw = new BufferedWriter(new FileWriter(VM_BILLING_HOURS_WITH_RI_LOG, true));

        if (machineRunning > newMachineReq15) {
            ArrayList<VmInstance> vmsEndingActivePeriod = new ArrayList<>();
            for (int i = 0; i < runningOdiInstances.size(); i++) {
                if (runningOdiInstances.get(i).endOfActivePeriod == timeStamp) {
                    vmsEndingActivePeriod.add(runningOdiInstances.get(i));
                }
            }

            int totalVmToKill = machineRunning - newMachineReq15;

            if (vmsEndingActivePeriod.size() > 0) {
                // kill all vm's which are ending active period.
                if ( totalVmToKill >= vmsEndingActivePeriod.size() ) {
                    for (int j = 0; j < vmsEndingActivePeriod.size(); j++) {
                        for (int i = 0; i < runningOdiInstances.size(); i++) {
                            if (runningOdiInstances.get(i).machineID == vmsEndingActivePeriod.get(j).machineID) {
                                runningOdiInstances.get(i).canExtend = false;
                                StringBuilder sb =new StringBuilder().append(runningOdiInstances.get(i).machineID)
                                        .append(",").append(runningOdiInstances.get(i).billingHourStartTime)
                                        .append(",").append(runningOdiInstances.get(i).billingHourEndTime)
                                        .append(",").append(runningOdiInstances.get(i).startOfActivePeriod)
                                        .append(",").append(runningOdiInstances.get(i).endOfActivePeriod)
                                        .append(",").append((runningOdiInstances.get(i).billingHourEndTime
                                                - runningOdiInstances.get(i).billingHourStartTime) / 60)
                                        .append(",").append((((runningOdiInstances.get(i).billingHourEndTime
                                                - runningOdiInstances.get(i).billingHourStartTime) / 60) / 60) * odiCost);
                                bw.write(sb.toString());
                                bw.newLine();
                                bw.flush();
                            }
                        }
                    }
                }
                // kill only subset of vm's ending active period.
                if (totalVmToKill < vmsEndingActivePeriod.size()) {
                    for (int j = 0; j < totalVmToKill; j++) {
                        for (int i = 0; i < runningOdiInstances.size(); i++) {
                            if (runningOdiInstances.get(i).machineID == vmsEndingActivePeriod.get(j).machineID) {
                                runningOdiInstances.get(i).canExtend = false;
                                StringBuilder sb = new StringBuilder().append(runningOdiInstances.get(i).machineID)
                                        .append(",").append(runningOdiInstances.get(i).billingHourStartTime)
                                        .append(",").append(runningOdiInstances.get(i).billingHourEndTime)
                                        .append(",").append(runningOdiInstances.get(i).startOfActivePeriod)
                                        .append(",").append(runningOdiInstances.get(i).endOfActivePeriod)
                                        .append(",").append((runningOdiInstances.get(i).billingHourEndTime
                                                - runningOdiInstances.get(i).billingHourStartTime) / 60)
                                        .append(",").append((((runningOdiInstances.get(i).billingHourEndTime
                                                - runningOdiInstances.get(i).billingHourStartTime) / 60) / 60) * odiCost);
                                bw.write(sb.toString());
                                bw.newLine();
                                bw.flush();
                            }
                        }
                    }
                }
                bw.close();
            }
        }

        for (int i = 0; i < runningOdiInstances.size(); i++) {
            if (timeStamp == runningOdiInstances.get(i).endOfActivePeriod && runningOdiInstances.get(i).canExtend) {
                runningOdiInstances.get(i).endOfActivePeriod += billingPeriod;
                runningOdiInstances.get(i).billingHourEndTime += billingPeriod;
            }
        }

        for (int i = 0; i < runningRiInstances.size(); i++) {
            if (timeStamp == runningRiInstances.get(i).endOfActivePeriod) {
                runningRiInstances.get(i).endOfActivePeriod += billingPeriod;
                runningRiInstances.get(i).billingHourEndTime += billingPeriod;
            }

        }
    }

    private static ArrayList<Integer> getRequestCountsInTimeRange(long startT, long endT, boolean isScaleDown) {
        String line = "";
        ArrayList<Integer> countArray = new ArrayList<>();
        try {
            BufferedReader br;
            if(isScaleDown) {
                 br = new BufferedReader(new FileReader(FORECAST_SCALEDOWN_WORKLOAD));
            }
            else
            {
                br = new BufferedReader(new FileReader(FORECAST_SCALEUP_WORKLOAD));
            }
            while ((line = br.readLine()) != null) {
                String[] dataRow = line.split(CSV_DELIMITOR);
                long timeStampT = Long.parseLong(dataRow[0]);
                int totalRequestAtT = (int)Math.ceil(Double.parseDouble(dataRow[1]));
                if (timeStampT >= startT && timeStampT <= endT) {
                    countArray.add(totalRequestAtT);
                }
                if (timeStampT > endT)
                    break;
            }
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        Collections.sort(countArray);
        return countArray;
    }

    private static void readConfigFile(){
        Properties prop = new Properties();
        InputStream configFile = null;
        try {
            configFile=new FileInputStream("config/appelastic.conf");
            prop.load(configFile);
        } catch (IOException ex) {
            ex.printStackTrace();
        } finally {
            if (configFile != null) {
                try {
                    configFile.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        System.out.println(":::Printing AppElastic Configuration:::");
        Enumeration<?> el = prop.propertyNames();
        while (el.hasMoreElements()) {
            String key = (String) el.nextElement();
            String value = prop.getProperty(key);
            System.out.println("Key : " + key + ", Value : " + value);
        }
        System.out.println(":::::::::::::::::::::::::::::::::::::::");

        numberOfUserPerInstance=Integer.parseInt(prop.getProperty("NUMBER_OF_USERS_PER_INSTANCES"));
        timeTakenToActive=Integer.parseInt(prop.getProperty("VM_START_TIME")) * secondInMin;
        timetakenToShutdown=Integer.parseInt(prop.getProperty("VM_SHUTDOWN_TIME")) * secondInMin;
        scaleUpLookAhead=Integer.parseInt(prop.getProperty("LOOKAHEAD_SCALEUP")) * secondInMin;
        scaleDownLookAhead=Integer.parseInt(prop.getProperty("LOOKAHEAD_SCALEDOWN")) * secondInMin;
        billingPeriod=Integer.parseInt(prop.getProperty("BILLING_PERIOD")) * secondInMin;
        riCost=Double.parseDouble(prop.getProperty("COST_RI"));
        odiCost=Double.parseDouble(prop.getProperty("COST_ODI"));
        totalRI=Integer.parseInt(prop.getProperty("TOTAL_RI"));
        workloadSize=Integer.parseInt(prop.getProperty("WORKLOAD_SIZE"));
        peakWorkload=Integer.parseInt(prop.getProperty("PEAK_WORKLOAD"));

        ACTUAL_WORKLOAD=prop.getProperty("ACTUAL_WORKLOAD");
        HISTORICAL_WORKLOAD=prop.getProperty("ACTUAL_WORKLOAD");
        SYSTEM_LOG=prop.getProperty("SYSTEM_LOG");
        SYSTEM_LOG_WITH_RI=prop.getProperty("SYSTEM_LOG_WITH_RI");
        VM_BILLING_HOURS_LOG=prop.getProperty("VM_BILLING_HOURS_LOG");
        COST_LOG=prop.getProperty("COST_LOG");
        FORECAST_SCALEUP_WORKLOAD=prop.getProperty("FORECAST_SCALEUP_WORKLOAD");
        FORECAST_SCALEDOWN_WORKLOAD=prop.getProperty("FORECAST_SCALEDOWN_WORKLOAD");
        VERBOSE_SYSTEM_LOG=prop.getProperty("VERBOSE_SYSTEM_LOG");
        VERBOSE_SYSTEM_LOG_WITH_RI=prop.getProperty("VERBOSE_SYSTEM_LOG_WITH_RI");
        VM_BILLING_HOURS_WITH_RI_VERBOSE_LOG=prop.getProperty("VM_BILLING_HOURS_WITH_RI_VERBOSE_LOG");
        VM_BILLING_HOURS_WITH_RI_LOG=prop.getProperty("VM_BILLING_HOURS_WITH_RI_LOG");
    }
}
