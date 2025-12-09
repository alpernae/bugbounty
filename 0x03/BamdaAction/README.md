# Bambda Action Scripts

The `BamdaAction` directory contains a collection of custom Bambda action scripts designed to improve the efficiency of bug bounty hunting. These scripts automate common tasks in Burp Suite Repeater, streamline workflows, and help bounty hunters focus on identifying security vulnerabilities.

Burp Suite Bambda Action Scripts empower you to automate and optimize your bug bounty workflow. Acting as programmable assistants within Burp Suite, these scripts can handle repetitive or complex tasks—such as vulnerability scanning, automated reconnaissance, or executing custom exploits—so you can focus on analysis and creativity. By leveraging Bambda Action Scripts, you can ensure consistency, save time, and make your security testing process more efficient and enjoyable.

# Bambda Action Folder Structure

```
BamdaAction/
├── CookieSwap.bambda
└── README.md
```

### Explanation

- **CookieSwap.bambda**: Intercepts and modifies an HTTP request by replacing its `Cookie` header with another user's session cookie for IDOR/privilege escalation testing. Logs the response status and prints either the response body or redirect location.
