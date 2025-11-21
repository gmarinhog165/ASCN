#!/bin/bash

# Default JMeter and test file locations
JMETER_DIR="/opt/jmeter/apache-jmeter-5.6.3/bin"
TEST_FILE="MoonshotTesSimpl.jmx"
RESULT_FILE="results.txt"
LOG_FILE="/tmp/jmeter.log"

# Function to show usage
usage() {
  echo "Usage: $0 -i <IP_ADDRESS> -t <NUMBER_OF_THREADS>"
  echo "  -i    IP address of the server (e.g., 127.0.0.1)"
  echo "  -t    Number of threads (e.g., 20)"
  exit 1
}

# Parse command-line arguments
while getopts ":i:t:" opt; do
  case $opt in
    i) IP_ADDRESS="$OPTARG" ;;
    t) THREAD_COUNT="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check if parameters are set
if [[ -z "$IP_ADDRESS" || -z "$THREAD_COUNT" ]]; then
  usage
fi

# Navigate to JMeter directory
cd "$JMETER_DIR" || { echo "Failed to navigate to $JMETER_DIR"; exit 1; }

# Update the test plan with the provided parameters
sed -i "s|<stringProp name=\"HTTPSampler.domain\">.*</stringProp>|<stringProp name=\"HTTPSampler.domain\">$IP_ADDRESS</stringProp>|" "$TEST_FILE"
sed -i "s|<intProp name=\"ThreadGroup.num_threads\">.*</intProp>|<intProp name=\"ThreadGroup.num_threads\">$THREAD_COUNT</intProp>|" "$TEST_FILE"

# Run JMeter test with custom log file
echo "Running JMeter test with IP: $IP_ADDRESS and Threads: $THREAD_COUNT..."
./jmeter -n -t "./$TEST_FILE" -l "$RESULT_FILE" -j "$LOG_FILE"

# Check for test completion
if [ $? -eq 0 ]; then
  echo "JMeter test completed successfully."
  echo "Results saved to $RESULT_FILE."
  echo "Log file saved to $LOG_FILE."
else
  echo "JMeter test failed. Check log file at $LOG_FILE."
  exit 1
fi
