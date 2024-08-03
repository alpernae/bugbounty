# Personal Bug Bounty Testing Note

This template was created for bug bounty hunters who like to take notes and stay on track.

## Target Information

| Target ID | Program/Asset Name | URL | Description | Known Issues  | Additional Notes |
|---|---|---|---|---|---|
| 1 | Example E-commerce Platform | <https://example.com> | A web application for buying and selling products, featuring user registration, login, and shopping cart functionality. | N/A | - |
| 2 | Example E-commerce Platform | <https://example.com> | A web application for buying and selling products, featuring user registration, login, and shopping cart functionality. | N/A | - |

**Additional Notes:**

- For Target 2, consider testing both the default installation and a custom theme to cover a wider range of potential vulnerabilities.

## 2. Program Details

**Program Rules**
  - Use hackerone alies @wearehackerone.com

**In-scope:**
  - Web application and APIs
  - Publicly accessible subdomains
 
**Out-of-scope:**
  - Internal networks and assets
  - Third-party services and websites
  - Denial of Service (DoS) and Distributed Denial of Service (DDoS) attacks
  - Social engineering attacks

## 3. Test Accounts

**Admin Account**
  - **Email:** admin@example.com
  - **Password:** P@ssw0rd
  - **Notes:** Created using the 'Create Admin Account' functionality in the application's admin panel.

**Regular User Account**
  - **Email:** user@example.com
  - **Password:** User123!
  - **Notes:** Registered using the 'Sign Up' functionality on the homepage.

**Test Products**
  - **SKU:** TEST123
  - **Name:** Test Product 1
  - **Price:** $10.00
  - **Notes:** Created using the 'Add Product' functionality in the admin panel for testing purposes.

## 4. Objectives

**Primary Objectives:**
  - Identify unauthorized access vectors to user data and functionality.
  - Find and exploit authentication bypass vulnerabilities.
  - Discover and report any sensitive data exposure.

**Secondary Objectives:**
  - Evaluate the application's business logic and rate limiting mechanisms.
  - Assess the security of custom-built components and third-party integrations.
  - Identify potential security misconfigurations and best practice violations.

## 5. Testing Methodology (Will be Update Soon!)

**Briefly describe your testing methodology and approach**

- **Manual Testing:**
  - Follow the OWASP Testing Guide (v4.2.1) as a primary reference.
  - Utilize Burp Suite Community Edition for manual testing and automation.
  - Perform manual testing of the web application, APIs, and other in-scope targets.
- **Automated Testing:**
  - Use OWASP ZAP (v2.11.0) for automated scanning and fuzzing.
  - Create custom scripts and tools to automate specific tests and tasks.
  - Integrate automated testing into the continuous integration/continuous deployment (CI/CD) pipeline, if applicable.
- **Documentation:**
  - Maintain detailed notes and findings using this template.
  - Keep screenshots, videos, and other evidence to support claims and reproduce issues.

## 6. Testing Phases and Findings

**Results and findings from various testing phases and details**

### 6.1 Unauthenticated Tests

| Title | Description | Steps to Reproduce | PoC | Impact | Remediation | Status |
|---|---|---|---|---|---|---|
| Unauthorized Access to User Data via Weak API Endpoint | An unauthenticated user can access any user's data by manipulating the API endpoint parameters. | 1. Open the browser and navigate to <https://example.com/api/users?id=123>. 2. Observe that the API returns user data without requiring authentication. | `curl -X GET "https://example.com/api/users?id=123"` | Compromised user data could lead to account takeovers, unauthorized access to sensitive information, and potential financial losses for users. | Implement proper authentication and authorization checks for API endpoints. Consider using API keys or OAuth for better security. | Acknowledged |

### 6.2 Authenticated Tests

| Title | Description | Steps to Reproduce | PoC | Impact | Remediation | Status |
|---|---|---|---|---|---|---|
| Insecure Direct Object References (ID| Insecure Direct Object References (IDOR) - User Profile Update | A logged-in user can update another user's profile by manipulating the request parameters. | 1. Log in as a regular user (user@example.com). 2. Navigate to the user profile page (e.g., <https://example.com/profile/123>). 3. Open the browser developer tools and modify the request parameters to update another user's profile (e.g., change the 'name' parameter to 'New Name'). 4. Submit the request and observe that the other user's profile is updated. | `curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "name=New%20Name" "https://example.com/api/users/456"` | An attacker could update other users' profiles, change their passwords, or perform other unauthorized actions, leading to account compromise and data loss. | Implement proper authorization checks to ensure that users can only update their own profiles. | Acknowledged |

### 6.3 Business Logic Tests

| Title | Description | Steps to Reproduce | PoC | Impact | Remediation | Status |
|---|---|---|---|---|---|---|
| Bypass Minimum Order Quantity (MOQ) | A user can bypass the minimum order quantity requirement by manipulating the request parameters. | 1. Add a product with a MOQ of 10 to the cart. 2. Open the browser developer tools and modify the request parameters to change the quantity to 5. 3. Proceed to checkout and observe that the order is placed successfully. | `curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "quantity=5" "https://example.com/api/cart/update"` | An attacker could exploit this vulnerability to purchase products in smaller quantities than intended, leading to stock mismanagement and potential financial losses for the vendor. | Implement proper input validation and sanitization to prevent users from bypassing the MOQ requirement. | Acknowledged |

### 6.4 Other Tests

| Title | Description | Steps to Reproduce | PoC | Impact | Remediation | Status |
|---|---|---|---|---|---|---|
| Rate Limiting Bypass - Account Creation | An attacker can bypass the account creation rate limiting mechanism by using multiple IP addresses or rotating proxies. | 1. Create a script to automate account creation requests. 2. Use a rotating proxy service to change IP addresses between requests. 3. Observe that the rate limiting mechanism is bypassed, allowing an attacker to create multiple accounts in a short period. | N/A (script-based attack) | An attacker could exploit this vulnerability to create multiple accounts, leading to inflated user numbers, spam, or other malicious activities. | Implement a more robust rate limiting mechanism that considers user behavior, device fingerprints, and other factors to prevent IP address-based bypasses. | In Progress |

## 7. Timeline

| Event | Date and Time (UTC) |
|---|---|
| Discovered Unauthorized Access to User Data via Weak API Endpoint | 2024-08-03 12:00 |
| Submitted Unauthorized Access to User Data via Weak API Endpoint | 2024-08-03 13:00 |
| Triage Started - Unauthorized Access to User Data via Weak API Endpoint | 2024-08-04 09:00 |
| Discovered Insecure Direct Object References (IDOR) - User Profile Update | 2024-08-05 14:30 |
| Submitted Insecure Direct Object References (IDOR) - User Profile Update | 2024-08-05 15:00 |
| Discovered Bypass Minimum Order Quantity (MOQ) | 2024-08-06 10:00 |
| Submitted Bypass Minimum Order Quantity (MOQ) | 2024-08-06 10:30 |
| Discovered Rate Limiting Bypass - Account Creation | 2024-08-07 16:45 |
| Submitted Rate Limiting Bypass - Account Creation | 2024-08-07 17:00 |

