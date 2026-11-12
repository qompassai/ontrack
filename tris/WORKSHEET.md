# ONTrack (package `ai.qompass.ontrack`, repo `qompassai/ontrack`) — TRIS form-input worksheet

The requestor's working worksheet for this product's TRIS form (Technology Request Information Sheet): every requestor-facing field, pre-filled from the submission evidence wherever the evidence supports a value. Anything only the requestor can supply is marked **[INPUT NEEDED: …]** — nothing here is invented. Numbers in parentheses are the TRIS template's row numbers, so each line can be checked against the form and against [CHECKLIST.md](CHECKLIST.md).

This is one product's slice of the combined six-product submission worksheet prepared 2026-11-11 (ONTrack, LightShow, Fathom, Versemend, the Salesforce MCP integration, and Niflheim were submitted together in one email). IT reviewer fields (template rows 66–91) need no requestor input and are not listed here.

## Shared submitter fields (rows 3–6, repeated on all six forms)

- Requestor (3): Matt A. Porter — Field Service Technician (FST), matthew.porter@tdstelecom.com
- Requestor's Manager (4): Josh Barter
- PAT Manager (5): [INPUT NEEDED: PAT Manager name — note: the process document names an Internal Employee Tools PAT contact as the AIR-access contact; that is not evidence he is the PAT Manager for this request]
- CoE Director (6): [INPUT NEEDED: CoE Director for the accountable Agile team — if left blank, the TRIS Administrator determines the accountable team, AM, and AD per the process document]

## Shared vendor fields (rows 10, 11, 42, plus the shared open-source fact at row 46)

Applies to the five Qompass AI products. The Salesforce integration's vendor is Salesforce; its vendor fields are in its own block below.

- Vendor Name (10): Qompass AI (the requestor's company; he is the developer/vendor)
- Website (11): qompass.ai
- What are the company's financial resources? (42): [INPUT NEEDED: the vendor financial-resources statement you want on record for Qompass AI — no figures exist in the package evidence]
- Has the governing Open Source license previously been reviewed by legal? (46, asked on every form): [INPUT NEEDED: whether Apache-2.0 has previously been reviewed by TDS legal — if not, this answer triggers legal review on each form]

## Product answers

[INPUT NEEDED: build-match confirmation — confirm the submitted build is release 2.0.0 / versionCode 201 and that it matches the checklist statements (repo LICENSE file, permission set, data flows below, no AI component, no TDS-system import)]

- Technology Name (8): ONTrack
- Technology Version (9): 2.0.0 / versionCode 201 (tag `v2.0.0`)
- Website (11): qompass.ai (no product-specific page in evidence)
- Description (14): A route optimizer for field service work: a technician enters the day's stops and the app sequences them into an efficient route. Rust application with an egui desktop UI and a Slint mobile UI.
- How used at TDS (15): Field service technicians plan daily stop sequences before and during a shift, reducing windshield time between jobs.
- Who will use it (16): Field services — TDS field service technicians. Pilot scope first; wider use only if the pilot earns it.
- Technology replaced/removed (17): [INPUT NEEDED: what, if anything, is formally replaced — candidate answer: manual route planning (maps checked stop by stop); no named TDS system is retired in the evidence]
- Direct customer impact (18): No — internal planning tool; used about customer visits, not by customers; no customer website or service is changed.
- Supported internally or by vendor (19): Internally — by the developer (the requestor / Qompass AI). No external support contract.
- Production or test/development (20): [INPUT NEEDED: requested scope — production field use by a pilot group is the intent; confirm pilot vs. general field-services scope]
- Impact if discontinued (21): Low — technicians return to manual route planning; no TDS system depends on ONTrack.
- Backout plan/cost (22): Uninstall the app from the device(s); cost is the removal time. (Whether locally stored routes/stops need export or deletion on backout is covered by the build-match confirmation above.)
- Similar technologies at TDS (23): [INPUT NEEDED: any TDS-internal route-optimization technology already in use — none is in the package evidence]
- Alternatives considered (24): [INPUT NEEDED: alternatives considered — e.g., ad-hoc consumer maps apps, or a commercial route-optimization product, and why a purpose-built tool is requested]
- AI component (26): No AI component in the evidence — deterministic route optimizer (confirmed via the build-match confirmation above; if No, AI Policy 710 does not apply).
- Internet access (28): Yes — online geocoding/routing by default: stop addresses and coordinates go to Nominatim and OSRM, with an ip-api.com fallback and an optional user-supplied Google Maps key. An offline haversine mode exists but is not the default (the F-Droid recipe declares the NonFreeNet anti-feature for this reason).
- Hosted internal/external (29): On the user's device (desktop/mobile application); no vendor-site hosting and no server component.
- Uploads data outside the Enterprise network (30): Yes — stop addresses and coordinates are sent to the services named at row 28. The repo's Data Safety transcription lists the data types actually collected: addresses, location, and on-device voice.
- Inbound access to the Enterprise network (31): No — client application; no inbound access.
- Data collected (32): Stop addresses; device location (ACCESS_COARSE_LOCATION / ACCESS_FINE_LOCATION); on-device voice input (RECORD_AUDIO; voice stays on device per the Data Safety record); reads device storage (READ_EXTERNAL_STORAGE, maxSdk 32). No integration with TDS systems.
- Java required (33): No.
- Microsoft 365 integration (34): No.
- Security risk assessment required (35): [INPUT NEEDED: your position — the app handles field-work location data, so Security Engineering may require one; the checklist flags it for their determination]
- Cardholder/banking data (36): No.
- How licensed (38): Open Source — Apache License 2.0 (repo LICENSE, confirmed via the build-match confirmation above).
- License model (39): No per-user/concurrent/server control; no license-control software.
- License fees and quantity (40): No license fees. Quantity: [INPUT NEEDED: pilot headcount]
- Support/maintenance fees (41): None — support is internal (row 19).
- How long around (43): Publication work completed by 2026-09-30; in active development through 2026.
- Governing License (45): Apache License 2.0.
- License previously reviewed by legal (46): See the shared vendor block.
- Distributed / external use (47): Yes — publicly distributed (Google Play and F-Droid publication work complete); per the template this triggers legal review, declared openly.
- Modified by TDS (48): No modification by TDS planned.
- Directly impacts a customer product/service (49): No — an internal tool used by technicians serving customers; not itself a product or service provided to customers.
- Mobile — developer (51): Third party — the requestor (Matt A. Porter) as a Qompass AI product.
- Mobile — store certification (52): [INPUT NEEDED: current Google Play / F-Droid listing status for the submitted build — publication work was completed 2026-09-30, but current listing status is not in the evidence]
- Mobile — platforms (53): Google Android (Slint mobile); desktop (egui — MS Windows and Linux). No iOS build.
- Mobile — TDS fee / required for a TDS service (54): No fee; not required to use any TDS service.
- Mobile — confidential information (55): Yes — stop addresses are customer-premises addresses; plus device location and on-device voice input. The repo carries a privacy policy (`docs/PRIVACY_POLICY.md`).
- Mobile — third-party code (56): [INPUT NEEDED: generate/attach the third-party code inventory (SBOM) for the submitted build — the app is built on open-source Rust stacks (egui desktop, Slint mobile) and other crates; Slint's license terms for this use must be confirmed as part of this answer]
- Mobile — user data collection language (57): Yes — `docs/PRIVACY_POLICY.md` and the Play Data Safety transcription (`playstore/google-play.json`, rewritten to list every data type actually collected) state what is collected and how it is used.
- Mobile — development tools/SDKs (58): Android SDK/toolchain for the mobile build; Rust toolchain for desktop.
- Mobile — in-app purchase (59) / Apple push (60) / Game Center (61) / iCloud (62) / Passes (63) / Apple Maps (64): No — no iOS build.

---
*Worksheet slice prepared 2026-11-11 from the TRIS template and process documents and the submission package evidence. DRAFT — not yet submitted. See [README.md](README.md) for the status summary and the public-copy notes.*
