# Bambda Action Scripts

The `BamdaAction` directory contains a collection of custom Bambda action scripts designed to improve the efficiency of bug bounty hunting. These scripts automate common tasks in Burp Suite Repeater, streamline workflows, and help bounty hunters focus on identifying security vulnerabilities.

Burp Suite Bambda Action Scripts empower you to automate and optimize your bug bounty workflow. Acting as programmable assistants within Burp Suite, these scripts can handle repetitive or complex tasks—such as vulnerability scanning, automated reconnaissance, or executing custom exploits—so you can focus on analysis and creativity. By leveraging Bambda Action Scripts, you can ensure consistency, save time, and make your security testing process more efficient and enjoyable.

# Bambda Action Folder Structure

```
BambdaAction/
├── Cookie Swap 
│   
|
```

### Explanation

- **CookieSwap**: This script demonstrates how to intercept and modify an HTTP request by replacing its Cookie header with another user's session cookie. It is designed for security testing, such as checking for IDOR or privilege escalation vulnerabilities. The script logs the response status and, depending on the result, outputs either the response body or the redirect location
