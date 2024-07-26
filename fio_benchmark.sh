#!/bin/bash

# Parse command-line arguments
IFS=',' read -ra BLOCK_SIZES <<< "$1"
IFS=',' read -ra IO_DEPTHS <<< "$2"
IFS=',' read -ra ACCESS_PATTERNS <<< "$3"
FILE_SIZE="$4"
RUNTIME="$5"

TEST_FILE="/data/fio_test_file"

CSV_FILE="/app/fio_summary.csv"
echo "Block Size,Access Pattern,I/O Depth,IOPS,Bandwidth (MB/s),Latency (us)" > "${CSV_FILE}"

for bs in "${BLOCK_SIZES[@]}"; do
  for rw in "${ACCESS_PATTERNS[@]}"; do
    for io_depth in "${IO_DEPTHS[@]}"; do
      TEST_NAME="${rw}_${bs}_iodepth${io_depth}"
      echo "Running test: ${TEST_NAME}"
      FIO_JSON_OUTPUT=$(fio --name="${TEST_NAME}" \
                            --filename="${TEST_FILE}" \
                            --rw="${rw}" \
                            --direct=1 \
                            --bs="${bs}" \
                            --ioengine=io_uring \
                            --runtime="${RUNTIME}" \
                            --time_based \
                            --group_reporting \
                            --size="${FILE_SIZE}" \
                            --iodepth="${io_depth}" \
                            --output-format=json 2>&1 | jq -c 'select(.jobs != null)')
      echo "Completed test: ${TEST_NAME}"
      IOPS=$(echo "$FIO_JSON_OUTPUT" | jq '.jobs[0].read.iops + .jobs[0].write.iops')
      BANDWIDTH_MB=$(echo "$FIO_JSON_OUTPUT" | jq '(.jobs[0].read.bw + .jobs[0].write.bw) / 1024')
      if [[ "$rw" == "read" || "$rw" == "randread" || "$rw" == "readwrite" ]]; then
        LATENCY_US=$(echo "$FIO_JSON_OUTPUT" | jq '.jobs[0].read.lat_ns.mean / 1000')
      else
        LATENCY_US=$(echo "$FIO_JSON_OUTPUT" | jq '.jobs[0].write.lat_ns.mean / 1000')
      fi
      echo "${bs},${rw},${io_depth},${IOPS},${BANDWIDTH_MB},${LATENCY_US}" >> "${CSV_FILE}"
    done
  done
done

echo "FIO benchmark completed. Results saved to ${CSV_FILE}"
cat "${CSV_FILE}"  # Print CSV contents for debugging