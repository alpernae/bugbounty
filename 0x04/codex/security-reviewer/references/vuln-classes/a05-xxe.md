# A05 XXE

## What it is
XXE (XML External Entity) issues happen when an XML parser resolves external entities or loads external DTDs.
This can lead to file disclosure, SSRF, or denial-of-service (entity expansion).

## What it is NOT (common false positives)
- **Not “any XML parsing”**: XXE requires entity/DTD resolution behavior.
- **Not SSRF in general**: XXE is one SSRF *vector* via XML parser behavior.
- **Not client-side XML rendering** (e.g., viewing XML in a browser) unless the server parses it unsafely.

## Common variants
- External entity resolution reading local files.
- External DTD fetching over the network (SSRF).
- “Billion laughs” style entity expansion (resource exhaustion).

Additional common variants:
- **Blind/OOB XXE**: parser makes outbound requests without returning their contents.
- **Second-order XXE**: XML stored first and later parsed by a backend job.

## Review checklist
Look for:
- Parsing untrusted XML uploads or XML from remote sources
- Parsers with default settings that resolve entities / allow network access
- XML parsing in background jobs (imports, report generators)

Controls:
- Disable entity resolution and network access (`resolve_entities=False`, `no_network=True`).
- Consider hardened parsers (e.g., `defusedxml`) for untrusted XML.
- In Java/.NET, explicitly disable DTDs and external entity resolution.

## Validation notes (safe)
- Confirm whether the parser resolves entities and whether outbound network/file access is possible.

## Examples

```python
# Vulnerable
from lxml import etree

def parse_xml_upload(xml_data):
    parser = etree.XMLParser()
    return etree.fromstring(xml_data, parser)

# Controlled
def parse_xml_upload(xml_data):
    parser = etree.XMLParser(resolve_entities=False, no_network=True)
    return etree.fromstring(xml_data, parser)
```

```java
// Java hardening (illustrative)
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setXIncludeAware(false);
dbf.setExpandEntityReferences(false);
```
