# A05 XXE

## What it is

XXE (XML External Entity) issues occur when an XML parser resolves external entities or loads external DTDs.
This can lead to file disclosure, SSRF, or denial-of-service (entity expansion).

## What it is NOT (common false positives)

- Not “any XML parsing”: XXE requires entity/DTD resolution behavior.
- Not SSRF in general: XXE is one SSRF vector via XML parser behavior.
- Not client-side XML viewing unless the server parses XML unsafely.

## Black-box probe strategy (Burp MCP)

1. Identify XML parsing surfaces:
   - SOAP endpoints (`text/xml`),
   - SAML handlers, XML config imports,
   - file upload/import that accepts XML,
   - endpoints that accept `application/xml`.
2. Capture a baseline request with well-formed XML.
3. Prefer safe validation using OOB detection (Burp Collaborator):
   - inject a DOCTYPE with an external entity referencing your Collaborator URL,
   - place `&xxe;` in a field that is likely parsed.
4. Send the request and observe for Collaborator interactions.

Avoid attempting local file reads unless explicitly authorized.

## Vulnerable signals

- Burp Collaborator receives DNS/HTTP interactions from the target after sending the XML.
- In-band responses contain resolved entity content (rare).
- Parser error messages indicate DTD/entity processing.

## Example attack request (OOB detection)

```http
POST /api/v1/import/xml HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/xml

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "https://<collaborator-host>/xxe">
]>
<root>
  <name>&xxe;</name>
</root>
```

## Source code examples

```python
# Vulnerable
from lxml import etree

def parse_xml_upload(xml_data: bytes):
    parser = etree.XMLParser()
    return etree.fromstring(xml_data, parser)

# Controlled
def parse_xml_upload(xml_data: bytes):
    parser = etree.XMLParser(resolve_entities=False, no_network=True)
    return etree.fromstring(xml_data, parser)
```

## Validation notes

- Confirm the OOB interaction correlates to your specific request (unique path/ID).
- Repeat once to rule out transient network artifacts.
- Treat entity expansion (“billion laughs”) as destructive unless explicitly authorized.

## Control-level mitigations (no patch code)

- Disable DTDs and external entity resolution.
- Disable network access during XML parsing.
- Use hardened parsers for untrusted XML (for example defusedxml equivalents).
- Apply strict content-type and schema validation to XML inputs.
