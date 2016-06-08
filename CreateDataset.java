package utils;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.Socket;
import java.security.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.Temporal;
import java.time.temporal.TemporalAccessor;
import java.time.temporal.TemporalField;
import java.time.temporal.TemporalUnit;
import java.time.temporal.ValueRange;
import java.util.ArrayList;
import java.util.Date;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import javax.print.attribute.standard.DateTimeAtCompleted;

import org.influxdb.InfluxDB;
import org.influxdb.InfluxDB.ConsistencyLevel;
import org.influxdb.InfluxDBFactory;
import org.influxdb.dto.BatchPoints;
import org.influxdb.dto.Point;
import org.influxdb.dto.Query;

public class CreateDataset {

	static final String USER_ARRIVAL_LOG = "logs/timeseries_citrix_rtc_minute.csv";
	static final String CSV_DELIMITOR = ";";
	static final String USER_ARRIVAL_DATA_SET = "logs/rtc_created_dataset.csv";

	public static void main(String[] args) {
		BufferedReader br;
		String line = "";
		BufferedWriter bw;
		int maxInstance = 6;
		double percentOfRI = 0.7;
		int countRI = (int) Math.ceil(maxInstance * percentOfRI);
		int numberOfUserPerInstance = 120;
		int userCoveredInRI = countRI * numberOfUserPerInstance;

		System.out.println(lc.toEpochSecond(ZoneOffset.UTC));

		// System.exit(0);

		try {
			br = new BufferedReader(new FileReader(CreateDataset.USER_ARRIVAL_LOG));
			long start = 1432818000;
			bw = new BufferedWriter(new FileWriter(CreateDataset.USER_ARRIVAL_DATA_SET));

			while ((line = br.readLine()) != null) {
				String[] dataRow = line.split(CSV_DELIMITOR);
				int userReqCount = (int) Math.ceil(Double.parseDouble(dataRow[1]));
				if (userReqCount < userCoveredInRI)
					userReqCount = userCoveredInRI;
				bw.write(start + "," + userReqCount);
				bw.newLine();
				System.out.println(start + "," + userReqCount);
				start += 60;
			}
			bw.flush();
			bw.close();
			br.close();

		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
