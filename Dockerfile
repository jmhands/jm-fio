# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    fio \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Streamlit using --break-system-packages
RUN pip3 install --break-system-packages streamlit pandas

# Set up working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app /data

# Copy the FIO benchmark script and Streamlit app
COPY fio_benchmark.sh /app/fio_benchmark.sh
COPY streamlit_app.py /app/streamlit_app.py

# Make the benchmark script executable
RUN chmod +x /app/fio_benchmark.sh

# Expose port 8501 for the Streamlit server
EXPOSE 8501

# Run the Streamlit app
CMD ["streamlit", "run", "/app/streamlit_app.py", "--server.port", "8501", "--server.address", "0.0.0.0"]