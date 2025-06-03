import glob
import pandas as pd
import os
import re
from tabulate import tabulate

def parse_log_file(filename, table_start_pattern="GEMM"):
    """
    Parse a log file to extract table data into a pandas DataFrame with dynamic headers.
    
    Args:
        filename (str): Path to the log file.
        
    Returns:
        pandas.DataFrame: DataFrame containing the parsed table data.
        
    Raises:
        FileNotFoundError: If the log file does not exist.
        ValueError: If the expected data pattern is not found or is malformed.
    """
    try:
        with open(filename, 'r') as file:
            lines = file.readlines()
        
        # Find the line with "fused-attention"
        for i, line in enumerate(lines):
            if "GEMM" in line:
                # Next line should be headers
                if i + 1 >= len(lines):
                    raise ValueError("Header line not found after 'fused-attention' pattern")
                
                headers = lines[i + 1].strip().split()
                print("headers:", headers)
                # Next line after headers should be data
                if i + 2 >= len(lines):
                    raise ValueError("Data line not found after headers")
                
                data = lines[i + 2].strip().split()[1:]
                print("data:", data)
                # Ensure data length matches headers
                if len(data) != len(headers):
                    raise ValueError("Data length does not match header length")
                
                # Create DataFrame, keeping all values as strings
                df = pd.DataFrame([data], columns=headers)
                
                return df
        
        raise ValueError("Pattern 'fused-attention' not found in log file")
    
    except FileNotFoundError:
        raise FileNotFoundError(f"Log file '{filename}' not found")
    except Exception as e:
        raise ValueError(f"Error parsing log file: {str(e)}")

def calculate_hit_ratio(csv_file):
    """Calculate L2 cache hit ratio from a CSV file."""
    try:
        # Read CSV
        df = pd.read_csv(csv_file)
        
        # Filter rows for TCC_HIT_sum and TCC_MISS_sum
        hit_rows = df[df['Counter_Name'] == 'TCC_HIT_sum']
        miss_rows = df[df['Counter_Name'] == 'TCC_MISS_sum']
        
        # Sum Counter_Value for hits and misses
        hit_sum = hit_rows['Counter_Value'].sum()
        miss_sum = miss_rows['Counter_Value'].sum()
        
        # Calculate hit ratio
        if hit_sum + miss_sum > 0:
            hit_ratio = (hit_sum / (hit_sum + miss_sum)) * 100
            return hit_ratio
        else:
            return None
    except Exception as e:
        print(f"Error processing {csv_file}: {e}")
        return None

def main():
    # Find all directories matching the pattern
    directories = glob.glob('rocprof_cache_batch*')

    print(f"Found directories: {directories}")
    
    if not directories:
        print("No directories found matching the pattern.")
        return
    
    # List to store results
    results = []
    
    for dir_path in directories:
        # Find CSV file
        csv_files = glob.glob(os.path.join(dir_path, '**', '*counter_collection.csv'), recursive=True)
        print(f"Found CSV files in {dir_path}: {csv_files}")
        if not csv_files:
            print(f"No CSV file found in {dir_path}")
            continue
        csv_file = csv_files[0]  # Take the first CSV file
        
        # Calculate hit ratio
        hit_ratio = calculate_hit_ratio(csv_file)
        print(f"Hit ratio for {csv_file}: {hit_ratio}")
        
        # Find log file (assuming it's named rocprofv2.log)
        log_file = os.path.join(dir_path, 'rocprofv2.log')
        if not os.path.exists(log_file):
            print(f"Log file not found: {log_file}")
            continue
        
        # Parse log file to get table row
        log_data = parse_log_file(log_file)
        if log_data is None:
            print(f"Skipping {dir_path} due to missing log data")
            continue
        
        # Combine log data with hit ratio
        result = log_data.copy()
        result['L2 Cache Hit Ratio (%)'] = f"{hit_ratio:.2f}" if hit_ratio is not None else "N/A"
        results.append(result)
    
    if not results:
        print("No results to display.")
        return
    
    # Concatenate all results into a single DataFrame
    final_df = pd.concat(results, ignore_index=True)
    
    # Print the final table using tabulate
    print("\nFinal Results:")
    print(tabulate(final_df, headers='keys', tablefmt='psql', showindex=False))

if __name__ == "__main__":
    main()