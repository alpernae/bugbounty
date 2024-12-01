# Week 1: HTTP, Browsers, and Web Architecture Basics (5 Days)

| **Day** | **Focus Area**               | **Detailed Tasks**                                                                                                                                                               | **Sources**                                                                                                                                            | **Relevant RFCs**                                         | **LH/HH** | **Notes**                                   |
|---------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|-----------|---------------------------------------------|
| **1**   | **HTTP Basics**              | - **Study:** Learn the basics of HTTP: request/response cycle, HTTP methods (GET, POST, PUT, DELETE).<br>- **Practical:** Use `curl` to send HTTP requests and examine responses.<br>- **Document:** Note common status codes and headers. | - [MDN HTTP Overview](https://developer.mozilla.org/en-US/docs/Web/HTTP)<br>- [HTTP Pocket Guide](https://httpstatuses.com/)                           | - RFC 7231: HTTP/1.1 Semantics and Content<br>- RFC 2616: HTTP/1.1 | **4 LH**  | Focus on understanding HTTP communication. |
| **2**   | **HTTP Headers**             | - **Study:** Analyze key headers like `Content-Type`, `Authorization`, `Cookie`, `Set-Cookie`, and security headers (e.g., `X-Frame-Options`).<br>- **Practical:** Capture HTTP traffic with Burp Suite and analyze headers.<br>- **Document:** Differences between request and response headers. | - [MDN HTTP Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)<br>- [OWASP Header Cheat Sheet](https://owasp.org/www-project-secure-headers/) | - RFC 6265: HTTP State Management Mechanism (Cookies)     | **4 LH**  | Security headers are critical for securing web apps. |
| **3**   | **HTTPS and TLS**            | - **Study:** Basics of HTTPS and TLS: encryption, certificates, and chain of trust.<br>- **Practical:** Use tools like `openssl` to inspect SSL/TLS certificates.<br>- **Document:** Differences between valid and invalid certificates. | - [SSL Labs Guide](https://www.ssllabs.com/ssltest/)<br>- [How HTTPS Works](https://howhttps.works/)                                                   | - RFC 5246: TLS 1.2<br>- RFC 8446: TLS 1.3                  | **4 LH**  | Build knowledge about secure communication mechanisms. |
| **4**   | **Web Browsers**             | - **Study:** How browsers work: rendering engines, DOM, and event loops.<br>- **Practical:** Use DevTools to inspect network requests and DOM manipulation.<br>- **Explore:** Test cross-origin requests and understand CORS policies. | - [How Browsers Work](https://web.dev/howbrowserswork/)<br>- [CORS MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)                         | - RFC 6454: Origin Policy for CORS                          | **4 LH**  | This knowledge is essential for understanding client-side vulnerabilities. |
| **5**   | **Web Architecture Basics**  | - **Study:** Learn client-server models, APIs, reverse proxies, and microservices.<br>- **Practical:** Analyze server responses and API structures with tools like Burp Suite or Postman.<br>- **Document:** Common API patterns like REST. | - [MDN Client-Server Model](https://developer.mozilla.org/en-US/docs/Learn/Server-side/First_steps/Client-Server_overview)<br>- [API Design Guide](https://apidocs.io/) | - RFC 7231: HTTP Semantics<br>- RFC 8259: JSON Format       | **4 LH**  | Focus on understanding API communication patterns. |

---

## Week 1 Totals
| **Type**   | **Hours** |
|------------|-----------|
| **Learning Hours (LH):** 20 |
| **Hunting Hours (HH):** 0  |

---

### Notes:
- This structure assumes 5 days of focused learning per week, with weekends reserved for optional revision or rest.
- Labs and practical work do not count as hunting hours.

