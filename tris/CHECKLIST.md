# ONTrack — TRIS submission checklist

One line per requirement on the TRIS form (Technology Request Information Sheet) for this product's submission.

**Where each answer is entered.** Every requestor answer is entered on the TRIS form itself, in the section named in each heading below; row numbers are the TRIS template's. Under the TRIS Approval Process: the Requestor completes the form (step 1) and sends it to DLT-IT TRIS Request (step 2); the TRIS Administrator verifies completeness and routes it for initial approvals — IT Solution Architecture, Data Management, and Security Engineering — and then to the IT & DM&S Leadership Team; after full approval the Administrator creates the AIR entry and sends the final communication, and the Requestor submits a Procurement Engagement Request (PER).

**Status key.** **Completed** — the answer is in [WORKSHEET.md](WORKSHEET.md) or the cited evidence in this folder. **Pending** — waiting on the exact input named on the line; nothing is guessed. **IT** — a reviewer field (template rows 66–91), completed by IT; no requestor input.

**Counting note.** Several ONTrack answers are stated and final once the single build-match confirmation below lands; those lines are counted Completed and cross-refer to it.

## Before submission

- [ ] **Build-match confirmation.** Pending — input needed: confirm the submitted build is release 2.0.0 / versionCode 201 and that it matches the worksheet statements (repo LICENSE file, permission set, data flows, no AI component, no TDS-system import). Slot: [WORKSHEET.md](WORKSHEET.md), note above the product answers.

## General — TRIS form, General section

- [x] **Row 3 — Requestor.** Completed — [WORKSHEET.md](WORKSHEET.md) (shared submitter fields).
- [ ] **Row 4 — Requestor's Manager.** Pending — input needed: your manager's name. Slot: [WORKSHEET.md](WORKSHEET.md) (shared submitter fields).
- [ ] **Row 5 — PAT Manager.** Pending — input needed: PAT Manager name. Slot: [WORKSHEET.md](WORKSHEET.md) (shared submitter fields).
- [ ] **Row 6 — CoE Director.** Pending — input needed: CoE Director for the accountable Agile team (if left blank, the TRIS Administrator determines the accountable team, AM, and AD per the process document). Slot: [WORKSHEET.md](WORKSHEET.md) (shared submitter fields).
- [x] **Row 8 — Technology Name.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 9 — Technology Version.** Completed — 2.0.0 / versionCode 201, subject to the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 10 — Vendor Name.** Completed — [WORKSHEET.md](WORKSHEET.md) (shared vendor fields).
- [x] **Row 11 — Website.** Completed — [WORKSHEET.md](WORKSHEET.md) (shared vendor fields).

## Technology Details — TRIS form, Technology Details section

- [x] **Row 14 — Description.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 15 — How used at TDS.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers); business case: [BUSINESS-USE.md](BUSINESS-USE.md).
- [x] **Row 16 — Who will use it.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 17 — Technology replaced/removed.** Pending — input needed: what, if anything, is formally replaced (candidate answer: manual route planning; no named TDS system is retired in the evidence). Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 18 — Direct customer impact.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 19 — Supported internally or by vendor.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 20 — Production or test/development.** Pending — input needed: requested scope (production field use by a pilot group is the intent; confirm pilot vs. general field-services scope). Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 21 — Impact if discontinued.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 22 — Backout plan/cost.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 23 — Similar technologies at TDS.** Pending — input needed: any TDS-internal route-optimization technology already in use (none is in the package evidence). Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 24 — Alternatives considered.** Pending — input needed: alternatives considered, and why a purpose-built tool is requested. Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).

## Technical Security — TRIS form, Technical Security section

- [x] **Row 26 — AI component.** Completed — no AI component; confirmed as part of the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- **Row 27 — See AI Policy 710.** Template instruction row; answered by the row 26 answer (No — the policy does not apply).
- [x] **Row 28 — Internet access.** Completed — yes; Nominatim/OSRM geocoding and routing, ip-api.com fallback. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 29 — Hosted internal/external.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 30 — Uploads data outside the Enterprise network.** Completed — yes; stop addresses and coordinates to the services named at row 28. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 31 — Inbound access to the Enterprise network.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 32 — Data collected.** Completed — the no-TDS-system-import point is part of the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 33 — Java required.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 34 — Microsoft 365 integration.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 35 — Security risk assessment required.** Pending — input needed: your position (the app handles field-work location data, so Security Engineering may require one). Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 36 — Cardholder/banking data.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).

## Licensing — TRIS form, Licensing section

- [x] **Row 38 — How licensed.** Completed — Apache License 2.0; the repo LICENSE confirmation is part of the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 39 — License model.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 40 — License fees and quantity.** Pending — input needed: pilot headcount (fees: none). Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 41 — Support/maintenance fees.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 42 — Company's financial resources.** Pending — input needed: the vendor financial-resources statement you want on record for Qompass AI. Slot: [WORKSHEET.md](WORKSHEET.md) (shared vendor fields).
- [x] **Row 43 — How long around.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).

## Open Source — TRIS form, Open Source section

- [x] **Row 45 — Governing License.** Completed — Apache License 2.0 (see row 38 note). [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 46 — License previously reviewed by legal.** Pending — input needed: whether Apache-2.0 has previously been reviewed by TDS legal (if not, this answer triggers legal review on each form). Slot: [WORKSHEET.md](WORKSHEET.md) (shared vendor fields).
- [x] **Row 47 — Distributed / external use.** Completed — yes, publicly distributed; legal review triggered and declared. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 48 — Modified by TDS.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 49 — Directly impacts a customer product/service.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).

## Mobile — TRIS form, Mobile section

- [x] **Row 51 — Developer.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 52 — Store certification.** Pending — input needed: current Google Play / F-Droid listing status for the submitted build. Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 53 — Platforms.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 54 — TDS fee / required for a TDS service.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 55 — Confidential information.** Completed — yes; stop addresses, device location, on-device voice. The exact data-element list is part of the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [ ] **Row 56 — Third-party code.** Pending — input needed: the third-party code inventory (SBOM) for the submitted build, including confirmation of Slint's license terms for this use. Slot: [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 57 — User data collection language.** Completed — repo privacy policy and Play Data Safety transcription; coverage confirmation rides on the build-match confirmation above. [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Row 58 — Development tools/SDKs.** Completed — [WORKSHEET.md](WORKSHEET.md) (product answers).
- [x] **Rows 59–64 — Apple service rows** (in-app purchase, push notification, Game Center, iCloud, Passes, Maps). Completed — no iOS build. [WORKSHEET.md](WORKSHEET.md) (product answers).

## Reviewer fields — TRIS form rows 66–91 (IT & DM&S use only; no requestor input)

- [ ] **Rows 68–70 — Security Engineering** (resource, review comments, recommendation). IT — completed by Security Engineering during initial approvals (process step: initial approvals, typically within 5 days).
- [ ] **Rows 72–74 — Data Management** (resource, review comments, recommendation). IT — completed by Data Management during initial approvals.
- [ ] **Rows 76–78 — Solution Architecture** (resource, review comments, recommendation). IT — completed by IT Solution Architecture during initial approvals.
- [ ] **Rows 81–89 — Leadership approvers.** IT — completed when the TRIS Administrator routes the request to the IT & DM&S Leadership Team (approval email carries Approve/Reject voting buttons, a link to the TRIS, and a 48-hour turnaround date).
- [ ] **Row 90 — Leadership review comments.** IT.
- [ ] **Row 91 — Leadership Team recommendation.** IT — on full approval the tracking entry moves to Completed, the Administrator creates the AIR entry and sends the final communication; the Requestor then submits the PER.

---
*Checklist prepared 2026-11-11 from the TRIS template and process documents and the submission package evidence. DRAFT — not submitted.*
