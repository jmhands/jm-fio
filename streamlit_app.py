import streamlit as st
import pandas as pd
import os
import subprocess

# Function to run FIO benchmark
def run_fio_benchmark(block_sizes, io_depths, access_patterns, file_size, runtime):
    try:
        command = [
            "/app/fio_benchmark.sh",
            ",".join(block_sizes),
            ",".join(map(str, io_depths)),
            ",".join(access_patterns),
            file_size,
            str(runtime)
        ]
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        st.success("Benchmark completed successfully!")
        st.text(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        st.error(f"An error occurred while running the benchmark: {e}")
        st.text(e.stdout)
        st.text(e.stderr)
        return False

# Load data
def load_data():
    csv_path = "/app/fio_summary.csv"
    if not os.path.exists(csv_path):
        return pd.DataFrame()
    df = pd.read_csv(csv_path)
    return df

# Main app
def main():
    st.title("FIO Benchmark")

    # Parameter selection
    st.header("Select Benchmark Parameters")

    col1, col2 = st.columns(2)

    with col1:
        block_sizes = st.multiselect(
            "Block Sizes",
            options=["4k", "16k", "32k", "64k", "128k"],
            default=["4k", "128k"]
        )

        io_depths = st.multiselect(
            "I/O Depths",
            options=[1, 4, 16, 32, 64, 128, 256],
            default=[1, 16, 256]
        )

        access_patterns = st.multiselect(
            "Access Patterns",
            options=["read", "write", "readwrite", "randread", "randwrite"],
            default=["read", "write"]
        )

    with col2:
        file_size = st.text_input("File Size (e.g., 1G, 512M)", "1G")
        runtime = st.number_input("Runtime (seconds)", min_value=1, value=10)

    if st.button("Run Benchmark"):
        with st.spinner("Running FIO benchmark..."):
            run_fio_benchmark(block_sizes, io_depths, access_patterns, file_size, runtime)

    # Load and display results
    df = load_data()

    if not df.empty:
        st.header("Benchmark Results")

        # Create bar charts
        st.subheader("Bandwidth vs I/O Depth")

        for pattern in df["Access Pattern"].unique():
            st.write(f"{pattern.capitalize()} Access Pattern")
            pattern_data = df[df["Access Pattern"] == pattern]

            chart_data = pattern_data.pivot(index="I/O Depth", columns="Block Size", values="Bandwidth (MB/s)")
            chart_data = chart_data.sort_index()

            st.bar_chart(chart_data)

        # Display table
        st.subheader("Detailed Results")
        st.dataframe(df)

        # Download CSV button
        csv = df.to_csv(index=False)
        st.download_button(
            label="Download results as CSV",
            data=csv,
            file_name="fio_results.csv",
            mime="text/csv",
        )
    else:
        st.info("Run the benchmark to see results.")

if __name__ == "__main__":
    main()