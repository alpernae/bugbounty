# GetScopes - HackerOne Scope Fetcher

A command-line tool to fetch and filter in-scope domains from HackerOne programs.

## Features

- Fetch scopes from HackerOne programs
- Filter by bounty or VDP programs
- Rate limiting for API requests
- Output in JSON or TXT format
- Filter wildcards and domains separately

## Installation

```bash
git clone <repository_url>
cd GetScopes
pip install -r requirements.txt
chmod +x getallscope.py
```

## Configuration

Set your HackerOne API credentials:
```bash
./getallscope.py -c "username:api_token"
```

The configuration will be saved in `~/.config/getscope/config.yaml`

## Usage

### Fetch Program Scopes

```bash
# Get all program scopes
./getallscope.py

# Get only bounty programs
./getallscope.py -b true

# Get only VDP programs
./getallscope.py -b false

# Save output as JSON
./getallscope.py -o json

# Save output as TXT
./getallscope.py -o txt
```

### Filter Domains

```bash
# Filter wildcards from a file
./filter.py -w scope_all_programs.txt -f w

# Filter domains from a file
./filter.py -w scope_all_programs.txt -f d
```

## Output Examples

### Text Output
```
domain1.com
domain2.com
*.wildcard1.com
```

### JSON Output

```json
{
  "programs": {
    "program1": {
      "urls": [...],
      "wildcards": [...],
    }
  }
}
```
