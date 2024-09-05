# HACKERONE

The `hackerone/` folder contains tools specifically designed to interact with the HackerOne platform, aiding bug bounty hunters in automating and simplifying tasks associated with managing HackerOne programs and submissions.

<details>
<summary> <strong>0x01 | h1fecther</strong></summary>
    
#### Description:
`h1fetcher.sh` is a Bash script designed to query a specific HackerOne program for in-scope or out-of-scope targets based on their eligibility for submission. The script retrieves data from the HackerOne API and allows users to filter results based on scope (eligible for submission or not). The filtered results are saved to an output file.

#### Features:
- **Command-line Arguments**:
  - `-handle`: The handle (name) of the HackerOne program to query.
  - `-scope`: Specify whether to fetch in-scope (`true`) or out-of-scope (`false`) targets.
  - `-output` (optional): Specify the name or path of the output file. If not provided, the results will be saved to a default file `targets.txt`.

- **API Credentials**: The script relies on environment variables `H1_USERNAME` and `H1_APIKEY` for authentication to the HackerOne API.

#### Usage:
```bash
./h1fetcher.sh -handle [program_name] -scope [true|false] [-output [file_path]]
```

#### Example:
```bash
./h1fetcher.sh -handle tinder -scope true -output tinder_inscope.txt
```

This command fetches the in-scope targets for the "tinder" program and saves the results to `tinder_inscope.txt`.

#### Requirements:
- **Environment Variables**:
  - `H1_USERNAME`: Your HackerOne username.
  - `H1_APIKEY`: Your HackerOne API key.

#### Error Handling:
- If the `-handle` or `-scope` options are not provided, the script will exit with an error.
- If the environment variables are missing, the script will notify the user and exit.
- If no targets match the specified scope, the script will display a message and exit without writing data.

#### Notes:
- Ensure you have `jq` installed for JSON parsing.
  
#### Installation:
1. Clone or download the script.
2. Make sure the script has executable permissions:
   ```bash
   chmod +x h1fetcher.sh
   ```

3. Export your API credentials to your environment:
   ```bash
   export H1_USERNAME="your_username"
   export H1_APIKEY="your_api_key"
   ```
</details>

#### Key Tools:

- **h1fetcher.sh**: 
  A script to fetch structured scopes and program details from HackerOne based on the provided handle. It helps to quickly retrieve eligible in-scope targets for a particular program.
  
- **h1reporter.sh** (Future Script): 
  Planned to automate the reporting process for HackerOne submissions, streamlining the process of crafting and submitting bug reports with proper formatting.
  
- **h1alerts.sh** (Future Script): 
  A script under development that will notify users of any changes or updates in the scope or bounty programs they are monitoring, helping hunters stay informed.

  Each script is designed to interact directly with the HackerOne API, leveraging API credentials for seamless integration and efficiency in bug bounty workflows. The folder is intended to grow with more HackerOne-specific utilities to support various bug bounty processes.
