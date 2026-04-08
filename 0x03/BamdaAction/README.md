# BamdaAction Scripts

This folder contains Bambda action scripts for Burp Suite Repeater.

## Folder Structure

```text
BamdaAction/
├── CookieSwap.bambda
└── README.md
```

## Available Script

- `CookieSwap.bambda`
	- Rewrites the outgoing `Cookie` header with a different session value.
	- Helps test cross-account access and broken authorization scenarios.
	- Logs response status and key response details for quick verification.

## Notes

- Use against targets where you have explicit permission.
- Record observed behavior in your engagement notes or report template.
