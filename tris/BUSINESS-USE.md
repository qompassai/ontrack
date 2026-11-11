# ONTrack — business use at TDS

**What it is.** A route optimizer for field service work, built by the requestor (a TDS field service technician) as a Qompass AI product. Rust, with an egui desktop UI and a Slint mobile UI. A technician enters the day's stops; the app sequences them into an efficient route.

**Who at TDS uses it.** Field service technicians — the people whose workday is a list of addresses and a windshield. The requestor is the pilot user. Any wider use should be a decision made after a pilot, not a premise of this request.

**What work it changes.** Route planning today is manual: a technician reads the day's jobs and orders them from experience, checking a maps app stop by stop. That works, and it costs time twice — once planning, and again in backtracking when the manual order is wrong. ONTrack moves the sequencing into a tool built for exactly that shape of day: many stops, one vehicle, fixed appointment windows where they exist. The saving is drive time and planning time. It is not estimated here in dollars or minutes, because no measured pilot data exists yet; producing that measurement is what a pilot is for, and this document does not invent one.

**What it replaces.** Formally, nothing — no TDS system is retired by this request (see CHECKLIST row 17, which the Owner must confirm). Practically, it replaces ad-hoc personal tooling and manual sequencing, which are currently ungoverned: technicians already use consumer maps on their own initiative. A purpose-built, reviewed tool is a governance improvement over that status quo, not just a convenience.

**Risk posture.**
- *Data touched, and network behavior.* ONTrack is **networked by default** (estate publish skill, fixed facts): it declares INTERNET, ACCESS_NETWORK_STATE, ACCESS_COARSE/FINE_LOCATION, RECORD_AUDIO, and READ_EXTERNAL_STORAGE (maxSdk 32), and in its default mode it sends stop addresses and coordinates to **Nominatim** and **OSRM** for geocoding/routing, with an **ip-api.com** fallback and an optional user-supplied Google Maps key. An offline haversine mode exists but is not the default — the F-Droid recipe declares the `NonFreeNet` anti-feature for exactly this reason. So the sensitive fact is concrete, not hypothetical: in default mode, customer-premises addresses leave the device (and the Enterprise network). The checklist (rows 28, 30, 32, 55, 57) states this in full, and the repo's Data Safety transcription (`playstore/google-play.json`) lists the data types actually collected: addresses, location, and on-device voice. Any TDS approval should therefore name the permitted configuration — e.g., approved services only, or the offline mode required — and data-minimization (no customer names attached to stops) belongs in the use conditions.
- *Blast radius.* Small by construction: an on-device planning tool with no TDS-system integration in evidence. If it is discontinued, technicians return to manual planning the same day (checklist rows 21–22).
- *Identity housekeeping.* CONFIRMED by the Owner 2026-11-11 (D-1277): this submission is ONTrack, package `ai.qompass.ontrack`. The FieldSnek rename on record (October 2026, package `com.qompassai.fieldsnek`) is a separate product line, not this submission.

**The honest limit.** ONTrack's value is real but narrow: one technician's day, made shorter. It does not integrate with TDS scheduling or work-order systems in any evidence available to this package, and this document does not claim dispatch, fleet, or customer-experience benefits beyond the technician using it.

*Draft, 2026-11-10. Not submitted.*
