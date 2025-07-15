import json
import os

def convert_to_ndjson(input_file, output_file):
    # Read the input JSON file
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Write to output file in NDJSON format
    with open(output_file, 'w', encoding='utf-8') as f:
        for item in data:
            f.write(json.dumps(item) + '\n')

# File paths
input_files = [
    r'C:\Users\mpoira01\OneDrive - dentsu\Documents\data\groups.json',
    r'C:\Users\mpoira01\OneDrive - dentsu\Documents\data\users.json',
    r'C:\Users\mpoira01\OneDrive - dentsu\Documents\data\venues.json',
    r'C:\Users\mpoira01\OneDrive - dentsu\Documents\data\events.json'
]

for input_file in input_files:
    # Create output filename by adding '_ndjson' before the extension
    base, ext = os.path.splitext(input_file)
    output_file = f"{base}_ndjson{ext}"
    
    try:
        convert_to_ndjson(input_file, output_file)
        print(f"Successfully converted {input_file} to NDJSON format")
        print(f"Output saved to: {output_file}")
    except Exception as e:
        print(f"Error processing {input_file}: {str(e)}") 